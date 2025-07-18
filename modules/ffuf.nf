/*
 * FFUF module for fast web fuzzing
 */

process FFUF {
    tag "${url}"
    publishDir "${params.outdir}/ffuf", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    val url
    path wordlist
    
    output:
    path "ffuf_${url.replaceAll('[^a-zA-Z0-9]', '_')}.json", emit: results
    path "ffuf_${url.replaceAll('[^a-zA-Z0-9]', '_')}_found.txt", emit: found_paths
    
    when:
    params.use_ffuf != false
    
    script:
    def safe_name = url.replaceAll('[^a-zA-Z0-9]', '_')
    def extensions = params.extensions ?: 'php,html,txt,js,json,xml,asp,aspx,jsp'
    def threads = params.threads ?: 50
    def timeout = params.timeout ?: '10s'
    
    """
    # Create empty output files
    touch ffuf_${safe_name}.json ffuf_${safe_name}_found.txt
    
    # Run ffuf for directory enumeration
    ffuf \\
        -u ${url}/FUZZ \\
        -w ${wordlist} \\
        -e ${extensions} \\
        -t ${threads} \\
        -timeout ${timeout} \\
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:91.0) Gecko/20100101 Firefox/91.0" \\
        -ac \\
        -s \\
        -o ffuf_${safe_name}.json \\
        -of json \\
        2>/dev/null || true
    
    # Extract found paths from JSON output
    if [[ -s ffuf_${safe_name}.json ]]; then
        jq -r '.results[]? | .url' ffuf_${safe_name}.json 2>/dev/null | sort -u > ffuf_${safe_name}_found.txt || true
    fi
    """
}

process FFUF_BATCH {
    tag "batch_${batch_id}"
    publishDir "${params.outdir}/ffuf", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    tuple val(batch_id), path(urls_file)
    path wordlist
    
    output:
    path "ffuf_batch_${batch_id}.json", emit: results
    path "ffuf_batch_${batch_id}_found.txt", emit: found_paths
    
    when:
    params.use_ffuf != false
    
    script:
    def extensions = params.extensions ?: 'php,html,txt,js,json,xml,asp,aspx,jsp'
    def threads = params.threads ?: 50
    def timeout = params.timeout ?: '10s'
    
    """
    # Create empty output files
    touch ffuf_batch_${batch_id}.json ffuf_batch_${batch_id}_found.txt
    echo '{"results": []}' > ffuf_batch_${batch_id}.json
    
    # Process each URL in the batch
    while IFS= read -r url; do
        [[ -z "\$url" ]] && continue
        [[ "\$url" =~ ^#.*\$ ]] && continue
        [[ ! "\$url" =~ ^https?:// ]] && continue
        
        echo "Processing: \$url"
        
        # Create temporary output file
        temp_output="\$(mktemp)"
        
        # Run ffuf for this URL
        ffuf \\
            -u "\$url/FUZZ" \\
            -w ${wordlist} \\
            -e ${extensions} \\
            -t ${threads} \\
            -timeout ${timeout} \\
            -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:91.0) Gecko/20100101 Firefox/91.0" \\
            -ac \\
            -s \\
            -o "\$temp_output" \\
            -of json \\
            2>/dev/null || true
        
        # Extract results from temporary file
        if [[ -s "\$temp_output" ]]; then
            jq -r '.results[]? | .url' "\$temp_output" 2>/dev/null >> ffuf_batch_${batch_id}_found.txt || true
        fi
        
        # Clean up
        rm -f "\$temp_output"
        
        # Small delay to avoid overwhelming the target
        sleep 0.1
        
    done < ${urls_file}
    
    # Sort and deduplicate results
    sort -u ffuf_batch_${batch_id}_found.txt -o ffuf_batch_${batch_id}_found.txt || true
    """
}

process FFUF_PARAMETERS {
    tag "${url}"
    publishDir "${params.outdir}/ffuf", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    val url
    path wordlist
    
    output:
    path "ffuf_params_${url.replaceAll('[^a-zA-Z0-9]', '_')}.json", emit: results
    path "ffuf_params_${url.replaceAll('[^a-zA-Z0-9]', '_')}_found.txt", emit: found_params
    
    when:
    params.use_ffuf_params == true
    
    script:
    def safe_name = url.replaceAll('[^a-zA-Z0-9]', '_')
    def threads = params.threads ?: 50
    def timeout = params.timeout ?: '10s'
    
    """
    # Create empty output files
    touch ffuf_params_${safe_name}.json ffuf_params_${safe_name}_found.txt
    
    # Run ffuf for parameter enumeration
    ffuf \\
        -u "${url}?FUZZ=test" \\
        -w ${wordlist} \\
        -t ${threads} \\
        -timeout ${timeout} \\
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:91.0) Gecko/20100101 Firefox/91.0" \\
        -ac \\
        -s \\
        -o ffuf_params_${safe_name}.json \\
        -of json \\
        2>/dev/null || true
    
    # Extract found parameters
    if [[ -s ffuf_params_${safe_name}.json ]]; then
        jq -r '.results[]? | .input.FUZZ' ffuf_params_${safe_name}.json 2>/dev/null | sort -u > ffuf_params_${safe_name}_found.txt || true
    fi
    """
}

process FFUF_VHOST {
    tag "${domain}"
    publishDir "${params.outdir}/ffuf", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    val domain
    path wordlist
    
    output:
    path "ffuf_vhost_${domain.replaceAll('[^a-zA-Z0-9]', '_')}.json", emit: results
    path "ffuf_vhost_${domain.replaceAll('[^a-zA-Z0-9]', '_')}_found.txt", emit: found_vhosts
    
    when:
    params.use_ffuf_vhost == true
    
    script:
    def safe_name = domain.replaceAll('[^a-zA-Z0-9]', '_')
    def threads = params.threads ?: 50
    def timeout = params.timeout ?: '10s'
    
    """
    # Create empty output files
    touch ffuf_vhost_${safe_name}.json ffuf_vhost_${safe_name}_found.txt
    
    # Run ffuf for vhost enumeration
    ffuf \\
        -u https://${domain} \\
        -w ${wordlist} \\
        -H "Host: FUZZ.${domain}" \\
        -t ${threads} \\
        -timeout ${timeout} \\
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:91.0) Gecko/20100101 Firefox/91.0" \\
        -ac \\
        -s \\
        -o ffuf_vhost_${safe_name}.json \\
        -of json \\
        2>/dev/null || true
    
    # Extract found vhosts
    if [[ -s ffuf_vhost_${safe_name}.json ]]; then
        jq -r '.results[]? | .input.FUZZ' ffuf_vhost_${safe_name}.json 2>/dev/null | sort -u > ffuf_vhost_${safe_name}_found.txt || true
    fi
    """
}