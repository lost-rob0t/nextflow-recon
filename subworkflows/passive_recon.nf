/*
 * Passive reconnaissance subworkflow
 */

include { SUBFINDER; SUBFINDER_BATCH } from '../modules/subfinder'
include { ASSETFINDER } from '../modules/assetfinder'

workflow PASSIVE_RECON {
    take:
    targets_ch
    existing_domains_ch

    main:
    // Run subdomain enumeration tools in parallel
    subfinder_results = SUBFINDER(targets_ch)
    assetfinder_results = ASSETFINDER(targets_ch)
    
    // Combine subdomain results
    all_subdomains = subfinder_results.domains
        .mix(assetfinder_results.domains)
        .collectFile(name: "all_subdomains.txt", newLine: true)
    
    // Filter new subdomains if we have existing ones
    if (existing_domains_ch.isEmpty()) {
        unique_subdomains = all_subdomains
        new_subdomains = all_subdomains
    } else {
        // For now, treat all as unique and new
        unique_subdomains = all_subdomains
        new_subdomains = all_subdomains
    }
    
    emit:
    subdomains = unique_subdomains
    new_subdomains = new_subdomains
}
