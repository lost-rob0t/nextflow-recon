/*
 * Upload workflow for BBRF integration
 */

include { BBRF_UPLOAD_DOMAINS; BBRF_UPLOAD_URLS } from '../modules/bbrf'

workflow UPLOAD {
    take:
    domains_ch
    urls_ch
    program
    
    main:
    domain_logs = Channel.empty()
    url_logs = Channel.empty()
    
    domains_ch
        .filter { it != null }
        .ifEmpty { Channel.fromPath("/dev/null") }
        .collectFile(name: "domains_for_upload.txt", newLine: true)
        .filter { file(it).exists() && file(it).size() > 0 }
        .set { filtered_domains }
    
    if (params.upload_to_bbrf) {
        domain_upload_results = BBRF_UPLOAD_DOMAINS(
            filtered_domains,
            program
        )
        domain_logs = domain_upload_results.upload_log
    }
    
    urls_ch
        .filter { it != null }
        .ifEmpty { Channel.fromPath("/dev/null") }
        .collectFile(name: "urls_for_upload.txt", newLine: true)
        .filter { file(it).exists() && file(it).size() > 0 }
        .set { filtered_urls }
    
    if (params.upload_to_bbrf) {
        url_upload_results = BBRF_UPLOAD_URLS(
            filtered_urls,
            program
        )
        url_logs = url_upload_results.upload_log
    }
    
    all_upload_results = domain_logs
        .mix(url_logs)
        .collectFile(name: "upload_summary.log", newLine: true)
    
    emit:
    upload_summary = all_upload_results
    domain_logs = domain_logs
    url_logs = url_logs
}
