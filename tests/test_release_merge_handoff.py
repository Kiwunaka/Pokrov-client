from __future__ import annotations

import json
import hashlib
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


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


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
        "generated_at": "2026-06-15T00:00:01Z",
        "read_only": True,
        "merge_order_ok": ok,
        "linear_base_to_head_chain": ok,
        "stack_count": 34,
        "latest_pr": 94,
        "latest_candidate": "v0.74.0-source",
        "errors": [] if ok else ["PR #94 base must equal previous head"],
    }


def _github_status_summary(ok: bool = True) -> dict:
    return {
        "schema_version": 1,
        "generated_at": "2026-06-15T00:00:02Z",
        "read_only": True,
        "github_status_ok": ok,
        "stack_count": 34,
        "latest_pr": 94,
        "latest_candidate": "v0.74.0-source",
        "clean_pr_count": 28 if ok else 27,
        "draft_pr_count": 0,
        "unclean_pr_count": 0 if ok else 1,
        "successful_check_count": 102 if ok else 101,
        "failed_check_count": 0 if ok else 1,
        "errors": [] if ok else ["PR #94 check 'Flutter analyze and tests' is FAILURE"],
    }


def _tag_readiness_summary(ready: bool = False) -> dict:
    open_blockers = (
        []
        if ready
        else [
            {
                "id": "merge_stacked_pr_sequence",
                "status": "pending_maintainer_review",
                "required_before_tag": True,
                "evidence": "All stacked PRs are merged in order.",
            }
        ]
    )
    return {
        "schema_version": 1,
        "generated_at": "2026-06-15T00:00:03Z",
        "read_only": True,
        "tag": "v0.74.0-source",
        "ready_for_tag": ready,
        "source_only": True,
        "ships_apk": False,
        "ships_exe": False,
        "store_release": False,
        "trusted_signing_claim": False,
        "tag_creation_allowed": ready,
        "latest_candidate": "v0.74.0-source",
        "latest_stacked_pr": 94,
        "open_blocker_count": len(open_blockers),
        "open_blockers": open_blockers,
    }


def _publication_dry_run_summary(ok: bool = True) -> dict:
    return {
        "schema_version": 1,
        "generated_at": "2026-06-15T00:00:04Z",
        "read_only": True,
        "tag": "v0.74.0-source",
        "source_only": True,
        "dry_run_only": True,
        "ready_for_manual_review": ok,
        "publish_performed": False,
        "tag_push_performed": False,
        "no_apk": True,
        "no_exe": True,
        "no_store_release": True,
        "no_trusted_signing_claim": True,
        "windows_bundle_verifier_ok": ok,
        "windows_bundle_verifier_summary": (
            "build/windows-bundle-verifier/windows-bundle-verifier.json" if ok else ""
        ),
        "errors": [] if ok else ["Windows bundle verifier proof is missing"],
    }


def _stale_tag_readiness_summary() -> dict:
    summary = _tag_readiness_summary()
    summary["tag"] = "v0.57.0-source"
    summary["latest_candidate"] = "v0.57.0-source"
    return summary


def _write_input_summaries(
    tmp_path: Path,
    *,
    merge_ok: bool = True,
    github_ok: bool = True,
    tag_ready: bool = False,
    publication_ok: bool = True,
    canonical_roots: bool = True,
) -> tuple[Path, Path, Path, Path]:
    if canonical_roots:
        suffix = tmp_path.name
        merge_path = (
            ROOT
            / "build"
            / "release-merge-order"
            / "test-inputs"
            / suffix
            / "release-merge-order.json"
        )
        github_path = (
            ROOT
            / "build"
            / "release-stack-github-status"
            / "test-inputs"
            / suffix
            / "release-stack-github-status.json"
        )
        tag_path = (
            ROOT
            / "build"
            / "source-tag-readiness"
            / "test-inputs"
            / suffix
            / "v0.74.0-source-tag-readiness.json"
        )
        publication_path = (
            ROOT
            / "build"
            / "source-release-publication"
            / "test-inputs"
            / suffix
            / "v0.74.0-source-publication-dry-run.json"
        )
    else:
        merge_path = tmp_path / "release-merge-order.json"
        github_path = tmp_path / "release-stack-github-status.json"
        tag_path = tmp_path / "v0.74.0-source-tag-readiness.json"
        publication_path = tmp_path / "v0.74.0-source-publication-dry-run.json"
    for path in (merge_path, github_path, tag_path, publication_path):
        path.parent.mkdir(parents=True, exist_ok=True)
    _write_json(merge_path, _merge_order_summary(merge_ok))
    _write_json(github_path, _github_status_summary(github_ok))
    _write_json(tag_path, _tag_readiness_summary(tag_ready))
    _write_json(publication_path, _publication_dry_run_summary(publication_ok))
    return merge_path, github_path, tag_path, publication_path


def test_release_merge_handoff_seed_defines_read_only_inputs() -> None:
    seed = _read_json("config/release-merge-handoff.seed.json")
    latest_candidate = _read_json("config/release-blocker-inventory.seed.json")[
        "tracked_candidates"
    ]["latest_candidate"]

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
    assert seed["policy"]["requires_publication_dry_run_summary"] is True
    assert seed["policy"]["requires_input_fingerprints"] is True
    assert seed["policy"]["requires_source_only_summary_flags"] is True
    assert seed["policy"]["requires_canonical_build_input_roots"] is True
    assert seed["policy"]["requires_input_generated_at"] is True
    assert seed["policy"]["requires_input_schema_versions"] is True
    assert seed["policy"]["requires_read_only_input_summaries"] is True
    assert seed["policy"]["requires_input_stack_count_consistency"] is True
    assert seed["policy"]["requires_error_free_input_summaries"] is True
    assert (
        seed["policy"]["requires_tag_readiness_blocker_count_consistency"] is True
    )
    assert seed["policy"]["requires_tag_readiness_blocker_entry_shape"] is True
    assert seed["policy"]["requires_tag_readiness_ready_flags_consistency"] is True
    assert (
        seed["policy"]["requires_tag_readiness_blocker_absence_consistency"] is True
    )
    assert (
        seed["policy"]["requires_tag_readiness_blocker_evidence_fields"] is True
    )
    assert seed["policy"]["requires_tag_readiness_latest_pr_consistency"] is True
    assert (
        seed["policy"]["requires_blocker_inventory_latest_candidate_consistency"]
        is True
    )
    assert seed["policy"]["requires_blocker_inventory_latest_pr_consistency"] is True
    assert seed["inputs"]["merge_order"] == "build/release-merge-order/release-merge-order.json"
    assert seed["inputs"]["github_status"] == (
        "build/release-stack-github-status/release-stack-github-status.json"
    )
    assert seed["inputs"]["tag_readiness"].endswith("-tag-readiness.json")
    assert seed["inputs"]["publication_dry_run"].endswith("-publication-dry-run.json")
    assert latest_candidate in seed["inputs"]["tag_readiness"]
    assert latest_candidate in seed["inputs"]["publication_dry_run"]
    assert seed["input_roots"] == {
        "merge_order": "build/release-merge-order",
        "github_status": "build/release-stack-github-status",
        "tag_readiness": "build/source-tag-readiness",
        "publication_dry_run": "build/source-release-publication",
    }


def test_release_merge_handoff_seed_rejects_stale_default_candidate_paths() -> None:
    handoff_seed_path = ROOT / "config" / "release-merge-handoff.seed.json"
    snapshots = _snapshot_files([handoff_seed_path])

    try:
        seed = json.loads(handoff_seed_path.read_text(encoding="utf-8"))
        seed["inputs"]["tag_readiness"] = (
            "build/source-tag-readiness/v0.69.0-source-tag-readiness.json"
        )
        seed["inputs"]["publication_dry_run"] = (
            "build/source-release-publication/v0.69.0-source/"
            "v0.69.0-source-publication-dry-run.json"
        )
        _write_json(handoff_seed_path, seed)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "validate-seed.ps1"),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode != 0
    output = result.stdout + result.stderr
    assert "release-merge-handoff.seed.json inputs must track latest_candidate" in output


def test_release_merge_handoff_script_is_read_only() -> None:
    script = _read("scripts/prepare-release-merge-handoff.ps1")

    for phrase in (
        "release-merge-handoff.seed.json",
        "merge_order_ok",
        "github_status_ok",
        "publication_dry_run_ok",
        "ready_for_tag",
        "ready_for_manual_review",
        "windows_bundle_verifier_ok",
        "input_fingerprints",
        "source_only = $true",
        "no_apk = $true",
        "no_exe = $true",
        "no_store_release = $true",
        "no_trusted_signing_claim = $true",
        "Assert-BuildInputPath",
        "Assert-InputGeneratedAt",
        "Assert-InputSchemaVersion",
        "Assert-InputReadOnly",
        "input_schema_versions",
        "input_stack_counts",
        "input_error_count",
        "input_generated_at",
        "tag readiness open blockers are missing evidence fields",
        "tag readiness denies tag creation without blockers",
        "tag readiness latest stacked PR mismatch",
        "release-blocker-inventory.seed.json",
        "release handoff latest candidate does not match blocker inventory",
        "release handoff latest PR does not match blocker inventory",
        "SHA256",
        "ComputeHash",
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
        "Get-FileHash",
        "-X POST",
        "-X PATCH",
        "-X PUT",
        "-X DELETE",
    ):
        assert forbidden not in script


def test_release_merge_handoff_writes_handoff_summary(tmp_path: Path) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    assert summary["latest_candidate"] == "v0.74.0-source"
    assert summary["latest_pr"] == 94
    assert summary["blocker_inventory_latest_candidate"] == "v0.74.0-source"
    assert summary["blocker_inventory_latest_pr"] == 94
    assert summary["source_only"] is True
    assert summary["no_apk"] is True
    assert summary["no_exe"] is True
    assert summary["no_store_release"] is True
    assert summary["no_trusted_signing_claim"] is True
    assert summary["publication_dry_run_ok"] is True
    assert summary["publication_ready_for_manual_review"] is True
    assert summary["windows_bundle_verifier_ok"] is True
    assert summary["windows_bundle_verifier_summary"].endswith(
        "windows-bundle-verifier.json"
    )
    assert summary["input_fingerprints"]["merge_order"]["sha256"] == _sha256(
        merge_path
    )
    assert summary["input_fingerprints"]["blocker_inventory"]["sha256"] == _sha256(
        ROOT / "config" / "release-blocker-inventory.seed.json"
    )
    assert summary["input_fingerprints"]["github_status"]["sha256"] == _sha256(
        github_path
    )
    assert summary["input_fingerprints"]["tag_readiness"]["sha256"] == _sha256(
        tag_path
    )
    assert summary["input_fingerprints"]["publication_dry_run"][
        "sha256"
    ] == _sha256(publication_path)
    assert summary["input_fingerprints"]["publication_dry_run"]["path"].endswith(
        "v0.74.0-source-publication-dry-run.json"
    )
    assert summary["input_generated_at"] == {
        "merge_order": "2026-06-15T00:00:01Z",
        "github_status": "2026-06-15T00:00:02Z",
        "tag_readiness": "2026-06-15T00:00:03Z",
        "publication_dry_run": "2026-06-15T00:00:04Z",
    }
    assert summary["input_schema_versions"] == {
        "merge_order": 1,
        "github_status": 1,
        "tag_readiness": 1,
        "publication_dry_run": 1,
    }
    assert summary["input_stack_counts"] == {
        "merge_order": 34,
        "github_status": 34,
    }
    assert summary["input_error_count"] == 0
    assert "merge stacked PRs in order" in " ".join(summary["next_manual_steps"])
    assert "publication dry-run" in " ".join(summary["next_manual_steps"])
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
        / "v0.74.0-source-tag-readiness.json"
    )
    default_publication_path = (
        ROOT
        / "build"
        / "source-release-publication"
        / "v0.74.0-source"
        / "v0.74.0-source-publication-dry-run.json"
    )
    out_dir = ROOT / "build" / "release-merge-handoff"
    summary_path = out_dir / "release-merge-handoff.json"
    touched_paths = [
        default_merge_path,
        default_github_path,
        default_tag_path,
        default_publication_path,
        summary_path,
    ]
    snapshots = _snapshot_files(touched_paths)
    try:
        default_merge_path.parent.mkdir(parents=True, exist_ok=True)
        default_github_path.parent.mkdir(parents=True, exist_ok=True)
        default_tag_path.parent.mkdir(parents=True, exist_ok=True)
        default_publication_path.parent.mkdir(parents=True, exist_ok=True)
        _write_json(default_merge_path, _merge_order_summary())
        _write_json(default_github_path, _github_status_summary())
        _write_json(default_tag_path, _tag_readiness_summary())
        _write_json(default_publication_path, _publication_dry_run_summary())

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
        assert summary["latest_candidate"] == "v0.74.0-source"
        assert summary["latest_pr"] == 94
        assert summary["blocker_inventory_latest_candidate"] == "v0.74.0-source"
        assert summary["blocker_inventory_latest_pr"] == 94
        assert summary["publication_dry_run_ok"] is True
        assert summary["source_only"] is True
        assert summary["no_apk"] is True
        assert summary["input_fingerprints"]["merge_order"]["sha256"] == _sha256(
            default_merge_path
        )
    finally:
        _restore_files(snapshots)


def test_release_merge_handoff_blocks_failed_inputs(tmp_path: Path) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    suffix = tmp_path.name
    merge_path = (
        ROOT
        / "build"
        / "release-merge-order"
        / "test-inputs"
        / suffix
        / "release-merge-order.json"
    )
    github_path = (
        ROOT
        / "build"
        / "release-stack-github-status"
        / "test-inputs"
        / suffix
        / "release-stack-github-status.json"
    )
    tag_path = (
        ROOT
        / "build"
        / "source-tag-readiness"
        / "test-inputs"
        / suffix
        / "v0.47.0-source-tag-readiness.json"
    )
    publication_path = (
        ROOT
        / "build"
        / "source-release-publication"
        / "test-inputs"
        / suffix
        / "v0.74.0-source-publication-dry-run.json"
    )
    for path in (merge_path, github_path, tag_path, publication_path):
        path.parent.mkdir(parents=True, exist_ok=True)
    _write_json(merge_path, _merge_order_summary())
    _write_json(github_path, _github_status_summary())
    _write_json(tag_path, _stale_tag_readiness_summary())
    _write_json(publication_path, _publication_dry_run_summary())
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
                "-PublicationDryRunPath",
                str(publication_path),
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


def test_release_merge_handoff_blocks_mismatched_stack_counts(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["stack_count"] = 27
    _write_json(github_path, github_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    assert "input summaries do not agree on stack count" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_input_summary_errors(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    merge_summary = json.loads(merge_path.read_text(encoding="utf-8"))
    merge_summary["errors"] = ["PR #94 base was stale when checked"]
    _write_json(merge_path, merge_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    assert summary["input_error_count"] == 1
    assert summary["input_errors"] == ["PR #94 base was stale when checked"]
    assert "input summaries report errors" in summary["blocking_errors"]


def test_release_merge_handoff_blocks_tag_readiness_input_errors(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    tag_summary = json.loads(tag_path.read_text(encoding="utf-8"))
    tag_summary["errors"] = ["tag readiness blocker inventory was stale"]
    _write_json(tag_path, tag_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    assert summary["input_error_count"] == 1
    assert summary["input_errors"] == ["tag readiness blocker inventory was stale"]
    assert "input summaries report errors" in summary["blocking_errors"]


def test_release_merge_handoff_blocks_tag_readiness_blocker_count_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path,
        tag_ready=True,
    )
    tag_summary = json.loads(tag_path.read_text(encoding="utf-8"))
    tag_summary["open_blocker_count"] = 0
    tag_summary["open_blockers"] = [
        {"id": "merge_stacked_pr_sequence", "status": "pending_maintainer_review"}
    ]
    _write_json(tag_path, tag_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    assert "tag readiness open blocker count mismatch" in summary["blocking_errors"]


def test_release_merge_handoff_blocks_malformed_tag_readiness_blockers(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path,
        tag_ready=True,
    )
    tag_summary = json.loads(tag_path.read_text(encoding="utf-8"))
    tag_summary["open_blocker_count"] = 1
    tag_summary["open_blockers"] = [
        {"id": "", "status": "pending_maintainer_review"}
    ]
    _write_json(tag_path, tag_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    assert "tag readiness open blockers have invalid entries" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_tag_readiness_blockers_without_evidence(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path,
        tag_ready=True,
    )
    tag_summary = json.loads(tag_path.read_text(encoding="utf-8"))
    tag_summary["open_blocker_count"] = 1
    tag_summary["open_blockers"] = [
        {
            "id": "merge_stacked_pr_sequence",
            "status": "pending_maintainer_review",
            "required_before_tag": True,
            "evidence": "",
        }
    ]
    _write_json(tag_path, tag_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    assert "tag readiness open blockers are missing evidence fields" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_ready_tag_readiness_with_open_blockers(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    tag_summary = json.loads(tag_path.read_text(encoding="utf-8"))
    tag_summary["ready_for_tag"] = True
    tag_summary["tag_creation_allowed"] = True
    _write_json(tag_path, tag_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    assert "tag readiness allows tag creation while blockers remain" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_denied_tag_readiness_without_open_blockers(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path,
        tag_ready=True,
    )
    tag_summary = json.loads(tag_path.read_text(encoding="utf-8"))
    tag_summary["ready_for_tag"] = False
    tag_summary["tag_creation_allowed"] = False
    _write_json(tag_path, tag_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    assert "tag readiness denies tag creation without blockers" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_tag_readiness_latest_pr_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    tag_summary = json.loads(tag_path.read_text(encoding="utf-8"))
    tag_summary["latest_stacked_pr"] = 88
    _write_json(tag_path, tag_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    assert "tag readiness latest stacked PR mismatch" in summary["blocking_errors"]


def test_release_merge_handoff_blocks_blocker_inventory_candidate_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    snapshots = _snapshot_files([inventory_path])
    out_dir = ROOT / "build" / "release-merge-handoff" / "test-output"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["tracked_candidates"]["latest_candidate"] = "v0.75.0-source"
        inventory["tracked_candidates"]["latest_stacked_pr"] = 95
        _write_json(inventory_path, inventory)

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
                "-PublicationDryRunPath",
                str(publication_path),
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
        _restore_files(snapshots)
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert summary["handoff_ready_for_maintainer"] is False
    assert (
        "release handoff latest candidate does not match blocker inventory"
        in summary["blocking_errors"]
    )
    assert (
        "release handoff latest PR does not match blocker inventory"
        in summary["blocking_errors"]
    )


def test_release_merge_handoff_blocks_failed_publication_dry_run(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path,
        publication_ok=False,
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
                "-PublicationDryRunPath",
                str(publication_path),
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
    assert "publication dry-run is not ready for manual review" in summary[
        "blocking_errors"
    ]
    assert "publication dry-run missing Windows bundle verifier proof" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_rejects_non_build_output(tmp_path: Path) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
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
            "-PublicationDryRunPath",
            str(publication_path),
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


def test_release_merge_handoff_rejects_non_canonical_input_roots(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path,
        canonical_roots=False,
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
                "-PublicationDryRunPath",
                str(publication_path),
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode != 0
    assert not (out_dir / "release-merge-handoff.json").exists()
    assert "Release merge handoff input 'merge_order'" in (
        result.stderr + result.stdout
    )
    assert "build\\release-merge-order" in (result.stderr + result.stdout)


def test_release_merge_handoff_rejects_inputs_without_generated_at(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    merge_summary = json.loads(merge_path.read_text(encoding="utf-8"))
    merge_summary.pop("generated_at")
    _write_json(merge_path, merge_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode != 0
    assert not (out_dir / "release-merge-handoff.json").exists()
    assert "Release merge handoff input 'merge_order' must include generated_at" in (
        result.stderr + result.stdout
    )


def test_release_merge_handoff_rejects_bad_input_schema_version(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["schema_version"] = 2
    _write_json(github_path, github_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode != 0
    assert not (out_dir / "release-merge-handoff.json").exists()
    assert "Release merge handoff input 'github_status' must use schema_version 1" in (
        result.stderr + result.stdout
    )


def test_release_merge_handoff_rejects_non_read_only_input_summary(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    tag_summary = json.loads(tag_path.read_text(encoding="utf-8"))
    tag_summary["read_only"] = False
    _write_json(tag_path, tag_summary)
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
                "-PublicationDryRunPath",
                str(publication_path),
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode != 0
    assert not (out_dir / "release-merge-handoff.json").exists()
    assert "Release merge handoff input 'tag_readiness' must be read-only" in (
        result.stderr + result.stdout
    )


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
