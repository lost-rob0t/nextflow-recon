#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ACTOR_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,127}$")


def parse_job(raw: str, line_number: int) -> dict[str, Any]:
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ValueError(f"line {line_number}: invalid JSON: {exc.msg}") from exc
    if not isinstance(value, dict):
        raise ValueError(f"line {line_number}: job must be a JSON object")

    actor = value.get("actor")
    args = value.get("args", [])
    job_id = value.get("id", f"job-{line_number:06d}")

    if not isinstance(actor, str) or not ACTOR_RE.fullmatch(actor):
        raise ValueError(f"line {line_number}: actor must be a lowercase actor id")
    if not isinstance(args, list) or not all(isinstance(item, str) for item in args):
        raise ValueError(f"line {line_number}: args must be an array of strings")
    if not isinstance(job_id, str) or not job_id.strip():
        raise ValueError(f"line {line_number}: id must be a non-empty string when supplied")

    return {"id": job_id, "actor": actor, "args": args}


def expand(input_path: Path, output_dir: Path) -> int:
    output_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for line_number, raw in enumerate(input_path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        job = parse_job(line, line_number)
        count += 1
        actor = job["actor"]
        path = output_dir / f"{count:06d}-{actor}.json"
        path.write_text(
            json.dumps(job, sort_keys=True, separators=(",", ":")) + "\n",
            encoding="utf-8",
        )
    if count == 0:
        raise ValueError("actor jobs file contains no runnable jobs")
    return count


def main() -> int:
    parser = argparse.ArgumentParser(description="Expand StarIntel actor NDJSON into request files")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    try:
        count = expand(args.input, args.output_dir)
    except (OSError, ValueError) as exc:
        print(f"expand-starintel-actor-jobs: {exc}", file=sys.stderr)
        return 2
    print(count)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
