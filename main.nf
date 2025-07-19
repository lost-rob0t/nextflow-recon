#!/usr/bin/env nextflow

/*
 * Hackmode Security Reconnaissance Framework
 * Main workflow entry point
 */

nextflow.enable.dsl = 2

// Include modules and subworkflows
include { BBRF_GET_DOMAINS; BBRF_GET_INSCOPE_DOMAINS; BBRF_GET_URLS; BBRF_GET_URLS_FULL; BBRF_GET_IPS } from './modules/bbrf'
include { SUBFINDER } from './modules/subfinder'
include { ASSETFINDER } from './modules/assetfinder'
include { KATANA; KATANA_PARSE_JSON } from './modules/katana'
include { PASSIVE_RECON } from './subworkflows/passive_recon'
include { ACTIVE_RECON } from './subworkflows/active_recon'
include { WEB_CRAWL; WEB_CRAWL_FROM_DOMAINS } from './subworkflows/web_crawl'
include { UPLOAD } from './subworkflows/upload'

// Help message
def help_message() {
    log.info"""
    Hackmode Security Reconnaissance Framework
    
    Usage:
        nextflow run main.nf [options]
    
    Options:
        --input <file>              Input file with targets
        --outdir <directory>        Output directory (default: ./results)
        --bbrf_program <name>       BBRF program name
        --use_bbrf_targets          Use targets from BBRF database
        --passive_recon             Enable passive reconnaissance
        --active_recon              Enable active reconnaissance
        --web_crawl                 Enable web crawling with Katana
        --help                      Show this help message
    
    Examples:
        nextflow run main.nf --passive_recon
        nextflow run main.nf --bbrf_program my-program --use_bbrf_targets
        nextflow run main.nf --active_recon --web_crawl --bbrf_program my-program
    """.stripIndent()
}

// Parameter validation
def validate_parameters() {
    if (params.help) {
        help_message()
        exit 0
    }
    
    if (!params.use_bbrf_targets && !params.input) {
        error("Error: Either --input or --use_bbrf_targets must be specified")
    }
    
    if (params.bbrf_program == null || params.bbrf_program == '') {
        error("Error: --bbrf_program must be specified")
    }
}

// Main workflow
workflow {
    validate_parameters()

    targets_ch = Channel.empty()
    existing_domains_ch = Channel.empty()
    existing_urls_ch = Channel.empty()

    if (params.use_bbrf_targets) {
        bbrf_domains = BBRF_GET_DOMAINS(params.bbrf_program)
        bbrf_inscope = BBRF_GET_INSCOPE_DOMAINS(params.bbrf_program)
        bbrf_urls = BBRF_GET_URLS(params.bbrf_program)
        bbrf_urls_full = BBRF_GET_URLS_FULL(params.bbrf_program)
        bbrf_ips = BBRF_GET_IPS(params.bbrf_program)

        targets_ch = bbrf_inscope.domains
            .splitText()
            .map { it.trim() }
            .filter { it && !it.startsWith('#') }

        existing_domains_ch = bbrf_domains.domains
        existing_urls_ch = bbrf_urls.urls

        bbrf_urls_full.urls_full.view { "BBRF URLs with status codes: ${it}" }
        bbrf_urls_full.urls_parsed.view { "BBRF URLs parsed JSON: ${it}" }

    } else {
        targets_ch = Channel.fromPath(params.input)
            .splitText()
            .map { it.trim() }
            .filter { it && !it.startsWith('#') }
    }

    all_domains = Channel.empty()
    all_urls = Channel.empty()
    all_crawled_urls = Channel.empty()
    active_results = Channel.empty()
    if (params.use_bbrf_targets) {
        all_urls = all_urls.mix(bbrf_urls_full.urls_full)
    }

    if (params.passive_recon) {
        passive_results = PASSIVE_RECON(targets_ch, existing_domains_ch)
        all_domains = all_domains.mix(passive_results.new_subdomains)

        passive_results.subdomains.view { "Passive recon found subdomains: ${it}" }

        if (params.active_recon) {
            active_results = ACTIVE_RECON(targets_ch.mix(passive_results.subdomains))
            all_urls = all_urls.mix(active_results.live_hosts)
            active_results.live_hosts.view { "Active recon found live hosts: ${it}" }
        }
        if (params.web_crawl) {
            crawl_results = WEB_CRAWL(targets_ch.mix(active_results))
            all_crawled_urls = all_crawled_urls.mix(crawl_results.crawled_urls)
            crawl_results.crawled_urls.view { "Web crawl found URLs: ${it}" }
            if (params.katana_json_output) {
                crawl_results.summary.view { "Crawl summary: ${it}" }
            }
        }


        // Even if active recon is on, also crawl directly from subdomains concurrently
        if (params.web_crawl) {
            crawl_results_from_domains = WEB_CRAWL_FROM_DOMAINS(passive_results.subdomains)
            all_crawled_urls = all_crawled_urls.mix(crawl_results_from_domains.crawled_urls)
            crawl_results_from_domains.crawled_urls.view { "Web crawl (from domains) found URLs: ${it}" }
            if (params.katana_json_output) {
                crawl_results_from_domains.summary.view { "Crawl summary from domains: ${it}" }
            }
        }

    } else if (params.active_recon) {
        active_results = ACTIVE_RECON(targets_ch)
        all_urls = all_urls.mix(active_results.live_hosts)
        active_results.live_hosts.view { "Active recon found live hosts: ${it}" }

        if (params.web_crawl) {
            crawl_results = WEB_CRAWL(active_results.live_hosts)
            all_crawled_urls = all_crawled_urls.mix(crawl_results.crawled_urls)
            crawl_results.crawled_urls.view { "Web crawl found URLs: ${it}" }
            if (params.katana_json_output) {
                crawl_results.summary.view { "Crawl summary: ${it}" }
            }
        }

    } else if (params.web_crawl) {
        if (params.use_bbrf_targets) {
            crawl_results = WEB_CRAWL(existing_urls_ch)
        } else {
            crawl_results = WEB_CRAWL_FROM_DOMAINS(targets_ch)
        }
        all_crawled_urls = all_crawled_urls.mix(crawl_results.crawled_urls)
        crawl_results.crawled_urls.view { "Web crawl found URLs: ${it}" }
        if (params.katana_json_output) {
            crawl_results.summary.view { "Crawl summary: ${it}" }
        }
    }
}
