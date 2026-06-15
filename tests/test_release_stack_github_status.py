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


def _check_run(name: str, conclusion: str = "SUCCESS") -> dict:
    return {
        "__typename": "CheckRun",
        "name": name,
        "status": "COMPLETED",
        "conclusion": conclusion,
    }


def _snapshot_for_stack(
    *,
    draft_pr: int | None = None,
    dirty_pr: int | None = None,
    failed_check_pr: int | None = None,
) -> list[dict]:
    stack = _read_json("config/release-merge-order.seed.json")["stack"]
    snapshot: list[dict] = []
    for item in stack:
        pr_number = item["pr"]
        snapshot.append(
            {
                "number": pr_number,
                "title": f"PR {pr_number}",
                "baseRefName": item["base"],
                "headRefName": item["head"],
                "isDraft": pr_number == draft_pr,
                "mergeStateStatus": "DIRTY" if pr_number == dirty_pr else "CLEAN",
                "statusCheckRollup": [
                    _check_run(
                        "Source import and public tree checks",
                        "FAILURE" if pr_number == failed_check_pr else "SUCCESS",
                    ),
                    _check_run("Flutter analyze and tests"),
                    _check_run("Android native Gradle unit tests"),
                ],
            }
        )
    return snapshot


def _write_snapshot(path: Path, snapshot: list[dict]) -> None:
    path.write_text(json.dumps(snapshot), encoding="utf-8")


def test_release_stack_github_status_seed_defines_read_only_policy() -> None:
    seed = _read_json("config/release-stack-github-status.seed.json")

    assert seed["script"] == "scripts/check-release-stack-github-status.ps1"
    assert seed["default_output_dir"] == "build/release-stack-github-status"
    assert seed["input_manifest"] == "config/release-merge-order.seed.json"
    assert seed["policy"]["read_only"] is True
    assert seed["policy"]["no_merge"] is True
    assert seed["policy"]["no_git_push"] is True
    assert seed["policy"]["no_github_api_mutation"] is True
    assert seed["policy"]["uses_pr_status_snapshot"] is True
    assert seed["policy"]["requires_clean_prs"] is True
    assert seed["policy"]["requires_ci_success"] is True
    assert seed["required_status_checks"] == [
        "Source import and public tree checks",
        "Flutter analyze and tests",
        "Android native Gradle unit tests",
    ]


def test_release_stack_github_status_script_is_read_only() -> None:
    script = _read("scripts/check-release-stack-github-status.ps1")

    for phrase in (
        "release-stack-github-status.seed.json",
        "release-merge-order.seed.json",
        "gh pr list",
        "mergeStateStatus",
        "statusCheckRollup",
        "build\\release-stack-github-status",
        "github_status_ok = $true",
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


def test_release_stack_github_status_command_accepts_clean_snapshot(
    tmp_path: Path,
) -> None:
    snapshot_path = tmp_path / "prs.clean.json"
    _write_snapshot(snapshot_path, _snapshot_for_stack())
    out_dir = ROOT / "build" / "release-stack-github-status" / "test-output"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-release-stack-github-status.ps1"),
                "-PrStatusPath",
                str(snapshot_path),
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "release-stack-github-status.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert summary["github_status_ok"] is True
    assert summary["read_only"] is True
    assert summary["stack_count"] >= 5
    assert summary["latest_pr"] == 73
    assert summary["clean_pr_count"] == summary["stack_count"]
    assert summary["successful_check_count"] == summary["stack_count"] * 3
    assert summary["errors"] == []


def test_release_stack_github_status_command_rejects_unsafe_snapshot(
    tmp_path: Path,
) -> None:
    snapshot_path = tmp_path / "prs.unsafe.json"
    _write_snapshot(
        snapshot_path,
        _snapshot_for_stack(draft_pr=63, dirty_pr=64, failed_check_pr=65),
    )
    out_dir = ROOT / "build" / "release-stack-github-status" / "test-output"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-release-stack-github-status.ps1"),
                "-PrStatusPath",
                str(snapshot_path),
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "release-stack-github-status.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    output = result.stdout + result.stderr
    assert result.returncode == 2
    assert summary["github_status_ok"] is False
    assert summary["draft_pr_count"] == 1
    assert summary["unclean_pr_count"] == 1
    assert summary["failed_check_count"] == 1
    assert "PR #63 is draft" in output
    assert "PR #64 mergeStateStatus is DIRTY" in output
    assert "PR #65 check 'Source import and public tree checks' is FAILURE" in output


def test_release_stack_github_status_rejects_non_build_output(tmp_path: Path) -> None:
    snapshot_path = tmp_path / "prs.clean.json"
    _write_snapshot(snapshot_path, _snapshot_for_stack())
    out_dir = tmp_path / "outside-build"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "check-release-stack-github-status.ps1"),
            "-PrStatusPath",
            str(snapshot_path),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "release-stack-github-status.json").exists()
    assert "build\\release-stack-github-status" in (result.stderr + result.stdout)


def test_release_stack_github_status_is_documented_and_validated() -> None:
    docs = "\n".join(
        [
            _read("docs/RELEASE_BLOCKERS.md"),
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("scripts/README.md"),
        ]
    )
    validator = _read("scripts/validate-seed.ps1")
    changelog = _read("CHANGELOG.md")

    assert "check-release-stack-github-status.ps1" in docs
    assert "release stack GitHub status" in docs
    assert "config\\\\release-stack-github-status.seed.json" in validator
    assert "scripts\\\\check-release-stack-github-status.ps1" in validator
    assert "release stack github status verifier" in changelog.lower()
