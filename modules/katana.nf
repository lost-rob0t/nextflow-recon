/*
 * Katana module for web crawling
 */

process KATANA {
    tag "${urls_file.baseName}"
    publishDir "${params.outdir}/katana", mode: 'copy', enabled: params.publish_intermediates
    maxRetries 3
    
    input:
    path urls_file
    
    output:
    path "katana_results.txt", emit: crawled_urls
    path "katana_results.json", emit: json_output, optional: true
    path "katana_forms.json", emit: forms_output, optional: true

    script:
    def json_params = params.katana_json_output ? "-jsonl" : ""
    def depth_params = "-depth ${params.katana_depth}"
    def threads_params = "-c ${params.katana_concurrency}"
    def js_crawl_params = params.katana_js_crawl ? "-jc" : ""
    def tech_detect_params = params.katana_tech_detect ? "-td" : ""
    def form_extract_params = params.katana_form_extraction ? "-fx" : ""
    def xhr_params = params.katana_xhr_extraction ? "-xhr" : ""
    def delay_params = params.katana_delay > 0 ? "-rd ${params.katana_delay}" : ""
    def rate_limit_params = params.katana_rate_limit > 0 ? "-rl ${params.katana_rate_limit}" : ""
    def timeout_params = "-timeout ${params.katana_timeout}"
    def known_files_params = params.katana_known_files ? "-kf ${params.katana_known_files}" : ""
    def user_agent_params = params.katana_user_agent ? "-H 'User-Agent: ${params.katana_user_agent}'" : ""
    def proxy_params = params.katana_proxy ? "-proxy ${params.katana_proxy}" : ""
    def filter_params = params.katana_filter_extensions ? "-ef ${params.katana_filter_extensions}" : ""
    def match_params = params.katana_match_extensions ? "-em ${params.katana_match_extensions}" : ""
    def scope_params = params.katana_crawl_scope ? "-cs '${params.katana_crawl_scope}'" : ""
    def field_params = params.katana_field ? "-f ${params.katana_field}" : ""
    
    """
    # Create empty output files
    touch katana_results.txt katana_results.json katana_forms.json
    
    # Run katana if input file has content
    if [[ -s ${urls_file} ]]; then
        if [[ "${params.katana_json_output}" == "true" ]]; then
            # Run with JSON output
            katana -list ${urls_file} \\
                -o katana_results.json \\
                -silent \\
                ${json_params} \\
                ${depth_params} \\
                ${threads_params} \\
                ${js_crawl_params} \\
                ${tech_detect_params} \\
                ${form_extract_params} \\
                ${xhr_params} \\
                ${delay_params} \\
                ${rate_limit_params} \\
                ${timeout_params} \\
                ${known_files_params} \\
                ${user_agent_params} \\
                ${proxy_params} \\
                ${filter_params} \\
                ${match_params} \\
                ${scope_params} \\
                ${field_params} || true
            
            # Extract URLs from JSON output for text file
            if [[ -s katana_results.json ]]; then
                jq -r '.endpoint // .url // empty' katana_results.json 2>/dev/null | grep -v '^\$' | sort -u > katana_results.txt || true
                
                # If form extraction is enabled, extract forms to separate file
                if [[ "${params.katana_form_extraction}" == "true" ]]; then
                    jq -c 'select(.form != null) | .form' katana_results.json 2>/dev/null > katana_forms.json || true
                fi
            fi
        else
            # Run with text output only
            katana -list ${urls_file} \\
                -o katana_results.txt \\
                -silent \\
                ${depth_params} \\
                ${threads_params} \\
                ${js_crawl_params} \\
                ${tech_detect_params} \\
                ${delay_params} \\
                ${rate_limit_params} \\
                ${timeout_params} \\
                ${known_files_params} \\
                ${user_agent_params} \\
                ${proxy_params} \\
                ${filter_params} \\
                ${match_params} \\
                ${scope_params} \\
                ${field_params} || true
        fi
    fi
    """
}

process KATANA_BATCH {
    tag "batch_${batch_id}"
    publishDir "${params.outdir}/katana", mode: 'copy', enabled: params.publish_intermediates
    maxRetries 3
    
    input:
    tuple val(batch_id), path(urls_chunk)
    
    output:
    path "katana_batch_${batch_id}.txt", emit: crawled_urls
    path "katana_batch_${batch_id}.json", emit: json_output, optional: true
    path "katana_batch_${batch_id}_forms.json", emit: forms_output, optional: true
    
    script:
    def json_params = params.katana_json_output ? "-jsonl" : ""
    def depth_params = "-depth ${params.katana_depth}"
    def threads_params = "-c ${params.katana_concurrency}"
    def js_crawl_params = params.katana_js_crawl ? "-jc" : ""
    def tech_detect_params = params.katana_tech_detect ? "-td" : ""
    def form_extract_params = params.katana_form_extraction ? "-fx" : ""
    def xhr_params = params.katana_xhr_extraction ? "-xhr" : ""
    def delay_params = params.katana_delay > 0 ? "-rd ${params.katana_delay}" : ""
    def rate_limit_params = params.katana_rate_limit > 0 ? "-rl ${params.katana_rate_limit}" : ""
    def timeout_params = "-timeout ${params.katana_timeout}"
    def known_files_params = params.katana_known_files ? "-kf ${params.katana_known_files}" : ""
    def user_agent_params = params.katana_user_agent ? "-H 'User-Agent: ${params.katana_user_agent}'" : ""
    def proxy_params = params.katana_proxy ? "-proxy ${params.katana_proxy}" : ""
    def filter_params = params.katana_filter_extensions ? "-ef ${params.katana_filter_extensions}" : ""
    def match_params = params.katana_match_extensions ? "-em ${params.katana_match_extensions}" : ""
    def scope_params = params.katana_crawl_scope ? "-cs '${params.katana_crawl_scope}'" : ""
    def field_params = params.katana_field ? "-f ${params.katana_field}" : ""
    
    """
    # Create empty output files
    touch katana_batch_${batch_id}.txt katana_batch_${batch_id}.json katana_batch_${batch_id}_forms.json
    
    # Run katana if input file has content
    if [[ -s ${urls_chunk} ]]; then
        if [[ "${params.katana_json_output}" == "true" ]]; then
            # Run with JSON output
            katana -list ${urls_chunk} \\
                -o katana_batch_${batch_id}.json \\
                -silent \\
                ${json_params} \\
                ${depth_params} \\
                ${threads_params} \\
                ${js_crawl_params} \\
                ${tech_detect_params} \\
                ${form_extract_params} \\
                ${xhr_params} \\
                ${delay_params} \\
                ${rate_limit_params} \\
                ${timeout_params} \\
                ${known_files_params} \\
                ${user_agent_params} \\
                ${proxy_params} \\
                ${filter_params} \\
                ${match_params} \\
                ${scope_params} \\
                ${field_params} || true
            
            # Extract URLs from JSON output for text file
            if [[ -s katana_batch_${batch_id}.json ]]; then
                jq -r '.endpoint // .url // empty' katana_batch_${batch_id}.json 2>/dev/null | grep -v '^\$' | sort -u > katana_batch_${batch_id}.txt || true
                
                # If form extraction is enabled, extract forms to separate file
                if [[ "${params.katana_form_extraction}" == "true" ]]; then
                    jq -c 'select(.form != null) | .form' katana_batch_${batch_id}.json 2>/dev/null > katana_batch_${batch_id}_forms.json || true
                fi
            fi
        else
            # Run with text output only
            katana -list ${urls_chunk} \\
                -o katana_batch_${batch_id}.txt \\
                -silent \\
                ${depth_params} \\
                ${threads_params} \\
                ${js_crawl_params} \\
                ${tech_detect_params} \\
                ${delay_params} \\
                ${rate_limit_params} \\
                ${timeout_params} \\
                ${known_files_params} \\
                ${user_agent_params} \\
                ${proxy_params} \\
                ${filter_params} \\
                ${match_params} \\
                ${scope_params} \\
                ${field_params} || true
        fi
    fi
    """
}

process KATANA_PARSE_JSON {
    tag "${json_file.baseName}"
    publishDir "${params.outdir}/katana/parsed", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    path json_file
    
    output:
    path "katana_parsed_urls.txt", emit: urls
    path "katana_parsed_endpoints.txt", emit: endpoints
    path "katana_parsed_forms.json", emit: forms, optional: true
    path "katana_parsed_xhr.json", emit: xhr, optional: true
    path "katana_parsed_js.txt", emit: js_files, optional: true
    path "katana_parsed_tech.json", emit: technologies, optional: true
    path "katana_parsed_summary.json", emit: summary
    
    script:
    """
    # Create empty output files
    touch katana_parsed_urls.txt katana_parsed_endpoints.txt katana_parsed_forms.json katana_parsed_xhr.json katana_parsed_js.txt katana_parsed_tech.json katana_parsed_summary.json
    
    # Parse JSON output if file exists and has content
    if [[ -s ${json_file} ]]; then
        # Extract all URLs/endpoints
        jq -r '.endpoint // .url // empty' ${json_file} 2>/dev/null | grep -v '^\$' | sort -u > katana_parsed_urls.txt || true
        
        # Extract just the endpoints (paths)
        jq -r 'select(.endpoint != null) | .endpoint' ${json_file} 2>/dev/null | sort -u > katana_parsed_endpoints.txt || true
        
        # Extract forms if present
        jq -c 'select(.form != null) | .form' ${json_file} 2>/dev/null > katana_parsed_forms.json || true
        
        # Extract XHR requests if present
        jq -c 'select(.xhr != null) | .xhr' ${json_file} 2>/dev/null > katana_parsed_xhr.json || true
        
        # Extract JavaScript files
        jq -r 'select(.endpoint != null and (.endpoint | test("\\\\.(js|jsx|ts|tsx)\$"))) | .endpoint' ${json_file} 2>/dev/null | sort -u > katana_parsed_js.txt || true
        
        # Extract technology information if present
        jq -c 'select(.tech != null) | {url: (.url // .endpoint), tech: .tech}' ${json_file} 2>/dev/null > katana_parsed_tech.json || true
        
        # Create summary statistics
        {
            echo "{"
            echo "  \\"total_entries\\": \$(jq -s 'length' ${json_file} 2>/dev/null || echo 0),"
            echo "  \\"unique_urls\\": \$(wc -l < katana_parsed_urls.txt 2>/dev/null || echo 0),"
            echo "  \\"endpoints\\": \$(wc -l < katana_parsed_endpoints.txt 2>/dev/null || echo 0),"
            echo "  \\"forms\\": \$(jq -s 'length' katana_parsed_forms.json 2>/dev/null || echo 0),"
            echo "  \\"xhr_requests\\": \$(jq -s 'length' katana_parsed_xhr.json 2>/dev/null || echo 0),"
            echo "  \\"js_files\\": \$(wc -l < katana_parsed_js.txt 2>/dev/null || echo 0),"
            echo "  \\"technologies\\": \$(jq -s 'length' katana_parsed_tech.json 2>/dev/null || echo 0)"
            echo "}"
        } > katana_parsed_summary.json
    fi
    """
}