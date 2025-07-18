/*
 * Active reconnaissance subworkflow
 */

include { HTTPX } from '../modules/httpx'



workflow ACTIVE_RECON {
    take:
    domains_ch
    
    main:
    split_domains = domains_ch
        .splitText()
        .map { it.trim() }
        .filter { it && !it.startsWith('#') }
        .map { domain -> 
            // Create individual file for each domain
            def domain_file = file("${domain.replaceAll('[^a-zA-Z0-9]', '_')}.txt")
            domain_file.text = domain
            domain_file
        }
    
    httpx_results = HTTPX(split_domains)
    
    // Collect all results
    all_live_hosts = httpx_results.live_hosts.collectFile(name: "httpx_all_live.txt", newLine: true)
    all_json_outputs = httpx_results.json_output.collectFile(name: "httpx_all_results.json", newLine: true)

    emit:
    live_hosts = all_live_hosts
    json_output = all_json_outputs
    individual_live_hosts = httpx_results.live_hosts
    individual_json_outputs = httpx_results.json_output
}
