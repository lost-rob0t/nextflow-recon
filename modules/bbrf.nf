/*
 * BBRF (Bug Bounty Reconnaissance Framework) integration modules
 */

def getTimestamp() {
    return new Date().format('yyyy-MM-dd_HH-mm-ss')
}
process BBRF_GET_DOMAINS {
    tag "get_domains"
    maxRetries 5
    
    input:
    val program
    
    output:
    path "bbrf_domains.txt", emit: domains
    
    when:
    params.use_bbrf_targets
    
    script:
    """
    bbrf domains -p ${program} > bbrf_domains.txt
    """
}

process BBRF_GET_IPS {
    tag "get_ips"
    maxRetries 5
    
    input:
    val program
    
    output:
    path "bbrf_ips.txt", emit: ips
    
    when:
    params.use_bbrf_targets
    
    script:
    """
    bbrf ips -p ${program} > bbrf_ips.txt
    """
}

process BBRF_GET_URLS {
    tag "get_urls"
    maxRetries 5
    
    input:
    val program
    
    output:
    path "bbrf_urls.txt", emit: urls
    
    when:
    params.use_bbrf_targets
    
    script:
    """
    # Get URLs and strip status codes and extra info, keep only the URL part
    bbrf urls -p ${program} | awk '{print \$1}' > bbrf_urls.txt
    """
}

process BBRF_GET_URLS_FULL {
    tag "get_urls_full"
    maxRetries 5
    
    input:
    val program
    
    output:
    path "bbrf_urls_full.txt", emit: urls_full
    path "bbrf_urls_parsed.json", emit: urls_parsed
    
    when:
    params.use_bbrf_targets
    
    script:
    """
    # Get URLs with status codes and extra info (full format)
    bbrf urls -p ${program} > bbrf_urls_full.txt
    
    # Parse URLs with status codes and extra info into JSON format
    echo '{"urls": [' > bbrf_urls_parsed.json
    
    first=true
    while IFS= read -r line; do
        [[ -z "\$line" ]] && continue
        [[ "\$line" =~ ^#.*\$ ]] && continue
        
        # Parse the line: URL [status_code] [extra_info]
        url=\$(echo "\$line" | awk '{print \$1}')
        status_code=\$(echo "\$line" | awk '{print \$2}')
        extra_info=\$(echo "\$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", \$i; print ""}' | sed 's/[[:space:]]*\$//')
        
        # Only process if URL is not empty
        if [[ -n "\$url" ]]; then
            # Add comma if not first entry
            if [[ "\$first" != "true" ]]; then
                echo ',' >> bbrf_urls_parsed.json
            fi
            first=false
            
            # Create JSON object
            echo -n '  {' >> bbrf_urls_parsed.json
            echo -n '"url": "'\$url'"' >> bbrf_urls_parsed.json
            
            if [[ -n "\$status_code" && "\$status_code" != "\$url" ]]; then
                echo -n ', "status_code": "'\$status_code'"' >> bbrf_urls_parsed.json
            fi
            
            if [[ -n "\$extra_info" ]]; then
                echo -n ', "extra_info": "'\$extra_info'"' >> bbrf_urls_parsed.json
            fi
            
            echo -n '}' >> bbrf_urls_parsed.json
        fi
    done < bbrf_urls_full.txt
    
    echo '' >> bbrf_urls_parsed.json
    echo ']}' >> bbrf_urls_parsed.json
    
    # Validate JSON
    if ! jq . bbrf_urls_parsed.json > /dev/null 2>&1; then
        echo '{"urls": []}' > bbrf_urls_parsed.json
    fi
    """
}

process BBRF_GET_INSCOPE_DOMAINS {
    tag "get_inscope"
    maxRetries 5
    
    input:
    val program
    
    output:
    path "bbrf_inscope.txt", emit: domains
    
    when:
    params.use_bbrf_targets
    
    script:
    """
    bbrf scope in --wildcard -p ${program} > bbrf_inscope.txt
    """
}

process BBRF_UPLOAD_DOMAINS {
    tag "upload_domains"
    publishDir "${params.outdir}/bbrf", mode: 'copy', enabled: params.publish_intermediates
    maxRetries 5
    
    input:
    path domains_file
    val program

    output:
    path "bbrf_upload_domains.log", emit: upload_log
    
    when:
    params.upload_to_bbrf
    
    script:
    """
    bbrf domain add -f ${domains_file} -p ${program} -t "source:automation" -t "date:${getTimestamp()}"  - > bbrf_upload_domains.log 2>&1
    """
}

process BBRF_UPLOAD_URLS {
    tag "upload_urls"
    publishDir "${params.outdir}/bbrf", mode: 'copy', enabled: params.publish_intermediates
    maxRetries 5
    
    input:
    path urls_file
    val program

    output:
    path "bbrf_upload_urls.log", emit: upload_log
    
    when:
    params.upload_to_bbrf && urls_file.exists() && urls_file.size() > 0
    
    script:
    """
    cat ${urls_file} | bbrf url add -p ${program} -t "source:automation" -t "date:${getTimestamp()}" - > bbrf_upload_urls.log 2>&1
    """
}

process BBRF_GET_TAG {
    input:
    val tag

    output: "targets-${tag.replaceAll('[^a-zA-Z0-9]', '_')}.txt"
    script:
    """
    bbrf tags -p ${program} ${tag} | awk '{print \$1}' > targets-${tag.replaceAll('[^a-zA-Z0-9]', '_')}.txt
    """
}
