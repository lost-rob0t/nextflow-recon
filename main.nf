#!/usr/bin/env nextflow

/*
 * Hackmode Security Reconnaissance Framework
 * Main workflow entry point
 */

nextflow.enable.dsl = 2

// Include modules and subworkflows
include { BBRF_GET_DOMAINS; BBRF_GET_INSCOPE_DOMAINS; BBRF_GET_URLS; BBRF_GET_URLS_FULL; BBRF_GET_IPS } from './modules/bbrf'
include { SUBFINDER } from './modules/subfinder'
include { ASSETFINDER } from './modules/assetfinder'
include { KATANA; KATANA_PARSE_JSON } from './modules/katana'
include { PASSIVE_RECON } from './subworkflows/passive_recon'
include { ACTIVE_RECON } from './subworkflows/active_recon'
include { WEB_CRAWL; WEB_CRAWL_FROM_DOMAINS } from './subworkflows/web_crawl'
include { UPLOAD } from './subworkflows/upload'

// Help message
def help_message() {
    log.info"""
    Hackmode Security Reconnaissance Framework
    
    Usage:
        nextflow run main.nf [options]
    
    Options:
        --input <file>              Input file with targets
        --outdir <directory>        Output directory (default: ./results)
        --bbrf_program <name>       BBRF program name
        --use_bbrf_targets          Use targets from BBRF database
        --passive_recon             Enable passive reconnaissance
        --active_recon              Enable active reconnaissance
        --web_crawl                 Enable web crawling with Katana
        --help                      Show this help message
    
    Examples:
        nextflow run main.nf --passive_recon
        nextflow run main.nf --bbrf_program my-program --use_bbrf_targets
        nextflow run main.nf --active_recon --web_crawl --bbrf_program my-program
    """.stripIndent()
}

// Parameter validation
def validate_parameters() {
    if (params.help) {
        help_message()
        exit 0
    }
    
    if (!params.use_bbrf_targets && !params.input) {
        error("Error: Either --input or --use_bbrf_targets must be specified")
    }
    
    if (params.bbrf_program == null || params.bbrf_program == '') {
        error("Error: --bbrf_program must be specified")
    }
}

// Main workflow
workflow {
    // Validate parameters
    validate_parameters()
    
    // Initialize channels
    targets_ch = Channel.empty()
    existing_domains_ch = Channel.empty()
    existing_urls_ch = Channel.empty()

    // Load targets
    if (params.use_bbrf_targets) {
        // Load from BBRF database
        bbrf_domains = BBRF_GET_DOMAINS(params.bbrf_program)
        bbrf_inscope = BBRF_GET_INSCOPE_DOMAINS(params.bbrf_program)
        bbrf_urls = BBRF_GET_URLS(params.bbrf_program)
        bbrf_urls_full = BBRF_GET_URLS_FULL(params.bbrf_program)
        bbrf_ips = BBRF_GET_IPS(params.bbrf_program)
        
        // Use in-scope domains as targets
        targets_ch = bbrf_inscope.domains
            .splitText()
            .map { it.trim() }
            .filter { it && !it.startsWith('#') }
        
        existing_domains_ch = bbrf_domains.domains
        existing_urls_ch = bbrf_urls.urls
        
        // Display URLs with status codes for reference
        bbrf_urls_full.urls_full.view { "BBRF URLs with status codes: ${it}" }
        bbrf_urls_full.urls_parsed.view { "BBRF URLs parsed JSON: ${it}" }

    } else {
        // Load from input file
        targets_ch = Channel.fromPath(params.input)
            .splitText()
            .map { it.trim() }
            .filter { it && !it.startsWith('#') }
    }
    
    // Initialize result channels
    all_domains = Channel.empty()
    all_urls = Channel.empty()
    all_crawled_urls = Channel.empty()
    
    // Execute workflows based on configuration
    if (params.passive_recon) {
        passive_results = PASSIVE_RECON(targets_ch, existing_domains_ch)
        all_domains = all_domains.mix(passive_results.new_subdomains)
        
        // Display passive results
        passive_results.subdomains.view { "Passive recon found subdomains: ${it}" }
        
        // If active recon is also enabled, use passive results as input
        if (params.active_recon) {
            active_results = ACTIVE_RECON(passive_results.subdomains)
            all_urls = all_urls.mix(active_results.live_hosts)
            
            // Display active results
            active_results.live_hosts.view { "Active recon found live hosts: ${it}" }
            
            // If web crawling is enabled, crawl the discovered URLs
            if (params.web_crawl) {

                crawl_results = WEB_CRAWL(active_results.live_hosts)
                all_crawled_urls = all_crawled_urls.mix(crawl_results.crawled_urls)
                
                // Display crawling results
                crawl_results.crawled_urls.view { "Web crawl found URLs: ${it}" }
                if (params.katana_json_output) {
                    crawl_results.summary.view { "Crawl summary: ${it}" }
                }
            }
        } else if (params.web_crawl) {
            // Run web crawling directly on passive recon results
            crawl_results = WEB_CRAWL_FROM_DOMAINS(passive_results.subdomains)
            all_crawled_urls = all_crawled_urls.mix(crawl_results.crawled_urls)
            
            
            // Display crawling results
            crawl_results.crawled_urls.view { "Web crawl found URLs: ${it}" }
            if (params.katana_json_output) {
                crawl_results.summary.view { "Crawl summary: ${it}" }
            }
        }
    } else if (params.active_recon) {
        // Run active recon directly on targets if no passive recon
        active_input = targets_ch.collectFile(name: "targets.txt", newLine: true)
        active_results = ACTIVE_RECON(active_input)
        all_urls = all_urls.mix(active_results.live_hosts)
        
        // Display active results
        active_results.live_hosts.view { "Active recon found live hosts: ${it}" }
        
        // If web crawling is enabled, crawl the discovered URLs
        if (params.web_crawl) {
            crawl_results = WEB_CRAWL(active_results.live_hosts)
            all_crawled_urls = all_crawled_urls.mix(crawl_results.crawled_urls)
            
            // Display crawling results
            crawl_results.crawled_urls.view { "Web crawl found URLs: ${it}" }
            if (params.katana_json_output) {
                crawl_results.summary.view { "Crawl summary: ${it}" }
            }
        }
    } else if (params.web_crawl) {
        // Run web crawling directly on targets
        if (params.use_bbrf_targets) {
            // Use existing URLs from BBRF
            crawl_results = WEB_CRAWL(existing_urls_ch)
        } else {
            // Convert targets to URLs and crawl
            crawl_input = targets_ch.collectFile(name: "targets.txt", newLine: true)
            crawl_results = WEB_CRAWL_FROM_DOMAINS(crawl_input)
        }
        all_crawled_urls = all_crawled_urls.mix(crawl_results.crawled_urls)
        
        // Display crawling results
        crawl_results.crawled_urls.view { "Web crawl found URLs: ${it}" }
        if (params.katana_json_output) {
            crawl_results.summary.view { "Crawl summary: ${it}" }
        }
    }
    
}

// Named workflows for specific use cases
workflow LOAD_TARGETS {
    main:
    if (params.use_bbrf_targets) {
        BBRF_GET_DOMAINS(params.bbrf_program)
        BBRF_GET_INSCOPE_DOMAINS(params.bbrf_program)
        BBRF_GET_URLS(params.bbrf_program)
        BBRF_GET_IPS(params.bbrf_program)
        
        targets = BBRF_GET_INSCOPE_DOMAINS.out.domains
            .splitText()
            .map { it.trim() }
            .filter { it && !it.startsWith('#') }
    } else {
        targets = Channel.fromPath(params.input)
            .splitText()
            .map { it.trim() }
            .filter { it && !it.startsWith('#') }
    }
    
    emit:
    targets = targets
    domains = params.use_bbrf_targets ? BBRF_GET_DOMAINS.out.domains : Channel.empty()
    urls = params.use_bbrf_targets ? BBRF_GET_URLS.out.urls : Channel.empty()
    ips = params.use_bbrf_targets ? BBRF_GET_IPS.out.ips : Channel.empty()
}

workflow SUBDOMAIN_ENUMERATION {
    take:
    targets
    
    main:
    subfinder_results = SUBFINDER(targets)
    assetfinder_results = ASSETFINDER(targets)
    
    // Combine results
    all_subdomains = subfinder_results.domains
        .mix(assetfinder_results.domains)
        .collectFile(name: "all_subdomains.txt", newLine: true)
    
    emit:
    domains = all_subdomains
}
