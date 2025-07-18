/*
 * Web crawling subworkflow using Katana
 */

include { KATANA; KATANA_BATCH; KATANA_PARSE_JSON } from '../modules/katana'

workflow WEB_CRAWL {
    take:
    urls_ch
    
    main:
    split_urls = urls_ch
        .splitText()
        .map { it.trim() }
        .filter { it && !it.startsWith('#') }
        .map { url -> 
            def safe_name = url.replaceAll('[^a-zA-Z0-9]', '_').take(50)
            def url_file = file("${safe_name}.txt")
            url_file.text = url
            url_file
        }
    
    katana_results = KATANA(split_urls)
    
    all_crawled_urls = katana_results.crawled_urls.collectFile(name: "katana_all_crawled.txt", newLine: true)
    all_json_outputs = katana_results.json_output.collectFile(name: "katana_all_results.json", newLine: true)
    all_forms = katana_results.forms_output.collectFile(name: "katana_all_forms.json", newLine: true)
    
    parsed_results = Channel.empty()
    if (params.katana_json_output) {
        parsed_results = KATANA_PARSE_JSON(all_json_outputs)
    }
    
    emit:
    crawled_urls = all_crawled_urls
    json_output = all_json_outputs
    forms = all_forms
    individual_crawled_urls = katana_results.crawled_urls
    individual_json_outputs = katana_results.json_output
    individual_forms = katana_results.forms_output
    parsed_urls = parsed_results.urls ?: Channel.empty()
    parsed_endpoints = parsed_results.endpoints ?: Channel.empty()
    parsed_forms = parsed_results.forms ?: Channel.empty()
    parsed_xhr = parsed_results.xhr ?: Channel.empty()
    parsed_js_files = parsed_results.js_files ?: Channel.empty()
    parsed_technologies = parsed_results.technologies ?: Channel.empty()
    summary = parsed_results.summary ?: Channel.empty()
}

workflow WEB_CRAWL_FROM_DOMAINS {
    take:
    domains_ch
    
    main:
    split_domains = domains_ch
        .splitText()
        .map { it.trim() }
        .filter { it && !it.startsWith('#') }
        .map { domain ->
            ["http://${domain}", "https://${domain}"]
        }
        .flatten()
        .map { url -> 
            def safe_name = url.replaceAll('[^a-zA-Z0-9]', '_').take(50)
            def url_file = file("${safe_name}.txt")
            url_file.text = url
            url_file
        }
    
    katana_results = KATANA(split_domains)
    all_crawled_urls = katana_results.crawled_urls.collectFile(name: "katana_domain_crawled.txt", newLine: true)
    all_json_outputs = katana_results.json_output.collectFile(name: "katana_domain_results.json", newLine: true)
    all_forms = katana_results.forms_output.collectFile(name: "katana_domain_forms.json", newLine: true)
    parsed_results = Channel.empty()
    if (params.katana_json_output) {
        parsed_results = KATANA_PARSE_JSON(all_json_outputs)
    }
    
    emit:
    crawled_urls = all_crawled_urls
    json_output = all_json_outputs
    forms = all_forms
    individual_crawled_urls = katana_results.crawled_urls
    individual_json_outputs = katana_results.json_output
    individual_forms = katana_results.forms_output
    parsed_urls = parsed_results.urls ?: Channel.empty()
    parsed_endpoints = parsed_results.endpoints ?: Channel.empty()
    parsed_forms = parsed_results.forms ?: Channel.empty()
    parsed_xhr = parsed_results.xhr ?: Channel.empty()
    parsed_js_files = parsed_results.js_files ?: Channel.empty()
    parsed_technologies = parsed_results.technologies ?: Channel.empty()
    summary = parsed_results.summary ?: Channel.empty()
}
