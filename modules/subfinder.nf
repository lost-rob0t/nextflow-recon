/*
 * Subfinder module for subdomain enumeration
 */

process SUBFINDER {
    tag "${domain}"
    publishDir "${params.outdir}/subfinder", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    val domain
    
    output:
    path "subfinder_${domain}.txt", emit: domains
    
    when:
    params.passive_recon
    
    script:
    """
    subfinder -d ${domain} -o subfinder_${domain}.txt -silent
    """
}

process SUBFINDER_BATCH {
    tag "batch_${batch_id}"
    publishDir "${params.outdir}/subfinder", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    tuple val(batch_id), path(domains_file)
    
    output:
    path "subfinder_batch_${batch_id}.txt", emit: domains
    
    when:
    params.passive_recon
    
    script:
    """
    subfinder -dL ${domains_file} -o subfinder_batch_${batch_id}.txt -silent
    """
}