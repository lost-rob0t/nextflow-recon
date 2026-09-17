#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { STARINTEL_ACTOR_BATCH } from './subworkflows/starintel_actors'


def actor_help() {
    log.info """
    StarIntel local actor workflow

    Usage:
        nextflow run actors.nf --starintel_actor_jobs jobs.ndjson

    Job format (one JSON object per line):
        {"id":"usernames-1","actor":"generate-usernames","args":["starintel:person:1","--first-name","Ada","--last-name","Lovelace"]}

    Options:
        --starintel_actor_jobs <file>       NDJSON actor jobs file
        --starintel_actor_cli <command>     Local launcher (default: starintel-actor)
        --starintel_actor_max_forks <n>     Maximum concurrent actor processes (default: 8)
        --starintel_actor_fail_fast         Stop when an actor returns non-zero (default: false)
        --starintel_actor_outdir <dir>      Actor result directory
    """.stripIndent()
}

workflow {
    if (params.help) {
        actor_help()
        exit 0
    }
    if (!params.starintel_actor_jobs) {
        actor_help()
        error("--starintel_actor_jobs is required")
    }

    jobs = Channel.fromPath(params.starintel_actor_jobs, checkIfExists: true)
    results = STARINTEL_ACTOR_BATCH(jobs)

    results.receipts.view { receipt -> "StarIntel actor receipt: ${receipt}" }
}
