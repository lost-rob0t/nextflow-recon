/*
 * Directory busting subworkflow
 */

include { GOBUSTER; GOBUSTER_BATCH; GOBUSTER_VHOST } from '../modules/gobuster'
include { FFUF; FFUF_BATCH; FFUF_PARAMETERS; FFUF_VHOST } from '../modules/ffuf'
include { DIRBUSTER; DIRBUSTER_RECURSIVE; DIRBUSTER_CUSTOM } from '../modules/dirbuster'

workflow DIRBUSTING {
    take:
    urls_ch
    wordlist
    
    main:
    all_found_paths = Channel.empty()
    all_stats = Channel.empty()
    
    if (params.use_gobuster != false) {
        gobuster_results = GOBUSTER(urls_ch, wordlist)
        all_found_paths = all_found_paths.mix(gobuster_results.found_paths)
        
        gobuster_results.found_paths.view { "Gobuster found: ${it}" }
    }
    
    if (params.use_ffuf != false) {
        ffuf_results = FFUF(urls_ch, wordlist)
        all_found_paths = all_found_paths.mix(ffuf_results.found_paths)
        
        ffuf_results.found_paths.view { "FFUF found: ${it}" }
    }
    
    if (params.use_dirbuster == true) {
        dirbuster_results = DIRBUSTER(urls_ch, wordlist)
        all_found_paths = all_found_paths.mix(dirbuster_results.found_paths)
        
        dirbuster_results.found_paths.view { "DirBuster found: ${it}" }
    }
    
    combined_paths = all_found_paths
        .collectFile(name: "combined_dirbusting_results.txt", newLine: true)
        .map { file ->
            def lines = file.readLines().unique().sort()
            def output = file.parent.resolve("deduplicated_dirbusting_results.txt")
            output.text = lines.join('\n')
            return output
        }
    
    stats = combined_paths.map { file ->
        def lines = file.readLines()
        def total_paths = lines.size()
        def unique_domains = lines.collect { it.split('/')[0..2].join('/') }.unique().size()
        
        return [
            total_paths: total_paths,
            unique_domains: unique_domains,
            tools_used: [
                gobuster: (params.use_gobuster != false),
                ffuf: (params.use_ffuf != false),
                dirbuster: (params.use_dirbuster == true)
            ],
            timestamp: new Date().format('yyyy-MM-dd HH:mm:ss')
        ]
    }
    
    emit:
    found_paths = combined_paths
    stats = stats
}

workflow DIRBUSTING_BATCH {
    take:
    url_batches
    wordlist
    
    main:
    all_found_paths = Channel.empty()
    
    if (params.use_gobuster != false) {
        gobuster_batch_results = GOBUSTER_BATCH(url_batches, wordlist)
        all_found_paths = all_found_paths.mix(gobuster_batch_results.found_paths)
    }
    
    if (params.use_ffuf != false) {
        ffuf_batch_results = FFUF_BATCH(url_batches, wordlist)
        all_found_paths = all_found_paths.mix(ffuf_batch_results.found_paths)
    }
    
    combined_batch_paths = all_found_paths
        .collectFile(name: "combined_batch_dirbusting_results.txt", newLine: true)
        .map { file ->
            def lines = file.readLines().unique().sort()
            def output = file.parent.resolve("deduplicated_batch_dirbusting_results.txt")
            output.text = lines.join('\n')
            return output
        }
    
    emit:
    found_paths = combined_batch_paths
}

workflow VHOST_ENUMERATION {
    take:
    domains_ch
    wordlist
    
    main:
    all_found_vhosts = Channel.empty()
    
    if (params.use_gobuster_vhost == true) {
        gobuster_vhost_results = GOBUSTER_VHOST(domains_ch, wordlist)
        all_found_vhosts = all_found_vhosts.mix(gobuster_vhost_results.found_vhosts)
    }
    
    if (params.use_ffuf_vhost == true) {
        ffuf_vhost_results = FFUF_VHOST(domains_ch, wordlist)
        all_found_vhosts = all_found_vhosts.mix(ffuf_vhost_results.found_vhosts)
    }
    
    combined_vhosts = all_found_vhosts
        .collectFile(name: "combined_vhost_results.txt", newLine: true)
        .map { file ->
            def lines = file.readLines().unique().sort()
            def output = file.parent.resolve("deduplicated_vhost_results.txt")
            output.text = lines.join('\n')
            return output
        }
    
    emit:
    found_vhosts = combined_vhosts
}

workflow PARAMETER_FUZZING {
    take:
    urls_ch
    wordlist
    
    main:
    if (params.use_ffuf_params == true) {
        ffuf_params_results = FFUF_PARAMETERS(urls_ch, wordlist)
        
        combined_params = ffuf_params_results.found_params
            .collectFile(name: "combined_parameter_results.txt", newLine: true)
            .map { file ->
                def lines = file.readLines().unique().sort()
                def output = file.parent.resolve("deduplicated_parameter_results.txt")
                output.text = lines.join('\n')
                return output
            }
        
        emit:
        found_params = combined_params
    } else {
        emit:
        found_params = Channel.empty()
    }
}
