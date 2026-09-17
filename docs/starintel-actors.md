# StarIntel local actors in Nextflow

`actors.nf` turns the local `starintel-actor` contract into a reusable DSL2 batch workflow. The workflow does **not** know how any individual actor works; Python/Pykka, Typer collectors, Common Lisp/Sento code, and other runtimes stay behind the local dispatcher.

## Job file

Use NDJSON, one job per line:

```json
{"id":"ada-usernames","actor":"generate-usernames","args":["starintel:person:ada","--first-name","Ada","--last-name","Lovelace","--max-candidates","20"]}
{"id":"ada-hunt","actor":"user-hunt","args":["ada_lovelace","--site","GitHub","--timeout","15"]}
```

Blank lines and lines beginning with `#` are ignored. `actor` must be a lowercase actor id and `args` must be an array of strings. Arguments are preserved as data; they are never concatenated into a shell command.

## Run

```sh
nextflow run actors.nf \
  --starintel_actor_jobs examples/starintel-actor-jobs.ndjson \
  --starintel_actor_cli "$PWD/../starintel-pro-actors/python/.venv/bin/starintel-actor" \
  --starintel_actor_max_forks 8
```

By default results are copied to `./results/starintel-actors`.

Each task produces three files:

- `actor-*.jsonl` — actor documents written to stdout.
- `actor-*.stderr.log` — diagnostics and actor summaries.
- `actor-*.receipt.json` — `id`, actor, argv, exit code, and an `ok` boolean.

The default is **record-and-continue**: a failed actor gets a receipt with a non-zero exit code, but unrelated jobs keep running. Add `--starintel_actor_fail_fast true` when a non-zero actor exit should fail the Nextflow task.

## Reuse as a subworkflow

```nextflow
include { STARINTEL_ACTOR_BATCH } from './subworkflows/starintel_actors'

workflow {
    jobs = Channel.fromPath(params.starintel_actor_jobs, checkIfExists: true)
    results = STARINTEL_ACTOR_BATCH(jobs)

    results.documents.view()
    results.receipts.view()
}
```

`PREPARE_STARINTEL_ACTOR_REQUESTS` expands the NDJSON into immutable JSON request files, then `STARINTEL_ACTOR` fans those requests out as independent tasks. The process uses `maxForks` to bound concurrent local actors while still allowing the same module to run under local, Slurm, Kubernetes, or batch executors.

## Interactive vs batch

Use `starintel-actor run ...` or a direct `starintel-pro-actor-*` alias for interactive and near-real-time one-shot work. Use `actors.nf` when you want scheduling, fan-out, executor portability, receipts, and reproducible batch runs. Both paths call the same actor implementation.
