from __future__ import annotations

import json
import hashlib
import shutil
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]
REQUIRED_STATUS_CHECKS = [
    "Source import and public tree checks",
    "Flutter analyze and tests",
    "Android native Gradle unit tests",
]
REQUIRED_RULESET_CHECKS = [
    {"name": "ruleset:required_status_checks", "status": "pass"},
    {"name": "branch_protection:required_status_checks", "status": "pass"},
]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def _write_json(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload), encoding="utf-8")


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _fresh_ruleset_checked_at() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _stale_ruleset_checked_at() -> str:
    return (
        datetime.now(timezone.utc) - timedelta(hours=48)
    ).isoformat().replace("+00:00", "Z")


def _fresh_input_generated_at() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _stale_input_generated_at() -> str:
    return (
        datetime.now(timezone.utc) - timedelta(hours=48)
    ).isoformat().replace("+00:00", "Z")


def _future_input_generated_at() -> str:
    return (
        datetime.now(timezone.utc) + timedelta(minutes=30)
    ).isoformat().replace("+00:00", "Z")


def _with_ruleset_checked_at(payload: dict[str, object]) -> dict[str, object]:
    enriched = dict(payload)
    enriched.setdefault("checked_at", _fresh_ruleset_checked_at())
    return enriched


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
    stack = [
        {
            "pr": pr_number,
            "candidate": f"v0.{pr_number - 21}.0-source",
            "base": f"codex/v0.{pr_number - 22}-source",
            "head": f"codex/v0.{pr_number - 21}-source",
        }
        for pr_number in range(62, 184)
    ]
    return {
        "schema_version": 1,
        "generated_at": _fresh_input_generated_at(),
        "read_only": True,
        "merge_order_ok": ok,
        "linear_base_to_head_chain": ok,
        "stack_count": 122,
        "latest_pr": 183,
        "latest_candidate": "v0.162.0-source",
        "errors": [] if ok else ["PR #159 base must equal previous head"],
        "stack": stack,
    }


def _github_status_pr_checks() -> list[dict]:
    return [
        {
            "name": "Source import and public tree checks",
            "status": "COMPLETED",
            "conclusion": "SUCCESS",
            "details_url": (
                "https://github.com/Kiwunaka/Pokrov-client/actions/runs/123/"
                "jobs/source-import-and-public-tree-checks"
            ),
            "workflow_name": "CI",
        },
        {
            "name": "Flutter analyze and tests",
            "status": "COMPLETED",
            "conclusion": "SUCCESS",
            "details_url": (
                "https://github.com/Kiwunaka/Pokrov-client/actions/runs/123/"
                "jobs/flutter-analyze-and-tests"
            ),
            "workflow_name": "CI",
        },
        {
            "name": "Android native Gradle unit tests",
            "status": "COMPLETED",
            "conclusion": "SUCCESS",
            "details_url": (
                "https://github.com/Kiwunaka/Pokrov-client/actions/runs/123/"
                "jobs/android-native-gradle-unit-tests"
            ),
            "workflow_name": "CI",
        },
    ]


def _github_status_summary(ok: bool = True) -> dict:
    pull_requests = [
        {
            "pr": pr_number,
            "url": f"https://github.com/Kiwunaka/Pokrov-client/pull/{pr_number}",
            "base": f"codex/v0.{pr_number - 22}-source",
            "head": f"codex/v0.{pr_number - 21}-source",
            "mergeStateStatus": "CLEAN",
            "isDraft": False,
            "successful_check_count": 3,
            "failed_check_count": 0,
            "required_status_check_count": 3,
            "checks": _github_status_pr_checks(),
            "errors": [],
        }
        for pr_number in range(62, 184)
    ]
    return {
        "schema_version": 1,
        "generated_at": _fresh_input_generated_at(),
        "read_only": True,
        "github_status_ok": ok,
        "stack_count": 122,
        "latest_pr": 183,
        "latest_pr_url": "https://github.com/Kiwunaka/Pokrov-client/pull/183",
        "expected_pr_url_prefix": "https://github.com/Kiwunaka/Pokrov-client/pull/",
        "latest_candidate": "v0.162.0-source",
        "clean_pr_count": 122 if ok else 62,
        "draft_pr_count": 0,
        "unclean_pr_count": 0 if ok else 1,
        "successful_check_count": 366 if ok else 194,
        "failed_check_count": 0 if ok else 1,
        "pull_requests": pull_requests,
        "errors": [] if ok else ["PR #159 check 'Flutter analyze and tests' is FAILURE"],
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
        "generated_at": _fresh_input_generated_at(),
        "read_only": True,
        "tag": "v0.162.0-source",
        "ready_for_tag": ready,
        "source_only": True,
        "ships_apk": False,
        "ships_exe": False,
        "store_release": False,
        "trusted_signing_claim": False,
        "tag_creation_allowed": ready,
        "latest_candidate": "v0.162.0-source",
        "latest_stacked_pr": 183,
        "input_fingerprints": {
            "blocker_inventory": {
                "path": "config/release-blocker-inventory.seed.json",
                "sha256": "a" * 64,
            },
            "source_readiness": {
                "path": "config/source-release-readiness.seed.json",
                "sha256": "b" * 64,
            },
        },
        "open_blocker_count": len(open_blockers),
        "open_blockers": open_blockers,
    }


def _publication_dry_run_summary(ok: bool = True) -> dict:
    return {
        "schema_version": 1,
        "generated_at": _fresh_input_generated_at(),
        "read_only": True,
        "tag": "v0.162.0-source",
        "commit_sha": "a" * 40,
        "evidence_bundle_preflight_commit_sha": "a" * 40,
        "evidence_bundle_preflight_ref_commit_sha": "a" * 40,
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
        "source_archive": "source.zip",
        "source_archive_sha256": "2" * 64,
        "input_fingerprints": {
            "evidence_bundle": {
                "path": "build/release-evidence/v0.162.0-source/release-evidence.json",
                "sha256": "c" * 64,
            },
            "release_notes": {
                "path": "build/source-release/v0.162.0-source/release-notes.md",
                "sha256": "d" * 64,
            },
        },
        "evidence_bundle_input_fingerprints": {
            "preflight_summary": {
                "path": "build/source-release-preflight/v0.162.0-source/preflight.json",
                "sha256": "e" * 64,
            },
        },
        "evidence_bundle_preflight_artifact_fingerprints": {
            "proof_manifest": {"path": "proof.json", "sha256": "f" * 64},
            "release_notes": {
                "path": "build/source-release/v0.162.0-source/release-notes.md",
                "sha256": "d" * 64,
            },
            "source_archive": {"path": "source.zip", "sha256": "2" * 64},
            "windows_bundle_verifier_summary": {
                "path": "windows-bundle-verifier.json",
                "sha256": "3" * 64,
            },
        },
        "errors": [] if ok else ["Windows bundle verifier proof is missing"],
    }


def _write_preflight_fixture(tmp_path: Path) -> Path:
    preflight = tmp_path / "preflight.json"
    preflight.write_text('{"source_only":true}', encoding="utf-8")
    return preflight


def _write_ruleset_report_fixture(tmp_path: Path) -> Path:
    ruleset = tmp_path / "github-ruleset-report.json"
    ruleset.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "checked_at": _fresh_ruleset_checked_at(),
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
                "required_status_checks": REQUIRED_STATUS_CHECKS,
                "covered_required_status_checks": REQUIRED_STATUS_CHECKS,
                "checks": REQUIRED_RULESET_CHECKS,
            }
        ),
        encoding="utf-8",
    )
    return ruleset


def _attach_preflight_input_fingerprint(summary: dict, preflight: Path) -> dict:
    summary["evidence_bundle_input_fingerprints"]["preflight_summary"] = {
        "path": str(preflight),
        "sha256": _sha256(preflight),
    }
    return summary


def _attach_ruleset_report_input_fingerprint(summary: dict, ruleset: Path) -> dict:
    summary["evidence_bundle_input_fingerprints"]["github_ruleset_report"] = {
        "path": str(ruleset),
        "sha256": _sha256(ruleset),
    }
    return summary


def _write_tag_readiness_input_fixtures(tmp_path: Path) -> tuple[Path, Path]:
    blocker_inventory = tmp_path / "release-blocker-inventory.seed.json"
    blocker_inventory.write_text('{"source_only":true}', encoding="utf-8")
    source_readiness = tmp_path / "source-release-readiness.seed.json"
    source_readiness.write_text('{"milestones":[]}', encoding="utf-8")
    return blocker_inventory, source_readiness


def _attach_tag_readiness_input_fingerprints(
    summary: dict,
    blocker_inventory: Path,
    source_readiness: Path,
) -> dict:
    summary["input_fingerprints"]["blocker_inventory"] = {
        "path": str(blocker_inventory),
        "sha256": _sha256(blocker_inventory),
    }
    summary["input_fingerprints"]["source_readiness"] = {
        "path": str(source_readiness),
        "sha256": _sha256(source_readiness),
    }
    return summary


def _write_publication_input_fixtures(tmp_path: Path) -> tuple[Path, Path]:
    evidence_bundle = tmp_path / "release-evidence.json"
    evidence_bundle.write_text('{"source_only":true}', encoding="utf-8")
    release_notes = tmp_path / "release-notes.md"
    release_notes.write_text("# v0.162.0-source\n", encoding="utf-8")
    return evidence_bundle, release_notes


def _attach_publication_input_fingerprints(
    summary: dict,
    evidence_bundle: Path,
    release_notes: Path,
) -> dict:
    summary["input_fingerprints"]["evidence_bundle"] = {
        "path": str(evidence_bundle),
        "sha256": _sha256(evidence_bundle),
    }
    summary["input_fingerprints"]["release_notes"] = {
        "path": str(release_notes),
        "sha256": _sha256(release_notes),
    }
    summary["evidence_bundle_preflight_artifact_fingerprints"][
        "release_notes"
    ] = {
        "path": str(release_notes),
        "sha256": _sha256(release_notes),
    }
    return summary


def _write_publication_artifact_fixtures(
    tmp_path: Path,
) -> tuple[Path, Path, Path]:
    proof_manifest = tmp_path / "proof.json"
    proof_manifest.write_text('{"source_only":true}', encoding="utf-8")
    source_archive = tmp_path / "source.zip"
    source_archive.write_bytes(b"source archive fixture")
    windows_bundle_verifier = tmp_path / "windows-bundle-verifier.json"
    windows_bundle_verifier.write_text('{"ok":true}', encoding="utf-8")
    return proof_manifest, source_archive, windows_bundle_verifier


def _attach_publication_artifact_fingerprints(
    summary: dict,
    proof_manifest: Path,
    source_archive: Path,
    windows_bundle_verifier: Path,
) -> dict:
    summary["source_archive_sha256"] = _sha256(source_archive)
    summary["windows_bundle_verifier_summary"] = str(windows_bundle_verifier)
    summary["evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ] = {
        "path": str(proof_manifest),
        "sha256": _sha256(proof_manifest),
    }
    summary["evidence_bundle_preflight_artifact_fingerprints"][
        "source_archive"
    ] = {
        "path": str(source_archive),
        "sha256": _sha256(source_archive),
    }
    summary["evidence_bundle_preflight_artifact_fingerprints"][
        "windows_bundle_verifier_summary"
    ] = {
        "path": str(windows_bundle_verifier),
        "sha256": _sha256(windows_bundle_verifier),
    }
    return summary


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
            / "v0.162.0-source-tag-readiness.json"
        )
        publication_path = (
            ROOT
            / "build"
            / "source-release-publication"
            / "test-inputs"
            / suffix
            / "v0.162.0-source-publication-dry-run.json"
        )
    else:
        merge_path = tmp_path / "release-merge-order.json"
        github_path = tmp_path / "release-stack-github-status.json"
        tag_path = tmp_path / "v0.162.0-source-tag-readiness.json"
        publication_path = tmp_path / "v0.162.0-source-publication-dry-run.json"
    for path in (merge_path, github_path, tag_path, publication_path):
        path.parent.mkdir(parents=True, exist_ok=True)
    blocker_inventory, source_readiness = _write_tag_readiness_input_fixtures(tmp_path)
    preflight = _write_preflight_fixture(tmp_path)
    ruleset = _write_ruleset_report_fixture(tmp_path)
    evidence_bundle, release_notes = _write_publication_input_fixtures(tmp_path)
    proof_manifest, source_archive, windows_bundle_verifier = (
        _write_publication_artifact_fixtures(tmp_path)
    )
    tag_summary = _attach_tag_readiness_input_fingerprints(
        _tag_readiness_summary(tag_ready),
        blocker_inventory,
        source_readiness,
    )
    publication_summary = _attach_publication_artifact_fingerprints(
        _attach_publication_input_fingerprints(
            _attach_ruleset_report_input_fingerprint(
                _attach_preflight_input_fingerprint(
                    _publication_dry_run_summary(publication_ok),
                    preflight,
                ),
                ruleset,
            ),
            evidence_bundle,
            release_notes,
        ),
        proof_manifest,
        source_archive,
        windows_bundle_verifier,
    )
    _write_json(merge_path, _merge_order_summary(merge_ok))
    _write_json(github_path, _github_status_summary(github_ok))
    _write_json(tag_path, tag_summary)
    _write_json(publication_path, publication_summary)
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
    assert seed["policy"]["requires_tag_readiness_input_fingerprints"] is True
    assert seed["policy"]["requires_tag_readiness_input_fingerprint_integrity"] is True
    assert seed["policy"]["requires_publication_dry_run_input_fingerprints"] is True
    assert (
        seed["policy"]["requires_publication_dry_run_input_fingerprint_integrity"]
        is True
    )
    assert (
        seed["policy"][
            "requires_publication_dry_run_evidence_bundle_input_fingerprints"
        ]
        is True
    )
    assert (
        seed["policy"][
            "requires_publication_dry_run_preflight_input_fingerprint_integrity"
        ]
        is True
    )
    assert (
        seed["policy"][
            "requires_publication_dry_run_ruleset_report_input_fingerprint_integrity"
        ]
        is True
    )
    assert seed["policy"]["requires_publication_dry_run_ruleset_report_shape"] is True
    assert seed["policy"]["requires_publication_dry_run_ruleset_report_target"] is True
    assert (
        seed["policy"]["requires_publication_dry_run_ruleset_report_ok_consistency"]
        is True
    )
    assert (
        seed["policy"]["requires_publication_dry_run_ruleset_report_checked_at"]
        is True
    )
    assert (
        seed["policy"]["requires_publication_dry_run_ruleset_report_freshness"]
        is True
    )
    assert (
        seed["policy"][
            "requires_publication_dry_run_ruleset_report_check_entry_shape"
        ]
        is True
    )
    assert (
        seed["policy"][
            "requires_publication_dry_run_ruleset_report_required_status_checks"
        ]
        is True
    )
    assert (
        seed["policy"][
            "requires_publication_dry_run_ruleset_report_covered_required_status_checks"
        ]
        is True
    )
    assert (
        seed["policy"][
            "requires_publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"
        ]
        is True
    )
    assert (
        seed["policy"]["requires_publication_dry_run_artifact_fingerprint_integrity"]
        is True
    )
    assert (
        seed["policy"]["requires_publication_dry_run_commit_sha_consistency"]
        is True
    )
    assert (
        seed["policy"]["carries_publication_dry_run_source_archive_name"]
        is True
    )
    assert (
        seed["policy"]["requires_publication_dry_run_ref_commit_sha_consistency"]
        is True
    )
    assert seed["policy"]["requires_latest_pr_url_consistency"] is True
    assert seed["policy"]["requires_expected_repository_pr_url_consistency"] is True
    assert (
        seed["policy"][
            "requires_github_status_expected_pr_url_prefix_consistency"
        ]
        is True
    )
    assert seed["policy"]["requires_github_status_count_consistency"] is True
    assert seed["policy"]["requires_github_status_pull_request_entries"] is True
    assert seed["policy"]["requires_github_status_pr_sequence"] is True
    assert seed["policy"]["requires_github_status_pr_refs"] is True
    assert seed["policy"]["requires_github_status_pr_urls"] is True
    assert seed["policy"]["requires_github_status_pr_states"] is True
    assert seed["policy"]["requires_github_status_pr_checks"] is True
    assert seed["policy"]["requires_github_status_pr_check_trace"] is True
    assert seed["policy"]["requires_source_only_summary_flags"] is True
    assert seed["policy"]["requires_canonical_build_input_roots"] is True
    assert seed["policy"]["requires_input_generated_at"] is True
    assert seed["policy"]["requires_input_generated_at_parseable"] is True
    assert seed["policy"]["requires_input_generated_at_freshness"] is True
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
        "tag_readiness_input_fingerprints",
        "tag readiness input fingerprints mismatch",
        "publication_dry_run_input_fingerprints",
        "publication dry-run input fingerprints mismatch",
        "publication_dry_run_evidence_bundle_input_fingerprints",
        "Assert-InputFingerprintIntegrity",
        "publication dry-run ruleset report input fingerprint mismatch",
        "publication dry-run ruleset report without schema_version 1",
        "publication dry-run ruleset report that is not read-only",
        "publication dry-run ruleset report without ok status",
        "publication dry-run ruleset report without checked_at timestamp",
        "publication dry-run stale ruleset report checked_at timestamp",
        "publication dry-run ruleset report repository mismatch",
        "publication dry-run ruleset report branch mismatch",
        "publication dry-run ruleset report ok status without checks",
        "publication dry-run ruleset report ok status with failed checks",
        "publication dry-run ruleset report check entry shape mismatch",
        "publication dry-run ruleset report required status checks mismatch",
        "publication dry-run ruleset report covered required status checks mismatch",
        "publication_dry_run_evidence_bundle_preflight_artifact_fingerprints",
        "publication_dry_run_source_archive",
        "tag readiness summary is missing input fingerprints",
        "publication dry-run summary is missing input fingerprints",
        "publication dry-run summary is missing evidence bundle input fingerprints",
        "publication dry-run preflight input fingerprint mismatch",
        "publication dry-run summary is missing evidence bundle preflight artifact fingerprints",
        "publication dry-run artifact fingerprints mismatch",
        "publication dry-run commit SHA mismatch",
        "publication dry-run ref commit SHA mismatch",
        "latest_pr_url",
        "release stack GitHub status latest PR URL is missing",
        "release stack GitHub status latest PR URL mismatch",
        "release stack GitHub status latest PR URL repository mismatch",
        "release stack GitHub status expected PR URL prefix mismatch",
        "release stack GitHub status count mismatch",
        "release stack GitHub status pull request entries mismatch",
        "release stack GitHub status PR sequence mismatch",
        "release stack GitHub status PR refs mismatch",
        "release stack GitHub status PR URLs mismatch",
        "release stack GitHub status PR states mismatch",
        "release stack GitHub status PR checks mismatch",
        "release stack GitHub status PR check trace mismatch",
        "expected_pr_url_prefix",
        "github_status_expected_pr_url_prefix",
        "github_status_counts",
        "github_status_pull_request_count",
        "github_status_pr_sequence",
        "github_status_pr_refs",
        "github_status_pr_urls",
        "github_status_pr_states",
        "github_status_pr_checks",
        "details_url",
        "workflow_name",
        "publication_dry_run_evidence_bundle_preflight_commit_sha",
        "publication_dry_run_evidence_bundle_preflight_ref_commit_sha",
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
    assert summary["latest_candidate"] == "v0.162.0-source"
    assert summary["latest_pr"] == 183
    assert summary["latest_pr_url"] == "https://github.com/Kiwunaka/Pokrov-client/pull/183"
    assert summary["expected_pr_url_prefix"] == (
        "https://github.com/Kiwunaka/Pokrov-client/pull/"
    )
    assert summary["github_status_expected_pr_url_prefix"] == (
        "https://github.com/Kiwunaka/Pokrov-client/pull/"
    )
    assert summary["blocker_inventory_latest_candidate"] == "v0.162.0-source"
    assert summary["blocker_inventory_latest_pr"] == 183
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
        "v0.162.0-source-publication-dry-run.json"
    )
    assert summary["tag_readiness_input_fingerprints"]["blocker_inventory"][
        "sha256"
    ] == _sha256(
        Path(
            json.loads(tag_path.read_text(encoding="utf-8"))["input_fingerprints"][
                "blocker_inventory"
            ]["path"]
        )
    )
    assert summary["tag_readiness_input_fingerprints"]["source_readiness"][
        "sha256"
    ] == _sha256(
        Path(
            json.loads(tag_path.read_text(encoding="utf-8"))["input_fingerprints"][
                "source_readiness"
            ]["path"]
        )
    )
    assert summary["publication_dry_run_input_fingerprints"]["evidence_bundle"][
        "sha256"
    ] == _sha256(
        Path(
            json.loads(publication_path.read_text(encoding="utf-8"))[
                "input_fingerprints"
            ]["evidence_bundle"]["path"]
        )
    )
    assert summary["publication_dry_run_input_fingerprints"]["release_notes"][
        "sha256"
    ] == _sha256(
        Path(
            json.loads(publication_path.read_text(encoding="utf-8"))[
                "input_fingerprints"
            ]["release_notes"]["path"]
        )
    )
    assert summary["publication_dry_run_commit_sha"] == "a" * 40
    assert summary["publication_dry_run_source_archive"] == "source.zip"
    assert summary["publication_dry_run_evidence_bundle_preflight_commit_sha"] == "a" * 40
    assert (
        summary["publication_dry_run_evidence_bundle_preflight_ref_commit_sha"]
        == "a" * 40
    )
    assert summary["publication_dry_run_evidence_bundle_input_fingerprints"][
        "preflight_summary"
    ]["sha256"] == _sha256(
        Path(
            json.loads(publication_path.read_text(encoding="utf-8"))[
                "evidence_bundle_input_fingerprints"
            ]["preflight_summary"]["path"]
        )
    )
    assert summary["publication_dry_run_evidence_bundle_input_fingerprints"][
        "github_ruleset_report"
    ]["sha256"] == _sha256(
        Path(
            json.loads(publication_path.read_text(encoding="utf-8"))[
                "evidence_bundle_input_fingerprints"
            ]["github_ruleset_report"]["path"]
        )
    )
    assert summary[
        "publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"
    ]["proof_manifest"]["sha256"] == _sha256(
        Path(
            json.loads(publication_path.read_text(encoding="utf-8"))[
                "evidence_bundle_preflight_artifact_fingerprints"
            ]["proof_manifest"]["path"]
        )
    )
    assert summary[
        "publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"
    ]["windows_bundle_verifier_summary"]["sha256"] == _sha256(
        Path(
            json.loads(publication_path.read_text(encoding="utf-8"))[
                "evidence_bundle_preflight_artifact_fingerprints"
            ]["windows_bundle_verifier_summary"]["path"]
        )
    )
    assert summary["input_generated_at"] == {
        "merge_order": json.loads(merge_path.read_text(encoding="utf-8"))[
            "generated_at"
        ],
        "github_status": json.loads(github_path.read_text(encoding="utf-8"))[
            "generated_at"
        ],
        "tag_readiness": json.loads(tag_path.read_text(encoding="utf-8"))[
            "generated_at"
        ],
        "publication_dry_run": json.loads(
            publication_path.read_text(encoding="utf-8")
        )["generated_at"],
    }
    assert summary["input_schema_versions"] == {
        "merge_order": 1,
        "github_status": 1,
        "tag_readiness": 1,
        "publication_dry_run": 1,
    }
    assert summary["input_stack_counts"] == {
        "merge_order": 122,
        "github_status": 122,
    }
    assert summary["github_status_counts"] == {
        "stack_count": 122,
        "clean_pr_count": 122,
        "draft_pr_count": 0,
        "unclean_pr_count": 0,
        "successful_check_count": 366,
        "failed_check_count": 0,
        "required_status_check_count": 3,
    }
    assert summary["github_status_pull_request_count"] == 122
    assert summary["github_status_pr_sequence"] == list(range(62, 184))
    assert summary["github_status_pr_refs"][0] == {
        "pr": 62,
        "base": "codex/v0.40-source",
        "head": "codex/v0.41-source",
    }
    assert summary["github_status_pr_refs"][-1] == {
        "pr": 183,
        "base": "codex/v0.161-source",
        "head": "codex/v0.162-source",
    }
    assert summary["github_status_pr_urls"][0] == {
        "pr": 62,
        "url": "https://github.com/Kiwunaka/Pokrov-client/pull/62",
    }
    assert summary["github_status_pr_urls"][-1] == {
        "pr": 183,
        "url": "https://github.com/Kiwunaka/Pokrov-client/pull/183",
    }
    assert summary["github_status_pr_states"][0] == {
        "pr": 62,
        "mergeStateStatus": "CLEAN",
        "isDraft": False,
    }
    assert summary["github_status_pr_states"][-1] == {
        "pr": 183,
        "mergeStateStatus": "CLEAN",
        "isDraft": False,
    }
    assert summary["github_status_pr_checks"][0] == {
        "pr": 62,
        "successful_check_count": 3,
        "failed_check_count": 0,
        "required_status_check_count": 3,
        "checks": _github_status_pr_checks(),
    }
    assert summary["github_status_pr_checks"][-1] == {
        "pr": 183,
        "successful_check_count": 3,
        "failed_check_count": 0,
        "required_status_check_count": 3,
        "checks": _github_status_pr_checks(),
    }
    assert summary["input_error_count"] == 0
    assert "merge stacked PRs in order" in " ".join(summary["next_manual_steps"])
    assert "publication dry-run" in " ".join(summary["next_manual_steps"])
    assert summary["blocking_errors"] == []


def test_release_merge_handoff_uses_seed_default_input_paths(tmp_path: Path) -> None:
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
        / "v0.162.0-source"
        / "v0.162.0-source-tag-readiness.json"
    )
    default_publication_path = (
        ROOT
        / "build"
        / "source-release-publication"
        / "v0.162.0-source"
        / "v0.162.0-source-publication-dry-run.json"
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
        blocker_inventory, source_readiness = _write_tag_readiness_input_fixtures(
            tmp_path
        )
        preflight = _write_preflight_fixture(tmp_path)
        _write_json(default_merge_path, _merge_order_summary())
        _write_json(default_github_path, _github_status_summary())
        _write_json(
            default_tag_path,
            _attach_tag_readiness_input_fingerprints(
                _tag_readiness_summary(),
                blocker_inventory,
                source_readiness,
            ),
        )
        evidence_bundle, release_notes = _write_publication_input_fixtures(tmp_path)
        proof_manifest, source_archive, windows_bundle_verifier = (
            _write_publication_artifact_fixtures(tmp_path)
        )
        _write_json(
            default_publication_path,
            _attach_publication_artifact_fingerprints(
                _attach_publication_input_fingerprints(
                    _attach_preflight_input_fingerprint(
                        _publication_dry_run_summary(),
                        preflight,
                    ),
                    evidence_bundle,
                    release_notes,
                ),
                proof_manifest,
                source_archive,
                windows_bundle_verifier,
            ),
        )

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
        assert summary["latest_candidate"] == "v0.162.0-source"
        assert summary["latest_pr"] == 183
        assert summary["blocker_inventory_latest_candidate"] == "v0.162.0-source"
        assert summary["blocker_inventory_latest_pr"] == 183
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
        / "v0.162.0-source-publication-dry-run.json"
    )
    for path in (merge_path, github_path, tag_path, publication_path):
        path.parent.mkdir(parents=True, exist_ok=True)
    preflight = _write_preflight_fixture(tmp_path)
    _write_json(merge_path, _merge_order_summary())
    _write_json(github_path, _github_status_summary())
    _write_json(tag_path, _stale_tag_readiness_summary())
    _write_json(
        publication_path,
        _attach_preflight_input_fingerprint(
            _publication_dry_run_summary(),
            preflight,
        ),
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
    merge_summary["errors"] = ["PR #159 base was stale when checked"]
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
    assert summary["input_errors"] == ["PR #159 base was stale when checked"]
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


def test_release_merge_handoff_blocks_missing_tag_readiness_input_fingerprints(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    tag_summary = json.loads(tag_path.read_text(encoding="utf-8"))
    tag_summary.pop("input_fingerprints")
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
    assert "tag readiness summary is missing input fingerprints" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_stale_tag_readiness_blocker_inventory_input_fingerprint(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    tag_summary = json.loads(tag_path.read_text(encoding="utf-8"))
    tag_summary["input_fingerprints"]["blocker_inventory"]["sha256"] = "0" * 64
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
    assert "tag readiness input fingerprints mismatch" in summary["blocking_errors"]


def test_release_merge_handoff_blocks_stale_tag_readiness_source_readiness_input_fingerprint(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    tag_summary = json.loads(tag_path.read_text(encoding="utf-8"))
    tag_summary["input_fingerprints"]["source_readiness"]["sha256"] = "0" * 64
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
    assert "tag readiness input fingerprints mismatch" in summary["blocking_errors"]


def test_release_merge_handoff_blocks_missing_publication_dry_run_input_fingerprints(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary.pop("input_fingerprints")
    _write_json(publication_path, publication_summary)
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
    assert "publication dry-run summary is missing input fingerprints" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_missing_publication_evidence_bundle_input_fingerprints(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary.pop("evidence_bundle_input_fingerprints")
    _write_json(publication_path, publication_summary)
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
    assert (
        "publication dry-run summary is missing evidence bundle input fingerprints"
        in summary["blocking_errors"]
    )


def test_release_merge_handoff_blocks_stale_publication_preflight_input_fingerprint(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary["evidence_bundle_input_fingerprints"]["preflight_summary"][
        "sha256"
    ] = "0" * 64
    _write_json(publication_path, publication_summary)
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
    assert "publication dry-run preflight input fingerprint mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_stale_publication_ruleset_report_input_fingerprint(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary["evidence_bundle_input_fingerprints"]["github_ruleset_report"][
        "sha256"
    ] = "0" * 64
    _write_json(publication_path, publication_summary)
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
    assert "publication dry-run ruleset report input fingerprint mismatch" in summary[
        "blocking_errors"
    ]


@pytest.mark.parametrize(
    ("ruleset_payload", "expected_error"),
    [
        ({"ok": True}, "publication dry-run ruleset report without schema_version 1"),
        (
            {"schema_version": 1, "ok": True, "read_only": False},
            "publication dry-run ruleset report that is not read-only",
        ),
        (
            {"schema_version": 1, "read_only": True},
            "publication dry-run ruleset report without ok status",
        ),
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
                "required_status_checks": REQUIRED_STATUS_CHECKS,
            },
            "publication dry-run ruleset report without checked_at timestamp",
        ),
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "checked_at": _stale_ruleset_checked_at(),
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
                "required_status_checks": REQUIRED_STATUS_CHECKS,
            },
            "publication dry-run stale ruleset report checked_at timestamp",
        ),
    ],
)
def test_release_merge_handoff_blocks_malformed_publication_ruleset_report(
    tmp_path: Path,
    ruleset_payload: dict[str, object],
    expected_error: str,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    ruleset_path = Path(
        publication_summary["evidence_bundle_input_fingerprints"][
            "github_ruleset_report"
        ]["path"]
    )
    ruleset_path.write_text(json.dumps(ruleset_payload), encoding="utf-8")
    publication_summary["evidence_bundle_input_fingerprints"]["github_ruleset_report"][
        "sha256"
    ] = _sha256(ruleset_path)
    _write_json(publication_path, publication_summary)
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
    assert expected_error in summary["blocking_errors"]


@pytest.mark.parametrize(
    ("ruleset_payload", "expected_error"),
    [
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "checked_at": _fresh_ruleset_checked_at(),
                "repository": "example/fork",
                "branch": "main",
            },
            "publication dry-run ruleset report repository mismatch",
        ),
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "checked_at": _fresh_ruleset_checked_at(),
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "release",
            },
            "publication dry-run ruleset report branch mismatch",
        ),
    ],
)
def test_release_merge_handoff_blocks_wrong_publication_ruleset_report_target(
    tmp_path: Path,
    ruleset_payload: dict[str, object],
    expected_error: str,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    ruleset_path = Path(
        publication_summary["evidence_bundle_input_fingerprints"][
            "github_ruleset_report"
        ]["path"]
    )
    ruleset_path.write_text(json.dumps(ruleset_payload), encoding="utf-8")
    publication_summary["evidence_bundle_input_fingerprints"]["github_ruleset_report"][
        "sha256"
    ] = _sha256(ruleset_path)
    _write_json(publication_path, publication_summary)
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
    assert expected_error in summary["blocking_errors"]


@pytest.mark.parametrize(
    ("ruleset_payload", "expected_error"),
    [
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "checked_at": _fresh_ruleset_checked_at(),
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
                "required_status_checks": REQUIRED_STATUS_CHECKS,
                "covered_required_status_checks": REQUIRED_STATUS_CHECKS,
            },
            "publication dry-run ruleset report ok status without checks",
        ),
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "checked_at": _fresh_ruleset_checked_at(),
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
                "required_status_checks": REQUIRED_STATUS_CHECKS,
                "covered_required_status_checks": REQUIRED_STATUS_CHECKS,
                "checks": [{"status": "pass"}],
            },
            "publication dry-run ruleset report check entry shape mismatch",
        ),
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "checked_at": _fresh_ruleset_checked_at(),
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
                "required_status_checks": REQUIRED_STATUS_CHECKS,
                "covered_required_status_checks": REQUIRED_STATUS_CHECKS,
                "checks": [{"name": "ruleset:active", "status": "fail"}],
            },
            "publication dry-run ruleset report ok status with failed checks",
        ),
    ],
)
def test_release_merge_handoff_blocks_inconsistent_publication_ruleset_report_ok_status(
    tmp_path: Path,
    ruleset_payload: dict[str, object],
    expected_error: str,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    ruleset_path = Path(
        publication_summary["evidence_bundle_input_fingerprints"][
            "github_ruleset_report"
        ]["path"]
    )
    ruleset_path.write_text(json.dumps(ruleset_payload), encoding="utf-8")
    publication_summary["evidence_bundle_input_fingerprints"]["github_ruleset_report"][
        "sha256"
    ] = _sha256(ruleset_path)
    _write_json(publication_path, publication_summary)
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
    assert expected_error in summary["blocking_errors"]


@pytest.mark.parametrize(
    "required_status_checks",
    [
        [],
        ["Source import and public tree checks"],
        [
            "Source import and public tree checks",
            "Android native Gradle unit tests",
            "Flutter analyze and tests",
        ],
    ],
)
def test_release_merge_handoff_blocks_publication_ruleset_report_required_status_check_mismatch(
    tmp_path: Path,
    required_status_checks: list[str],
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    ruleset_path = Path(
        publication_summary["evidence_bundle_input_fingerprints"][
            "github_ruleset_report"
        ]["path"]
    )
    ruleset_path.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "checked_at": _fresh_ruleset_checked_at(),
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
                "required_status_checks": required_status_checks,
                "covered_required_status_checks": REQUIRED_STATUS_CHECKS,
                "checks": REQUIRED_RULESET_CHECKS,
            }
        ),
        encoding="utf-8",
    )
    publication_summary["evidence_bundle_input_fingerprints"]["github_ruleset_report"][
        "sha256"
    ] = _sha256(ruleset_path)
    _write_json(publication_path, publication_summary)
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
    assert (
        "publication dry-run ruleset report required status checks mismatch"
        in summary["blocking_errors"]
    )


def test_release_merge_handoff_blocks_publication_ruleset_report_covered_required_status_check_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    ruleset_path = Path(
        publication_summary["evidence_bundle_input_fingerprints"][
            "github_ruleset_report"
        ]["path"]
    )
    ruleset_path.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "checked_at": _fresh_ruleset_checked_at(),
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
                "required_status_checks": REQUIRED_STATUS_CHECKS,
                "covered_required_status_checks": REQUIRED_STATUS_CHECKS[:-1],
                "checks": REQUIRED_RULESET_CHECKS,
            }
        ),
        encoding="utf-8",
    )
    publication_summary["evidence_bundle_input_fingerprints"]["github_ruleset_report"][
        "sha256"
    ] = _sha256(ruleset_path)
    _write_json(publication_path, publication_summary)
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
    assert (
        "publication dry-run ruleset report covered required status checks mismatch"
        in summary["blocking_errors"]
    )


def test_release_merge_handoff_blocks_stale_publication_evidence_bundle_input_fingerprint(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary["input_fingerprints"]["evidence_bundle"]["sha256"] = "0" * 64
    _write_json(publication_path, publication_summary)
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
    assert "publication dry-run input fingerprints mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_stale_publication_release_notes_input_fingerprint(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary["input_fingerprints"]["release_notes"]["sha256"] = "0" * 64
    publication_summary["evidence_bundle_preflight_artifact_fingerprints"][
        "release_notes"
    ]["sha256"] = "0" * 64
    _write_json(publication_path, publication_summary)
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
    assert "publication dry-run input fingerprints mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_missing_publication_evidence_bundle_preflight_artifact_fingerprints(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary.pop("evidence_bundle_preflight_artifact_fingerprints")
    _write_json(publication_path, publication_summary)
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
    assert (
        "publication dry-run summary is missing evidence bundle preflight artifact fingerprints"
        in summary["blocking_errors"]
    )


def test_release_merge_handoff_blocks_publication_artifact_fingerprint_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary["evidence_bundle_preflight_artifact_fingerprints"][
        "release_notes"
    ]["sha256"] = "0" * 64
    _write_json(publication_path, publication_summary)
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
    assert "publication dry-run artifact fingerprints mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_stale_publication_proof_manifest_artifact_fingerprint(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary["evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ]["sha256"] = "0" * 64
    _write_json(publication_path, publication_summary)
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
    assert "publication dry-run artifact fingerprints mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_stale_publication_windows_bundle_verifier_artifact_fingerprint(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary["evidence_bundle_preflight_artifact_fingerprints"][
        "windows_bundle_verifier_summary"
    ]["sha256"] = "0" * 64
    _write_json(publication_path, publication_summary)
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
    assert "publication dry-run artifact fingerprints mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_publication_commit_sha_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary["evidence_bundle_preflight_commit_sha"] = "b" * 40
    _write_json(publication_path, publication_summary)
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
    assert "publication dry-run commit SHA mismatch" in summary["blocking_errors"]


def test_release_merge_handoff_blocks_publication_ref_commit_sha_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    publication_summary = json.loads(publication_path.read_text(encoding="utf-8"))
    publication_summary["evidence_bundle_preflight_ref_commit_sha"] = "b" * 40
    _write_json(publication_path, publication_summary)
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
    assert "publication dry-run ref commit SHA mismatch" in summary["blocking_errors"]


def test_release_merge_handoff_blocks_missing_latest_pr_url(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary.pop("latest_pr_url")
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
    assert "release stack GitHub status latest PR URL is missing" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_latest_pr_url_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["latest_pr_url"] = "https://github.com/Kiwunaka/Pokrov-client/pull/112"
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
    assert "release stack GitHub status latest PR URL mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_latest_pr_url_wrong_repository(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["latest_pr_url"] = "https://github.com/example/fork/pull/183"
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
    assert (
        "release stack GitHub status latest PR URL repository mismatch"
        in summary["blocking_errors"]
    )


def test_release_merge_handoff_blocks_github_status_pr_url_prefix_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["expected_pr_url_prefix"] = "https://github.com/example/fork/pull/"
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
    assert (
        "release stack GitHub status expected PR URL prefix mismatch"
        in summary["blocking_errors"]
    )


def test_release_merge_handoff_blocks_github_status_count_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["successful_check_count"] = 164
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
    assert "release stack GitHub status count mismatch" in summary["blocking_errors"]


def test_release_merge_handoff_blocks_github_status_pull_request_entry_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["pull_requests"] = github_summary["pull_requests"][:-1]
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
    assert (
        "release stack GitHub status pull request entries mismatch"
        in summary["blocking_errors"]
    )


def test_release_merge_handoff_blocks_github_status_pr_sequence_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["pull_requests"][0], github_summary["pull_requests"][1] = (
        github_summary["pull_requests"][1],
        github_summary["pull_requests"][0],
    )
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
    assert "release stack GitHub status PR sequence mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_github_status_pr_refs_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["pull_requests"][-1]["base"] = "codex/stale-base"
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
    assert "release stack GitHub status PR refs mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_github_status_pr_urls_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["pull_requests"][0][
        "url"
    ] = "https://github.com/example/fork/pull/62"
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
    assert "release stack GitHub status PR URLs mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_github_status_pr_states_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["pull_requests"][0]["mergeStateStatus"] = "BLOCKED"
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
    assert "release stack GitHub status PR states mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_github_status_pr_checks_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["pull_requests"][0].pop("checks")
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
    assert "release stack GitHub status PR checks mismatch" in summary[
        "blocking_errors"
    ]


def test_release_merge_handoff_blocks_github_status_pr_check_trace_mismatch(
    tmp_path: Path,
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["pull_requests"][0]["checks"][0]["details_url"] = ""
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
    assert "release stack GitHub status PR check trace mismatch" in summary[
        "blocking_errors"
    ]


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
        inventory["tracked_candidates"]["latest_candidate"] = "v0.135.0-source"
        inventory["tracked_candidates"]["latest_stacked_pr"] = 156
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


@pytest.mark.parametrize(
    ("generated_at", "expected_error"),
    [
        (
            "not-a-date",
            "Release merge handoff input 'github_status' must include parseable generated_at",
        ),
        (
            _stale_input_generated_at(),
            "Release merge handoff input 'github_status' has stale generated_at",
        ),
        (
            _future_input_generated_at(),
            "Release merge handoff input 'github_status' has stale generated_at",
        ),
    ],
)
def test_release_merge_handoff_rejects_unfresh_input_generated_at(
    tmp_path: Path, generated_at: str, expected_error: str
) -> None:
    merge_path, github_path, tag_path, publication_path = _write_input_summaries(
        tmp_path
    )
    github_summary = json.loads(github_path.read_text(encoding="utf-8"))
    github_summary["generated_at"] = generated_at
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
    assert expected_error in (result.stderr + result.stdout)


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
