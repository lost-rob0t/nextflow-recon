/*
 * Gobuster module for directory and file enumeration
 */

process GOBUSTER {
    tag "${url}"
    publishDir "${params.outdir}/gobuster", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    val url
    path wordlist
    
    output:
    path "gobuster_${url.replaceAll('[^a-zA-Z0-9]', '_')}.txt", emit: results
    path "gobuster_${url.replaceAll('[^a-zA-Z0-9]', '_')}_found.txt", emit: found_paths
    
    when:
    params.use_gobuster != false
    
    script:
    def safe_name = url.replaceAll('[^a-zA-Z0-9]', '_')
    def extensions = params.extensions ?: 'php,html,txt,js,json,xml,asp,aspx,jsp'
    def threads = params.threads ?: 50
    def timeout = params.timeout ?: '10s'
    
    """
    # Create empty output files
    touch gobuster_${safe_name}.txt gobuster_${safe_name}_found.txt
    
    # Run gobuster dir mode
    gobuster dir \\
        -u ${url} \\
        -w ${wordlist} \\
        -x ${extensions} \\
        -t ${threads} \\
        -a "Mozilla/5.0 (X11; Linux x86_64; rv:91.0) Gecko/20100101 Firefox/91.0" \\
        --timeout ${timeout} \\
        -k \\
        -q \\
        -o gobuster_${safe_name}.txt \\
        2>/dev/null || true
    
    # Extract found paths
    if [[ -s gobuster_${safe_name}.txt ]]; then
        grep -E "^/" gobuster_${safe_name}.txt | awk '{print "${url}" \$1}' > gobuster_${safe_name}_found.txt || true
    fi
    """
}

process GOBUSTER_BATCH {
    tag "batch_${batch_id}"
    publishDir "${params.outdir}/gobuster", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    tuple val(batch_id), path(urls_file)
    path wordlist
    
    output:
    path "gobuster_batch_${batch_id}.txt", emit: results
    path "gobuster_batch_${batch_id}_found.txt", emit: found_paths
    
    when:
    params.use_gobuster != false
    
    script:
    def extensions = params.extensions ?: 'php,html,txt,js,json,xml,asp,aspx,jsp'
    def threads = params.threads ?: 50
    def timeout = params.timeout ?: '10s'
    
    """
    # Create empty output files
    touch gobuster_batch_${batch_id}.txt gobuster_batch_${batch_id}_found.txt
    
    # Process each URL in the batch
    while IFS= read -r url; do
        [[ -z "\$url" ]] && continue
        [[ "\$url" =~ ^#.*\$ ]] && continue
        [[ ! "\$url" =~ ^https?:// ]] && continue
        
        echo "Processing: \$url"
        
        # Run gobuster for this URL
        gobuster dir \\
            -u "\$url" \\
            -w ${wordlist} \\
            -x ${extensions} \\
            -t ${threads} \\
            -a "Mozilla/5.0 (X11; Linux x86_64; rv:91.0) Gecko/20100101 Firefox/91.0" \\
            --timeout ${timeout} \\
            -k \\
            -q \\
            2>/dev/null | while read -r line; do
                if [[ "\$line" =~ ^/ ]]; then
                    echo "\$url\$line" >> gobuster_batch_${batch_id}_found.txt
                fi
                echo "\$line" >> gobuster_batch_${batch_id}.txt
            done || true
        
        # Small delay to avoid overwhelming the target
        sleep 0.1
        
    done < ${urls_file}
    
    # Sort and deduplicate results
    sort -u gobuster_batch_${batch_id}_found.txt -o gobuster_batch_${batch_id}_found.txt || true
    """
}

process GOBUSTER_VHOST {
    tag "${domain}"
    publishDir "${params.outdir}/gobuster", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    val domain
    path wordlist
    
    output:
    path "gobuster_vhost_${domain.replaceAll('[^a-zA-Z0-9]', '_')}.txt", emit: results
    path "gobuster_vhost_${domain.replaceAll('[^a-zA-Z0-9]', '_')}_found.txt", emit: found_vhosts
    
    when:
    params.use_gobuster_vhost == true
    
    script:
    def safe_name = domain.replaceAll('[^a-zA-Z0-9]', '_')
    def threads = params.threads ?: 50
    def timeout = params.timeout ?: '10s'
    
    """
    # Create empty output files
    touch gobuster_vhost_${safe_name}.txt gobuster_vhost_${safe_name}_found.txt
    
    # Run gobuster vhost mode
    gobuster vhost \\
        -u https://${domain} \\
        -w ${wordlist} \\
        -t ${threads} \\
        -a "Mozilla/5.0 (X11; Linux x86_64; rv:91.0) Gecko/20100101 Firefox/91.0" \\
        --timeout ${timeout} \\
        -k \\
        -q \\
        -o gobuster_vhost_${safe_name}.txt \\
        2>/dev/null || true
    
    # Extract found vhosts
    if [[ -s gobuster_vhost_${safe_name}.txt ]]; then
        grep -E "Found:" gobuster_vhost_${safe_name}.txt | awk '{print \$2}' > gobuster_vhost_${safe_name}_found.txt || true
    fi
    """
}