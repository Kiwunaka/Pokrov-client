from __future__ import annotations

import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def test_source_tag_readiness_seed_defines_read_only_command() -> None:
    seed = _read_json("config/source-tag-readiness.seed.json")

    assert seed["script"] == "scripts/check-source-tag-readiness.ps1"
    assert seed["default_output_dir"] == "build/source-tag-readiness"
    assert seed["policy"]["read_only"] is True
    assert seed["policy"]["no_tag_creation"] is True
    assert seed["policy"]["no_git_push"] is True
    assert seed["policy"]["no_github_release_publish"] is True
    assert seed["policy"]["nonzero_when_blocked"] is True
    assert seed["policy"]["requires_open_blocker_evidence_fields"] is True
    assert seed["inputs"]["blocker_inventory"] == (
        "config/release-blocker-inventory.seed.json"
    )
    assert seed["inputs"]["source_readiness"] == (
        "config/source-release-readiness.seed.json"
    )


def test_source_tag_readiness_script_is_local_only() -> None:
    script = _read("scripts/check-source-tag-readiness.ps1")

    for phrase in (
        "release-blocker-inventory.seed.json",
        "source-release-readiness.seed.json",
        "ready_for_tag = $false",
        "open_blocker_count",
        "build\\source-tag-readiness",
        "exit 2",
    ):
        assert phrase in script

    for forbidden in (
        "git tag",
        "git push",
        "gh release create",
        "gh release upload",
        "-X POST",
        "-X PATCH",
        "-X PUT",
        "-X DELETE",
    ):
        assert forbidden not in script


def test_source_tag_readiness_reports_current_blockers(tmp_path: Path) -> None:
    out_dir = tmp_path / "tag-readiness"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
            "-Tag",
            "v0.71.0-source",
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 2
    assert "Source tag readiness: NOT READY" in result.stdout
    assert "merge_stacked_pr_sequence" in result.stdout

    summary = json.loads(
        (out_dir / "v0.71.0-source-tag-readiness.json").read_text(
            encoding="utf-8-sig"
        )
    )
    assert summary["tag"] == "v0.71.0-source"
    assert summary["ready_for_tag"] is False
    assert summary["source_only"] is True
    assert summary["ships_apk"] is False
    assert summary["ships_exe"] is False
    assert summary["store_release"] is False
    assert summary["trusted_signing_claim"] is False
    assert summary["tag_creation_allowed"] is False
    assert summary["latest_candidate"] == "v0.71.0-source"
    assert summary["open_blocker_count"] >= 7
    assert "merge_stacked_pr_sequence" in {
        blocker["id"] for blocker in summary["open_blockers"]
    }
    for blocker in summary["open_blockers"]:
        assert blocker["required_before_tag"] is True
        assert blocker["evidence"]


def test_source_tag_readiness_is_documented_and_validated() -> None:
    docs = "\n".join(
        [
            _read("docs/RELEASE_BLOCKERS.md"),
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("scripts/README.md"),
        ]
    )
    validator = _read("scripts/validate-seed.ps1")
    changelog = _read("CHANGELOG.md")

    assert "check-source-tag-readiness.ps1" in docs
    assert "source tag readiness" in docs
    assert "config\\\\source-tag-readiness.seed.json" in validator
    assert "scripts\\\\check-source-tag-readiness.ps1" in validator
    assert "source tag readiness command" in changelog.lower()
