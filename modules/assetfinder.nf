/*
 * Assetfinder module for asset discovery
 */

process ASSETFINDER {
    tag "${domain}"
    publishDir "${params.outdir}/assetfinder", mode: 'copy', enabled: params.publish_intermediates
    
    input:
    val domain
    
    output:
    path "assetfinder_${domain}.txt", emit: domains
    
    when:
    params.passive_recon && params.enable_assetfinder
    
    script:
    """
    assetfinder --subs-only ${domain} > assetfinder_${domain}.txt
    """
}