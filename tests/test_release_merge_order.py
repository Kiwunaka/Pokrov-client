from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def test_release_merge_order_seed_defines_read_only_stack() -> None:
    seed = _read_json("config/release-merge-order.seed.json")

    assert seed["script"] == "scripts/check-release-merge-order.ps1"
    assert seed["default_output_dir"] == "build/release-merge-order"
    assert seed["policy"]["read_only"] is True
    assert seed["policy"]["no_merge"] is True
    assert seed["policy"]["no_git_push"] is True
    assert seed["policy"]["no_github_api_mutation"] is True
    assert seed["policy"]["requires_linear_base_to_head_chain"] is True

    stack = seed["stack"]
    assert stack[0]["pr"] == 61
    assert stack[-1]["pr"] == 111
    assert stack[-1]["candidate"] == "v0.90.0-source"
    for previous, current in zip(stack, stack[1:]):
        assert current["base"] == previous["head"]


def test_release_merge_order_script_is_local_only() -> None:
    script = _read("scripts/check-release-merge-order.ps1")

    for phrase in (
        "release-merge-order.seed.json",
        "merge_order_ok = $true",
        "build\\release-merge-order",
        "stack_count",
        "linear_base_to_head_chain",
    ):
        assert phrase in script

    for forbidden in (
        "git merge",
        "git push",
        "gh pr merge",
        "gh api",
        "-X POST",
        "-X PATCH",
        "-X PUT",
        "-X DELETE",
    ):
        assert forbidden not in script


def test_release_merge_order_command_writes_summary() -> None:
    out_dir = ROOT / "build" / "release-merge-order" / "test-output"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-release-merge-order.ps1"),
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "release-merge-order.json").read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert summary["merge_order_ok"] is True
    assert summary["read_only"] is True
    assert summary["stack_count"] >= 5
    assert summary["latest_pr"] == 111
    assert summary["latest_candidate"] == "v0.90.0-source"
    assert summary["linear_base_to_head_chain"] is True
    assert summary["stack"][0]["pr"] == 61
    assert summary["stack"][-1]["pr"] == 111


def test_release_merge_order_rejects_non_build_output(tmp_path: Path) -> None:
    out_dir = tmp_path / "outside-build"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "check-release-merge-order.ps1"),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "release-merge-order.json").exists()
    assert "build\\release-merge-order" in (result.stderr + result.stdout)


def test_release_merge_order_is_documented_and_validated() -> None:
    docs = "\n".join(
        [
            _read("docs/RELEASE_BLOCKERS.md"),
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("scripts/README.md"),
        ]
    )
    validator = _read("scripts/validate-seed.ps1")
    changelog = _read("CHANGELOG.md")

    assert "check-release-merge-order.ps1" in docs
    assert "release merge order" in docs
    assert "config\\\\release-merge-order.seed.json" in validator
    assert "scripts\\\\check-release-merge-order.ps1" in validator
    assert "release merge-order verifier" in changelog.lower()
