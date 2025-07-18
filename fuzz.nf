#!/usr/bin/env nextflow

/*
 * Hackmode Fuzzing and Directory Busting Workflow
 * Specialized workflow for content discovery and fuzzing
 */

nextflow.enable.dsl = 2

// Include modules and subworkflows
include { GOBUSTER; GOBUSTER_BATCH } from './modules/gobuster'
include { FFUF; FFUF_BATCH } from './modules/ffuf'
include { DIRBUSTER } from './modules/dirbuster'
include { DIRBUSTING } from './subworkflows/dirbusting'
include { BBRF_GET_URLS; BBRF_GET_URLS_FULL; BBRF_UPLOAD_URLS } from './modules/bbrf'

// Help message
def help_message() {
    log.info"""
    Hackmode Fuzzing and Directory Busting Workflow
    
    Usage:
        nextflow run fuzz.nf [options]
    
    Options:
        --input <file>              Input file with URLs/domains
        --outdir <directory>        Output directory (default: ./fuzz_results)
        --bbrf_program <name>       BBRF program name
        --use_bbrf_urls             Use URLs from BBRF database
        --wordlist <file>           Wordlist for directory busting
        --threads <number>          Number of threads (default: 50)
        --extensions <string>       File extensions to fuzz (default: php,html,txt,js)
        --timeout <string>          Request timeout (default: 10s)
        --help                      Show this help message
    
    Tools:
        --use_gobuster             Enable gobuster (default: true)
        --use_ffuf                 Enable ffuf (default: true)
        --use_dirbuster            Enable dirbuster (default: false)
    
    Examples:
        nextflow run fuzz.nf --input urls.txt --wordlist /path/to/wordlist.txt
        nextflow run fuzz.nf --bbrf_program my-program --use_bbrf_urls
        nextflow run fuzz.nf --input urls.txt --threads 100 --extensions php,html,js
    """.stripIndent()
}

// Parameter validation
def validate_parameters() {
    if (params.help) {
        help_message()
        exit 0
    }
    
    if (!params.use_bbrf_urls && !params.input) {
        error("Error: Either --input or --use_bbrf_urls must be specified")
    }
    
    if (!params.wordlist) {
        error("Error: --wordlist must be specified")
    }
    
    if (!file(params.wordlist).exists()) {
        error("Error: Wordlist file '${params.wordlist}' not found")
    }
}

// Main workflow
workflow {
    // Validate parameters
    validate_parameters()
    
    // Initialize channels
    urls_ch = Channel.empty()
    
    // Load URLs
    if (params.use_bbrf_urls) {
        // Load from BBRF database
        bbrf_urls = BBRF_GET_URLS(params.bbrf_program)
        bbrf_urls_full = BBRF_GET_URLS_FULL(params.bbrf_program)
        
        // Use clean URLs for fuzzing
        urls_ch = bbrf_urls.urls
            .splitText()
            .map { it.trim() }
            .filter { it && !it.startsWith('#') && it.startsWith('http') }
        
        // Display full URLs with status codes for reference
        bbrf_urls_full.urls_full.view { "BBRF URLs with status codes: ${it}" }
        bbrf_urls_full.urls_parsed.view { "BBRF URLs parsed JSON: ${it}" }
    } else {
        // Load from input file
        urls_ch = Channel.fromPath(params.input)
            .splitText()
            .map { it.trim() }
            .filter { it && !it.startsWith('#') && it.startsWith('http') }
    }
    
    // Run directory busting workflow
    dirbusting_results = DIRBUSTING(urls_ch, params.wordlist)
    
    // Display results
    dirbusting_results.found_paths.view { "Found paths: ${it}" }
    dirbusting_results.stats.view { "Directory busting stats: ${it}" }
    
    // Upload results to BBRF if configured
    if (params.upload_to_bbrf) {
        upload_results = BBRF_UPLOAD_URLS(
            dirbusting_results.found_paths,
            params.bbrf_program
        )
        
        upload_results.upload_log.view { "Upload log: ${it}" }
    }
}

// Workflow for batch processing
workflow FUZZ_BATCH {
    take:
    urls_file
    wordlist
    
    main:
    // Split URLs into batches for parallel processing
    url_batches = Channel.fromPath(urls_file)
        .splitText(by: params.batch_size ?: 100, file: true)
        .map { chunk -> [UUID.randomUUID().toString()[0..7], chunk] }
    
    // Run directory busting on batches
    batch_results = DIRBUSTING_BATCH(url_batches, wordlist)
    
    // Combine results
    combined_results = batch_results.found_paths
        .collectFile(name: 'combined_fuzz_results.txt', storeDir: "${params.outdir}")
    
    emit:
    results = combined_results
}

// Workflow for single URL fuzzing
workflow FUZZ_SINGLE {
    take:
    url
    wordlist
    
    main:
    // Create single URL channel
    single_url_ch = Channel.of(url)
        .collectFile(name: "${url.replaceAll('[^a-zA-Z0-9]', '_')}.txt", newLine: true)
    
    // Run directory busting
    single_results = DIRBUSTING(single_url_ch, wordlist)
    
    emit:
    results = single_results.found_paths
}
