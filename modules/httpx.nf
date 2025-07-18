/*
 * HTTPx module for HTTP probing
 */

process HTTPX {
    tag "${domains_file.baseName}"
    publishDir "${params.outdir}/httpx", mode: 'copy', enabled: params.publish_intermediates
    maxRetries 3
    
    input:
    path domains_file
    
    output:
    path "httpx_live.txt", emit: live_hosts
    path "httpx_results.json", emit: json_output, optional: true

    script:
    def json_params = params.httpx_json_output ? "-json" : ""
    def tech_params = params.httpx_tech_detect ? "-tech-detect" : ""
    def hash_params = params.httpx_hash_calculate ? "-hash sha256,md5,mmh3" : ""
    def jarm_params = params.httpx_jarm ? "-jarm" : ""
    
    """
    # Create empty output files
    touch httpx_live.txt httpx_results.json
    
    # Run httpx if input file has content
    if [[ -s ${domains_file} ]]; then
        if [[ "${params.httpx_json_output}" == "true" ]]; then
            httpx -l ${domains_file} \\
                -o httpx_results.json \\
                -silent \\
                -threads ${params.httpx_threads} \\
                ${json_params} ${tech_params} ${hash_params} ${jarm_params} || true
            
            # Extract URLs from JSON
            if [[ -s httpx_results.json ]]; then
                jq -r '.url // empty' httpx_results.json 2>/dev/null | grep -v '^\$' | sort -u > httpx_live.txt || true
            fi
        else
            httpx -l ${domains_file} \\
                -o httpx_live.txt \\
                -silent \\
                -threads ${params.httpx_threads} || true
        fi
    fi
    """
}
