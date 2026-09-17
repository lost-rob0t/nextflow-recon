include { PREPARE_STARINTEL_ACTOR_REQUESTS; STARINTEL_ACTOR } from '../modules/starintel_actor'

workflow STARINTEL_ACTOR_BATCH {
    take:
    jobs

    main:
    prepared = PREPARE_STARINTEL_ACTOR_REQUESTS(jobs)
    requests = prepared.requests.flatten()
    executed = STARINTEL_ACTOR(requests)

    emit:
    documents = executed.documents
    receipts = executed.receipts
    logs = executed.logs
}
