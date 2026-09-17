/*
 * Generic StarIntel actor execution.
 *
 * Requests use the stable local CLI contract:
 *   {"id":"job-1","actor":"generate-usernames","args":[...]}
 *
 * The process never builds shell command text from actor arguments.  The
 * starintel-actor launcher reads JSON and executes an argv vector directly.
 */

process PREPARE_STARINTEL_ACTOR_REQUESTS {
    tag "${jobs.baseName}"

    input:
    path jobs

    output:
    path "actor-requests/*.json", emit: requests

    script:
    """
    python3 ${projectDir}/bin/expand_starintel_actor_jobs.py \
        --input ${jobs} \
        --output-dir actor-requests
    """
}

process STARINTEL_ACTOR {
    tag "${request.baseName}"
    publishDir "${params.starintel_actor_outdir ?: params.outdir + '/starintel-actors'}",
        mode: 'copy', overwrite: false
    maxForks (params.starintel_actor_max_forks ?: 8)

    input:
    path request

    output:
    path "actor-*.jsonl", emit: documents
    path "actor-*.receipt.json", emit: receipts
    path "actor-*.stderr.log", emit: logs

    script:
    def actorCli = params.starintel_actor_cli ?: 'starintel-actor'
    def failFast = params.starintel_actor_fail_fast ? '1' : '0'
    def index = task.index
    """
    set -u

    set +e
    "${actorCli}" request "${request}" \
        > "actor-${index}.jsonl" \
        2> "actor-${index}.stderr.log"
    rc=\$?
    set -e

    python3 - "${request}" "\$rc" "actor-${index}.receipt.json" <<'PY'
import json
import sys
from pathlib import Path

request_path = Path(sys.argv[1])
exit_code = int(sys.argv[2])
receipt_path = Path(sys.argv[3])
request = json.loads(request_path.read_text(encoding="utf-8"))
receipt = {
    "id": request.get("id"),
    "actor": request["actor"],
    "args": request.get("args", []),
    "exit_code": exit_code,
    "ok": exit_code == 0,
}
receipt_path.write_text(
    json.dumps(receipt, sort_keys=True, separators=(",", ":")) + "\n",
    encoding="utf-8",
)
PY

    if [ "\$rc" -ne 0 ] && [ "${failFast}" = "1" ]; then
        exit "\$rc"
    fi
    """
}
