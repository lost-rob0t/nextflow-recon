from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).parents[1] / "bin" / "expand_starintel_actor_jobs.py"
SPEC = importlib.util.spec_from_file_location("expand_starintel_actor_jobs", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ActorJobExpansionTests(unittest.TestCase):
    def test_parse_job_preserves_argv_as_data(self) -> None:
        payload = {
            "id": "safe-argv",
            "actor": "generate-usernames",
            "args": ["person:1", "$(touch /tmp/should-not-run)", "hello world", "a;b"],
        }
        parsed = MODULE.parse_job(json.dumps(payload), 1)
        self.assertEqual(parsed, payload)

    def test_expand_writes_one_request_per_non_comment_line(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            jobs = root / "jobs.ndjson"
            output = root / "requests"
            jobs.write_text(
                "# comment\n"
                '{"actor":"generate-usernames","args":["person:1"]}\n'
                '\n'
                '{"id":"hunt","actor":"user-hunt","args":["neo"]}\n',
                encoding="utf-8",
            )

            count = MODULE.expand(jobs, output)

            self.assertEqual(count, 2)
            requests = sorted(output.glob("*.json"))
            self.assertEqual(len(requests), 2)
            first = json.loads(requests[0].read_text(encoding="utf-8"))
            second = json.loads(requests[1].read_text(encoding="utf-8"))
            self.assertEqual(first["actor"], "generate-usernames")
            self.assertEqual(second["id"], "hunt")

    def test_invalid_actor_id_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "lowercase actor id"):
            MODULE.parse_job('{"actor":"bad actor","args":[]}', 7)

    def test_args_must_be_string_array(self) -> None:
        with self.assertRaisesRegex(ValueError, "array of strings"):
            MODULE.parse_job('{"actor":"x","args":[1]}', 3)


if __name__ == "__main__":
    unittest.main()
