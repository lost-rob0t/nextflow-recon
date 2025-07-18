/*
 * DirBuster module for directory and file enumeration
 */

process DIRBUSTER {
    tag "${url}"
    publishDir "${params.outdir}/dirbuster", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    val url
    path wordlist
    
    output:
    path "dirbuster_${url.replaceAll('[^a-zA-Z0-9]', '_')}.txt", emit: results
    path "dirbuster_${url.replaceAll('[^a-zA-Z0-9]', '_')}_found.txt", emit: found_paths
    
    when:
    params.use_dirbuster == true
    
    script:
    def safe_name = url.replaceAll('[^a-zA-Z0-9]', '_')
    def extensions = params.extensions ?: 'php,html,txt,js,json,xml,asp,aspx,jsp'
    def threads = params.threads ?: 50
    def timeout = params.timeout ?: '10s'
    
    """
    # Create empty output files
    touch dirbuster_${safe_name}.txt dirbuster_${safe_name}_found.txt
    
    # Create DirBuster configuration file
    cat > dirbuster_config_${safe_name}.properties << EOF
# DirBuster Configuration
target.url=${url}
wordlist.file=${wordlist}
extensions=${extensions}
threads=${threads}
timeout=${timeout}
EOF
    
    # Run dirb (lightweight alternative to DirBuster)
    dirb ${url} ${wordlist} \\
        -o dirbuster_${safe_name}.txt \\
        -w \\
        -S \\
        -X ".${extensions.replace(',', ',.')}" \\
        2>/dev/null || true
    
    # Extract found paths
    if [[ -s dirbuster_${safe_name}.txt ]]; then
        grep -E "^==> DIRECTORY:|^+ " dirbuster_${safe_name}.txt | \\
        sed -E 's/^==> DIRECTORY: //; s/^+ //' | \\
        grep -E "^https?://" > dirbuster_${safe_name}_found.txt || true
    fi
    """
}

process DIRBUSTER_RECURSIVE {
    tag "${url}"
    publishDir "${params.outdir}/dirbuster", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    val url
    path wordlist
    
    output:
    path "dirbuster_recursive_${url.replaceAll('[^a-zA-Z0-9]', '_')}.txt", emit: results
    path "dirbuster_recursive_${url.replaceAll('[^a-zA-Z0-9]', '_')}_found.txt", emit: found_paths
    
    when:
    params.use_dirbuster_recursive == true
    
    script:
    def safe_name = url.replaceAll('[^a-zA-Z0-9]', '_')
    def extensions = params.extensions ?: 'php,html,txt,js,json,xml,asp,aspx,jsp'
    def threads = params.threads ?: 50
    def timeout = params.timeout ?: '10s'
    def max_depth = params.max_depth ?: 3
    
    """
    # Create empty output files
    touch dirbuster_recursive_${safe_name}.txt dirbuster_recursive_${safe_name}_found.txt
    
    # Run dirb with recursive scanning
    dirb ${url} ${wordlist} \\
        -o dirbuster_recursive_${safe_name}.txt \\
        -w \\
        -S \\
        -r \\
        -X ".${extensions.replace(',', ',.')}" \\
        2>/dev/null || true
    
    # Extract found paths
    if [[ -s dirbuster_recursive_${safe_name}.txt ]]; then
        grep -E "^==> DIRECTORY:|^+ " dirbuster_recursive_${safe_name}.txt | \\
        sed -E 's/^==> DIRECTORY: //; s/^+ //' | \\
        grep -E "^https?://" > dirbuster_recursive_${safe_name}_found.txt || true
    fi
    """
}

process DIRBUSTER_CUSTOM {
    tag "${url}"
    publishDir "${params.outdir}/dirbuster", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    val url
    path wordlist
    val custom_options
    
    output:
    path "dirbuster_custom_${url.replaceAll('[^a-zA-Z0-9]', '_')}.txt", emit: results
    path "dirbuster_custom_${url.replaceAll('[^a-zA-Z0-9]', '_')}_found.txt", emit: found_paths
    
    when:
    params.use_dirbuster_custom == true
    
    script:
    def safe_name = url.replaceAll('[^a-zA-Z0-9]', '_')
    def extensions = params.extensions ?: 'php,html,txt,js,json,xml,asp,aspx,jsp'
    
    """
    # Create empty output files
    touch dirbuster_custom_${safe_name}.txt dirbuster_custom_${safe_name}_found.txt
    
    # Run dirb with custom options
    dirb ${url} ${wordlist} \\
        -o dirbuster_custom_${safe_name}.txt \\
        -w \\
        -S \\
        -X ".${extensions.replace(',', ',.')}" \\
        ${custom_options} \\
        2>/dev/null || true
    
    # Extract found paths
    if [[ -s dirbuster_custom_${safe_name}.txt ]]; then
        grep -E "^==> DIRECTORY:|^+ " dirbuster_custom_${safe_name}.txt | \\
        sed -E 's/^==> DIRECTORY: //; s/^+ //' | \\
        grep -E "^https?://" > dirbuster_custom_${safe_name}_found.txt || true
    fi
    """
}