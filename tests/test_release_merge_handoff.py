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


def _write_json(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload), encoding="utf-8")


def _snapshot_files(paths: list[Path]) -> dict[Path, bytes | None]:
    snapshots: dict[Path, bytes | None] = {}
    for path in paths:
        snapshots[path] = path.read_bytes() if path.exists() else None
    return snapshots


def _restore_files(snapshots: dict[Path, bytes | None]) -> None:
    for path, content in snapshots.items():
        if content is None:
            path.unlink(missing_ok=True)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)


def _merge_order_summary(ok: bool = True) -> dict:
    return {
        "schema_version": 1,
        "read_only": True,
        "merge_order_ok": ok,
        "linear_base_to_head_chain": ok,
        "stack_count": 12,
        "latest_pr": 72,
        "latest_candidate": "v0.52.0-source",
        "errors": [] if ok else ["PR #72 base must equal previous head"],
    }


def _github_status_summary(ok: bool = True) -> dict:
    return {
        "schema_version": 1,
        "read_only": True,
        "github_status_ok": ok,
        "stack_count": 12,
        "latest_pr": 72,
        "latest_candidate": "v0.52.0-source",
        "clean_pr_count": 12 if ok else 11,
        "draft_pr_count": 0,
        "unclean_pr_count": 0 if ok else 1,
        "successful_check_count": 36 if ok else 35,
        "failed_check_count": 0 if ok else 1,
        "errors": [] if ok else ["PR #72 check 'Flutter analyze and tests' is FAILURE"],
    }


def _tag_readiness_summary(ready: bool = False) -> dict:
    return {
        "schema_version": 1,
        "read_only": True,
        "tag": "v0.52.0-source",
        "ready_for_tag": ready,
        "source_only": True,
        "ships_apk": False,
        "ships_exe": False,
        "store_release": False,
        "trusted_signing_claim": False,
        "tag_creation_allowed": ready,
        "latest_candidate": "v0.52.0-source",
        "open_blocker_count": 0 if ready else 7,
        "open_blockers": []
        if ready
        else [{"id": "merge_stacked_pr_sequence", "status": "pending_maintainer_review"}],
    }


def _stale_tag_readiness_summary() -> dict:
    summary = _tag_readiness_summary()
    summary["tag"] = "v0.51.0-source"
    summary["latest_candidate"] = "v0.51.0-source"
    return summary


def _write_input_summaries(
    tmp_path: Path,
    *,
    merge_ok: bool = True,
    github_ok: bool = True,
    tag_ready: bool = False,
) -> tuple[Path, Path, Path]:
    merge_path = tmp_path / "release-merge-order.json"
    github_path = tmp_path / "release-stack-github-status.json"
    tag_path = tmp_path / "v0.52.0-source-tag-readiness.json"
    _write_json(merge_path, _merge_order_summary(merge_ok))
    _write_json(github_path, _github_status_summary(github_ok))
    _write_json(tag_path, _tag_readiness_summary(tag_ready))
    return merge_path, github_path, tag_path


def test_release_merge_handoff_seed_defines_read_only_inputs() -> None:
    seed = _read_json("config/release-merge-handoff.seed.json")

    assert seed["script"] == "scripts/prepare-release-merge-handoff.ps1"
    assert seed["default_output_dir"] == "build/release-merge-handoff"
    assert seed["policy"]["read_only"] is True
    assert seed["policy"]["no_merge"] is True
    assert seed["policy"]["no_git_push"] is True
    assert seed["policy"]["no_tag_creation"] is True
    assert seed["policy"]["no_github_release_publish"] is True
    assert seed["policy"]["requires_merge_order_summary"] is True
    assert seed["policy"]["requires_github_status_summary"] is True
    assert seed["policy"]["requires_tag_readiness_summary"] is True
    assert seed["inputs"]["merge_order"] == "build/release-merge-order/release-merge-order.json"
    assert seed["inputs"]["github_status"] == (
        "build/release-stack-github-status/release-stack-github-status.json"
    )
    assert seed["inputs"]["tag_readiness"].endswith("-tag-readiness.json")


def test_release_merge_handoff_script_is_read_only() -> None:
    script = _read("scripts/prepare-release-merge-handoff.ps1")

    for phrase in (
        "release-merge-handoff.seed.json",
        "merge_order_ok",
        "github_status_ok",
        "ready_for_tag",
        "handoff_ready_for_maintainer",
        "build\\release-merge-handoff",
        "manual_merge_required = $true",
    ):
        assert phrase in script

    for forbidden in (
        "git merge",
        "git push",
        "git tag",
        "gh pr merge",
        "gh release create",
        "gh release upload",
        "gh api",
        "-X POST",
        "-X PATCH",
        "-X PUT",
        "-X DELETE",
    ):
        assert forbidden not in script


def test_release_merge_handoff_writes_handoff_summary(tmp_path: Path) -> None:
    merge_path, github_path, tag_path = _write_input_summaries(tmp_path)
    out_dir = ROOT / "build" / "release-merge-handoff" / "test-output"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-release-merge-handoff.ps1"),
                "-MergeOrderPath",
                str(merge_path),
                "-GithubStatusPath",
                str(github_path),
                "-TagReadinessPath",
                str(tag_path),
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "release-merge-handoff.json").read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert summary["handoff_ready_for_maintainer"] is True
    assert summary["ready_for_tag"] is False
    assert summary["manual_merge_required"] is True
    assert summary["manual_tag_required"] is True
    assert summary["publish_performed"] is False
    assert summary["tag_push_performed"] is False
    assert summary["latest_candidate"] == "v0.52.0-source"
    assert summary["latest_pr"] == 72
    assert "merge stacked PRs in order" in " ".join(summary["next_manual_steps"])
    assert summary["blocking_errors"] == []


def test_release_merge_handoff_uses_seed_default_input_paths() -> None:
    default_merge_path = (
        ROOT / "build" / "release-merge-order" / "release-merge-order.json"
    )
    default_github_path = (
        ROOT
        / "build"
        / "release-stack-github-status"
        / "release-stack-github-status.json"
    )
    default_tag_path = (
        ROOT
        / "build"
        / "source-tag-readiness"
        / "v0.52.0-source-tag-readiness.json"
    )
    out_dir = ROOT / "build" / "release-merge-handoff"
    summary_path = out_dir / "release-merge-handoff.json"
    touched_paths = [
        default_merge_path,
        default_github_path,
        default_tag_path,
        summary_path,
    ]
    snapshots = _snapshot_files(touched_paths)
    try:
        default_merge_path.parent.mkdir(parents=True, exist_ok=True)
        default_github_path.parent.mkdir(parents=True, exist_ok=True)
        default_tag_path.parent.mkdir(parents=True, exist_ok=True)
        _write_json(default_merge_path, _merge_order_summary())
        _write_json(default_github_path, _github_status_summary())
        _write_json(default_tag_path, _tag_readiness_summary())

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-release-merge-handoff.ps1"),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0, result.stderr + result.stdout
        summary = json.loads(summary_path.read_text(encoding="utf-8-sig"))
        assert summary["handoff_ready_for_maintainer"] is True
        assert summary["latest_candidate"] == "v0.52.0-source"
        assert summary["latest_pr"] == 72
    finally:
        _restore_files(snapshots)


def test_release_merge_handoff_blocks_failed_inputs(tmp_path: Path) -> None:
    merge_path, github_path, tag_path = _write_input_summaries(
        tmp_path,
        merge_ok=False,
        github_ok=False,
    )
    out_dir = ROOT / "build" / "release-merge-handoff" / "test-output"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-release-merge-handoff.ps1"),
                "-MergeOrderPath",
                str(merge_path),
                "-GithubStatusPath",
                str(github_path),
                "-TagReadinessPath",
                str(tag_path),
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "release-merge-handoff.json").read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert summary["handoff_ready_for_maintainer"] is False
    assert "release merge order is not OK" in summary["blocking_errors"]
    assert "release stack GitHub status is not OK" in summary["blocking_errors"]
    assert "Release merge handoff blocked." in result.stdout


def test_release_merge_handoff_blocks_mismatched_input_candidates(
    tmp_path: Path,
) -> None:
    merge_path = tmp_path / "release-merge-order.json"
    github_path = tmp_path / "release-stack-github-status.json"
    tag_path = tmp_path / "v0.47.0-source-tag-readiness.json"
    _write_json(merge_path, _merge_order_summary())
    _write_json(github_path, _github_status_summary())
    _write_json(tag_path, _stale_tag_readiness_summary())
    out_dir = ROOT / "build" / "release-merge-handoff" / "test-output"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-release-merge-handoff.ps1"),
                "-MergeOrderPath",
                str(merge_path),
                "-GithubStatusPath",
                str(github_path),
                "-TagReadinessPath",
                str(tag_path),
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "release-merge-handoff.json").read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert summary["handoff_ready_for_maintainer"] is False
    assert "input summaries do not agree on latest candidate" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_rejects_non_build_output(tmp_path: Path) -> None:
    merge_path, github_path, tag_path = _write_input_summaries(tmp_path)
    out_dir = tmp_path / "outside-build"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "prepare-release-merge-handoff.ps1"),
            "-MergeOrderPath",
            str(merge_path),
            "-GithubStatusPath",
            str(github_path),
            "-TagReadinessPath",
            str(tag_path),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "release-merge-handoff.json").exists()
    assert "build\\release-merge-handoff" in (result.stderr + result.stdout)


def test_release_merge_handoff_is_documented_and_validated() -> None:
    docs = "\n".join(
        [
            _read("docs/RELEASE_BLOCKERS.md"),
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("scripts/README.md"),
        ]
    )
    validator = _read("scripts/validate-seed.ps1")
    changelog = _read("CHANGELOG.md")

    assert "prepare-release-merge-handoff.ps1" in docs
    assert "release merge handoff" in docs
    assert "config\\\\release-merge-handoff.seed.json" in validator
    assert "scripts\\\\prepare-release-merge-handoff.ps1" in validator
    assert "release merge handoff helper" in changelog.lower()
