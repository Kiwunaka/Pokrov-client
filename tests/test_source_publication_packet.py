from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload), encoding="utf-8")


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _write_source_zip(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("README.md", "# source archive fixture\n")


def _fresh_generated_at() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _stale_generated_at() -> str:
    return (
        datetime.now(timezone.utc) - timedelta(hours=48)
    ).isoformat().replace("+00:00", "Z")


def _release_handoff_summary(
    publication_path: Path,
    publication_summary: dict,
    ready: bool = True,
) -> dict:
    return {
        "schema_version": 1,
        "generated_at": _fresh_generated_at(),
        "read_only": True,
        "handoff_ready_for_maintainer": ready,
        "source_only": True,
        "no_apk": True,
        "no_exe": True,
        "no_store_release": True,
        "no_trusted_signing_claim": True,
        "manual_merge_required": True,
        "manual_tag_required": True,
        "publish_performed": False,
        "tag_push_performed": False,
        "ready_for_tag": False,
        "tag_creation_allowed": False,
        "latest_candidate": "v0.159.0-source",
        "latest_pr": 180,
        "latest_pr_url": "https://github.com/Kiwunaka/Pokrov-client/pull/180",
        "publication_dry_run_ok": True,
        "blocking_errors": [] if ready else ["release stack is not clean"],
        "input_fingerprints": {
            "publication_dry_run": {
                "path": str(publication_path),
                "sha256": _sha256(publication_path),
            },
        },
        "publication_dry_run_input_fingerprints": publication_summary[
            "input_fingerprints"
        ],
        "publication_dry_run_evidence_bundle_input_fingerprints": publication_summary[
            "evidence_bundle_input_fingerprints"
        ],
        "publication_dry_run_evidence_bundle_preflight_artifact_fingerprints": publication_summary[
            "evidence_bundle_preflight_artifact_fingerprints"
        ],
    }


def _publication_dry_run_summary(tmp_path: Path, ready: bool = True) -> dict:
    suffix = tmp_path.name
    preflight_root = (
        ROOT / "build" / "source-release-preflight" / "test-inputs" / suffix
    )
    proof_root = preflight_root / "proof"
    evidence_root = ROOT / "build" / "release-evidence" / "test-inputs" / suffix
    windows_root = (
        ROOT / "build" / "windows-bundle-verifier" / "test-inputs" / suffix
    )
    release_notes = preflight_root / "release-notes.md"
    release_notes.parent.mkdir(parents=True, exist_ok=True)
    release_notes.write_text(
        "\n".join(
            [
                "# v0.159.0-source",
                "",
                "This is a source-only release for manual GitHub Release review.",
                "",
                "## Included",
                "",
                "- Source archive and proof manifest.",
                "- Local community import, QR import, subscription refresh, and gated third-party catalog status.",
                "",
                "## Not Included",
                "",
                "- No APK artifacts.",
                "- No EXE artifacts.",
                "- No store release.",
                "- No trusted Windows signing claim.",
                "- No official binary claim.",
                "",
                "## Known Limitations",
                "",
                "- Maintainers must review the packet and publish manually.",
                "",
            ]
        ),
        encoding="utf-8",
    )
    source_archive = proof_root / "source.zip"
    _write_source_zip(source_archive)
    release_notes.write_text(
        "\n".join(
            [
                "# v0.159.0-source",
                "",
                "This is a source-only release for manual GitHub Release review.",
                "",
                "## Source Reference",
                "",
                f"- Source archive SHA-256: {_sha256(source_archive)}",
                "",
                "## Included",
                "",
                "- Source archive and proof manifest.",
                "- Local community import, QR import, subscription refresh, and gated third-party catalog status.",
                "",
                "## Not Included",
                "",
                "- No APK artifacts.",
                "- No EXE artifacts.",
                "- No store release.",
                "- No trusted Windows signing claim.",
                "- No official binary claim.",
                "",
                "## Known Limitations",
                "",
                "- Maintainers must review the packet and publish manually.",
                "",
            ]
        ),
        encoding="utf-8",
    )
    proof_manifest = proof_root / "proof.json"
    _write_json(
        proof_manifest,
        {
            "schema_version": 1,
            "tag": "v0.159.0-source",
            "commit_sha": "a" * 40,
            "source_archive": "source.zip",
            "source_archive_sha256": _sha256(source_archive),
            "source_only": True,
            "no_apk": True,
            "no_exe": True,
            "no_store_release": True,
            "no_trusted_signing_claim": True,
            "forbidden_file_count": 0,
        },
    )
    evidence_bundle = evidence_root / "release-evidence.json"
    _write_json(
        evidence_bundle,
        {
            "schema_version": 1,
            "tag": "v0.159.0-source",
            "commit_sha": "a" * 40,
            "preflight_commit_sha": "a" * 40,
            "preflight_ref_commit_sha": "a" * 40,
            "source_only": True,
            "no_apk": True,
            "no_exe": True,
            "no_store_release": True,
            "no_trusted_signing_claim": True,
            "forbidden_file_count": 0,
            "source_archive": "source.zip",
            "source_archive_sha256": _sha256(source_archive),
            "windows_bundle_verifier_ok": True,
            "windows_bundle_verifier_summary": "",
        },
    )
    clean_clone = preflight_root / "preflight.json"
    _write_json(
        clean_clone,
        {
            "schema_version": 1,
            "tag": "v0.159.0-source",
            "source_only": True,
            "no_apk": True,
            "no_exe": True,
            "no_store_release": True,
            "no_trusted_signing_claim": True,
            "forbidden_file_count": 0,
            "windows_bundle_verifier_ok": True,
            "source_archive_sha256": _sha256(source_archive),
        },
    )
    windows_verifier = windows_root / "windows-bundle-verifier.json"
    _write_json(
        windows_verifier,
        {
            "schema_version": 1,
            "windows_bundle_ok": True,
            "source_only": True,
            "no_runtime_download": True,
            "no_signing": True,
            "no_packaging": True,
            "no_publish": True,
            "build_performed": False,
            "signing_performed": False,
            "publish_performed": False,
            "runtime_download_performed": False,
            "forbidden_artifact_count": 0,
        },
    )

    return {
        "schema_version": 1,
        "generated_at": _fresh_generated_at(),
        "read_only": True,
        "tag": "v0.159.0-source",
        "commit_sha": "a" * 40,
        "source_only": True,
        "dry_run_only": True,
        "ready_for_manual_review": ready,
        "publish_performed": False,
        "tag_push_performed": False,
        "no_apk": True,
        "no_exe": True,
        "no_store_release": True,
        "no_trusted_signing_claim": True,
        "windows_bundle_verifier_ok": ready,
        "windows_bundle_verifier_summary": str(windows_verifier),
        "source_archive_sha256": _sha256(source_archive),
        "input_fingerprints": {
            "evidence_bundle": {
                "path": str(evidence_bundle),
                "sha256": _sha256(evidence_bundle),
            },
            "release_notes": {
                "path": str(release_notes),
                "sha256": _sha256(release_notes),
            },
        },
        "evidence_bundle_input_fingerprints": {
            "preflight_summary": {
                "path": str(clean_clone),
                "sha256": _sha256(clean_clone),
            },
        },
        "evidence_bundle_preflight_artifact_fingerprints": {
            "proof_manifest": {
                "path": str(proof_manifest),
                "sha256": _sha256(proof_manifest),
            },
            "release_notes": {
                "path": str(release_notes),
                "sha256": _sha256(release_notes),
            },
            "source_archive": {
                "path": str(source_archive),
                "sha256": _sha256(source_archive),
            },
            "windows_bundle_verifier_summary": {
                "path": str(windows_verifier),
                "sha256": _sha256(windows_verifier),
            },
        },
        "errors": [] if ready else ["Windows bundle verifier proof is missing"],
    }


def _write_input_summaries(
    tmp_path: Path,
    *,
    handoff_ready: bool = True,
    publication_ready: bool = True,
) -> tuple[Path, Path]:
    suffix = tmp_path.name
    handoff_path = (
        ROOT
        / "build"
        / "release-merge-handoff"
        / "test-inputs"
        / suffix
        / "release-merge-handoff.json"
    )
    publication_path = (
        ROOT
        / "build"
        / "source-release-publication"
        / "test-inputs"
        / suffix
        / "v0.159.0-source-publication-dry-run.json"
    )
    publication_summary = _publication_dry_run_summary(tmp_path, publication_ready)
    _write_json(publication_path, publication_summary)
    _write_json(
        handoff_path,
        _release_handoff_summary(publication_path, publication_summary, handoff_ready),
    )
    return handoff_path, publication_path


def test_source_publication_packet_seed_defines_manual_publish_policy() -> None:
    seed = _read_json("config/source-publication-packet.seed.json")

    assert seed["script"] == "scripts/prepare-source-publication-packet.ps1"
    assert seed["default_output_dir"] == "build/source-publication-packet"
    assert seed["policy"]["read_only"] is True
    assert seed["policy"]["source_only"] is True
    assert seed["policy"]["manual_publish_only"] is True
    assert seed["policy"]["no_tag_creation"] is True
    assert seed["policy"]["no_tag_push"] is True
    assert seed["policy"]["no_github_release_publish"] is True
    assert seed["policy"]["no_asset_upload"] is True
    assert seed["policy"]["requires_release_handoff_summary"] is True
    assert seed["policy"]["requires_publication_dry_run_summary"] is True
    assert seed["policy"]["requires_artifact_fingerprints"] is True
    assert seed["policy"]["requires_input_generated_at"] is True
    assert seed["policy"]["requires_input_generated_at_parseable"] is True
    assert seed["policy"]["requires_input_generated_at_freshness"] is True
    assert (
        seed["policy"][
            "requires_release_handoff_publication_dry_run_input_fingerprint_integrity"
        ]
        is True
    )
    assert (
        seed["policy"][
            "requires_publication_dry_run_carried_input_fingerprint_integrity"
        ]
        is True
    )
    assert (
        seed["policy"][
            "requires_publication_dry_run_carried_artifact_fingerprint_integrity"
        ]
        is True
    )
    assert (
        seed["policy"]["requires_publication_artifact_file_fingerprint_integrity"]
        is True
    )
    assert seed["policy"]["requires_publication_artifact_root_boundaries"] is True
    assert seed["policy"]["requires_source_only_release_asset_allowlist"] is True
    assert seed["policy"]["requires_publication_artifact_file_extensions"] is True
    assert seed["policy"]["requires_publication_artifact_content_validation"] is True
    assert seed["policy"]["requires_publication_artifact_schema_validation"] is True
    assert seed["policy"]["requires_release_notes_claim_guard"] is True
    assert seed["policy"]["forbids_release_notes_tbd_placeholders"] is True
    assert seed["policy"]["requires_release_notes_proof_values"] is True
    assert seed["policy"]["requires_proof_manifest_tag_binding"] is True
    assert seed["policy"]["requires_proof_manifest_commit_sha_binding"] is True
    assert seed["policy"]["requires_proof_manifest_source_archive_sha_binding"] is True
    assert seed["policy"]["requires_proof_manifest_source_archive_name_binding"] is True
    assert seed["policy"]["requires_release_evidence_bundle_tag_binding"] is True
    assert seed["policy"]["requires_release_evidence_bundle_commit_sha_binding"] is True
    assert (
        seed["policy"]["requires_release_evidence_bundle_source_archive_sha_binding"]
        is True
    )
    assert (
        seed["policy"]["requires_release_evidence_bundle_source_archive_name_binding"]
        is True
    )
    assert seed["policy"]["writes_only_ignored_build_output"] is True
    assert seed["inputs"]["release_handoff"] == (
        "build/release-merge-handoff/release-merge-handoff.json"
    )
    assert seed["inputs"]["publication_dry_run"].endswith(
        "v0.159.0-source-publication-dry-run.json"
    )
    assert seed["artifact_roots"] == {
        "release_notes": "build/source-release-preflight",
        "release_evidence_bundle": "build/release-evidence",
        "proof_manifest": "build/source-release-preflight",
        "source_archive": "build/source-release-preflight",
        "clean_clone_or_import_proof": "build/source-release-preflight",
        "windows_bundle_verifier_summary": "build/windows-bundle-verifier",
        "github_ruleset_report": "build/release-evidence",
    }
    assert seed["allowed_release_assets"] == [
        "release_notes",
        "proof_manifest",
        "source_archive",
        "release_evidence_bundle",
        "clean_clone_or_import_proof",
        "windows_bundle_verifier_summary",
        "github_ruleset_report",
    ]
    assert seed["artifact_file_extensions"] == {
        "release_notes": ".md",
        "release_evidence_bundle": ".json",
        "proof_manifest": ".json",
        "source_archive": ".zip",
        "clean_clone_or_import_proof": ".json",
        "windows_bundle_verifier_summary": ".json",
        "github_ruleset_report": ".json",
    }
    assert seed["artifact_content_types"] == {
        "release_notes": "markdown",
        "release_evidence_bundle": "json",
        "proof_manifest": "json",
        "source_archive": "zip",
        "clean_clone_or_import_proof": "json",
        "windows_bundle_verifier_summary": "json",
        "github_ruleset_report": "json",
    }
    assert seed["artifact_schema_contracts"] == {
        "release_evidence_bundle": "source_evidence",
        "proof_manifest": "source_proof",
        "clean_clone_or_import_proof": "source_preflight",
        "windows_bundle_verifier_summary": "windows_bundle_verifier",
        "github_ruleset_report": "github_ruleset_report",
    }
    assert seed["release_notes_required_markers"] == [
        "source-only release",
        "## Included",
        "## Not Included",
        "## Known Limitations",
        "No APK",
        "No EXE",
        "No store release",
        "No trusted Windows signing claim",
        "official binary",
    ]
    assert seed["release_notes_proof_requirements"] == [
        "publication_dry_run.tag",
        "publication_dry_run.source_archive_sha256",
    ]
    assert seed["proof_manifest_proof_requirements"] == [
        "proof_manifest.tag",
        "proof_manifest.commit_sha",
        "proof_manifest.source_archive",
        "proof_manifest.source_archive_sha256",
        "publication_dry_run.tag",
        "publication_dry_run.commit_sha",
        "publication_dry_run.source_archive_sha256",
    ]
    assert seed["release_evidence_bundle_proof_requirements"] == [
        "release_evidence_bundle.tag",
        "release_evidence_bundle.commit_sha",
        "release_evidence_bundle.source_archive",
        "release_evidence_bundle.source_archive_sha256",
        "publication_dry_run.tag",
        "publication_dry_run.commit_sha",
        "publication_dry_run.source_archive_sha256",
    ]


def test_source_publication_packet_script_is_read_only() -> None:
    script = _read("scripts/prepare-source-publication-packet.ps1")

    for phrase in (
        "source-publication-packet.seed.json",
        "release_handoff",
        "publication_dry_run",
        "handoff_ready_for_maintainer",
        "ready_for_manual_review",
        "source_only",
        "no_apk",
        "no_exe",
        "no_store_release",
        "no_trusted_signing_claim",
        "release_notes",
        "proof_manifest",
        "source_archive",
        "release_evidence_bundle",
        "clean_clone_or_import_proof",
        "input_fingerprints",
        "input_generated_at",
        "release_handoff_publication_dry_run_input_fingerprints",
        "release handoff publication dry-run input",
        "handoff-carried publication dry-run",
        "source_archive",
        "fingerprint mismatch",
        "artifact_file_fingerprints",
        "source publication packet artifact fingerprint mismatch",
        "artifact_roots",
        "source publication packet artifact path outside expected root",
        "allowed_release_assets",
        "source publication packet unexpected release asset fingerprint",
        "artifact_file_extensions",
        "source publication packet artifact file extension mismatch",
        "artifact_content_types",
        "source publication packet artifact content invalid",
        "artifact_schema_contracts",
        "source publication packet artifact schema invalid",
        "release_notes_required_markers",
        "source publication packet release notes claims invalid",
        "release_notes_proof_requirements",
        "source publication packet release notes proof mismatch",
        "proof_manifest_proof_requirements",
        "source publication packet proof manifest tag mismatch",
        "source publication packet proof manifest commit SHA mismatch",
        "source publication packet proof manifest source archive SHA mismatch",
        "source publication packet proof manifest source archive name mismatch",
        "release_evidence_bundle_proof_requirements",
        "source publication packet release evidence bundle tag mismatch",
        "source publication packet release evidence bundle commit SHA mismatch",
        "source publication packet release evidence bundle source archive SHA mismatch",
        "Test-PathUnderRoot",
        "must include generated_at timestamp",
        "must include parseable generated_at timestamp",
        "has stale generated_at timestamp",
        "ComputeHash",
        "packet_ready_for_manual_publish_review",
        "asset_upload_performed = $false",
        "build\\source-publication-packet",
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


def test_source_publication_packet_command_writes_review_packet(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    out_dir = ROOT / "build" / "source-publication-packet" / "test-output"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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

        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert packet["packet_ready_for_manual_publish_review"] is True
    assert packet["read_only"] is True
    assert packet["source_only"] is True
    assert packet["manual_publish_only"] is True
    assert packet["publish_performed"] is False
    assert packet["tag_push_performed"] is False
    assert packet["asset_upload_performed"] is False
    assert packet["no_apk"] is True
    assert packet["no_exe"] is True
    assert packet["no_store_release"] is True
    assert packet["no_trusted_signing_claim"] is True
    assert packet["latest_candidate"] == "v0.159.0-source"
    assert packet["latest_pr"] == 180
    assert packet["latest_pr_url"] == "https://github.com/Kiwunaka/Pokrov-client/pull/180"
    assert packet["release_notes"]["sha256"]
    assert packet["proof_manifest"]["sha256"]
    assert packet["source_archive"]["sha256"] == packet["source_archive_sha256"]
    assert packet["release_evidence_bundle"]["sha256"]
    assert packet["clean_clone_or_import_proof"]["sha256"]
    assert packet["allowed_release_assets"] == [
        "release_notes",
        "proof_manifest",
        "source_archive",
        "release_evidence_bundle",
        "clean_clone_or_import_proof",
        "windows_bundle_verifier_summary",
        "github_ruleset_report",
    ]
    assert packet["artifact_file_extensions"]["source_archive"] == ".zip"
    assert packet["artifact_file_extensions"]["release_notes"] == ".md"
    assert packet["release_notes_required_markers"] == [
        "source-only release",
        "## Included",
        "## Not Included",
        "## Known Limitations",
        "No APK",
        "No EXE",
        "No store release",
        "No trusted Windows signing claim",
        "official binary",
    ]
    assert packet["release_notes_proof_requirements"] == [
        "publication_dry_run.tag",
        "publication_dry_run.source_archive_sha256",
    ]
    assert packet["proof_manifest_proof_requirements"] == [
        "proof_manifest.tag",
        "proof_manifest.commit_sha",
        "proof_manifest.source_archive",
        "proof_manifest.source_archive_sha256",
        "publication_dry_run.tag",
        "publication_dry_run.commit_sha",
        "publication_dry_run.source_archive_sha256",
    ]
    assert packet["release_evidence_bundle_proof_requirements"] == [
        "release_evidence_bundle.tag",
        "release_evidence_bundle.commit_sha",
        "release_evidence_bundle.source_archive",
        "release_evidence_bundle.source_archive_sha256",
        "publication_dry_run.tag",
        "publication_dry_run.commit_sha",
        "publication_dry_run.source_archive_sha256",
    ]
    assert packet["publication_dry_run_release_asset_fingerprints"] is None
    assert packet["input_fingerprints"]["release_handoff"]["sha256"] == _sha256(
        handoff_path
    )
    assert packet["input_fingerprints"]["publication_dry_run"]["sha256"] == _sha256(
        publication_path
    )
    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    assert packet["release_handoff_publication_dry_run_input_fingerprints"] == handoff[
        "publication_dry_run_input_fingerprints"
    ]
    assert (
        packet[
            "release_handoff_publication_dry_run_evidence_bundle_input_fingerprints"
        ]
        == handoff["publication_dry_run_evidence_bundle_input_fingerprints"]
    )
    assert (
        packet[
            "release_handoff_publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"
        ]
        == handoff[
            "publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"
        ]
    )
    assert packet["publication_dry_run_input_fingerprints"] == publication[
        "input_fingerprints"
    ]
    assert packet["artifact_file_fingerprints"]["release_notes"]["sha256"] == _sha256(
        Path(packet["release_notes"]["path"])
    )
    assert packet["artifact_file_fingerprints"]["source_archive"]["sha256"] == _sha256(
        Path(packet["source_archive"]["path"])
    )
    assert packet["input_generated_at"] == {
        "release_handoff": handoff["generated_at"],
        "publication_dry_run": publication["generated_at"],
    }
    assert packet["blocking_errors"] == []


def test_source_publication_packet_rejects_blocked_inputs(tmp_path: Path) -> None:
    handoff_path, publication_path = _write_input_summaries(
        tmp_path,
        handoff_ready=False,
        publication_ready=False,
    )
    out_dir = ROOT / "build" / "source-publication-packet" / "test-blocked"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert packet["packet_ready_for_manual_publish_review"] is False
    assert "release handoff must be ready for maintainer review" in packet[
        "blocking_errors"
    ]
    assert "publication dry-run must be ready for manual review" in packet[
        "blocking_errors"
    ]


def test_source_publication_packet_rejects_missing_artifact_fingerprint(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    publication["evidence_bundle_preflight_artifact_fingerprints"].pop(
        "proof_manifest"
    )
    _write_json(publication_path, publication)
    out_dir = ROOT / "build" / "source-publication-packet" / "test-missing-fingerprint"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert "source publication packet is missing proof_manifest fingerprint" in packet[
        "blocking_errors"
    ]


def test_source_publication_packet_rejects_stale_handoff_publication_dry_run_fingerprint(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["input_fingerprints"]["publication_dry_run"]["sha256"] = "0" * 64
    _write_json(handoff_path, handoff)
    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-stale-handoff-publication-dry-run"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert "release handoff publication dry-run input fingerprint mismatch" in packet[
        "blocking_errors"
    ]


def test_source_publication_packet_rejects_handoff_carried_artifact_fingerprint_mismatch(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff[
        "publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"
    ]["source_archive"]["sha256"] = "f" * 64
    _write_json(handoff_path, handoff)
    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-carried-artifact-mismatch"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "handoff-carried publication dry-run source_archive artifact fingerprint mismatch"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_stale_artifact_file_fingerprint(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    source_archive_path = Path(
        publication["evidence_bundle_preflight_artifact_fingerprints"][
            "source_archive"
        ]["path"]
    )
    source_archive_path.write_bytes(b"changed after publication dry-run")
    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-stale-artifact-file"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert "source publication packet artifact fingerprint mismatch for source_archive" in packet[
        "blocking_errors"
    ]
    assert packet["artifact_file_fingerprints"]["source_archive"]["sha256"] == _sha256(
        source_archive_path
    )


def test_source_publication_packet_rejects_source_archive_with_binary_extension(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    original_archive = Path(
        publication["evidence_bundle_preflight_artifact_fingerprints"][
            "source_archive"
        ]["path"]
    )
    disguised_archive = original_archive.with_name("source.apk")
    disguised_archive.write_bytes(b"not a source archive")
    disguised_fingerprint = {
        "path": str(disguised_archive),
        "sha256": _sha256(disguised_archive),
    }

    publication["evidence_bundle_preflight_artifact_fingerprints"][
        "source_archive"
    ] = disguised_fingerprint
    publication["source_archive_sha256"] = disguised_fingerprint["sha256"]
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"][
        "source_archive"
    ] = disguised_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-source-archive-extension"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet artifact file extension mismatch for source_archive"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_invalid_source_archive_zip(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    source_archive_path = Path(
        publication["evidence_bundle_preflight_artifact_fingerprints"][
            "source_archive"
        ]["path"]
    )
    source_archive_path.write_bytes(b"not a valid zip archive")
    invalid_fingerprint = {
        "path": str(source_archive_path),
        "sha256": _sha256(source_archive_path),
    }

    publication["evidence_bundle_preflight_artifact_fingerprints"][
        "source_archive"
    ] = invalid_fingerprint
    publication["source_archive_sha256"] = invalid_fingerprint["sha256"]
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"][
        "source_archive"
    ] = invalid_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-source-archive-content"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet artifact content invalid for source_archive"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_release_notes_without_claim_guards(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    release_notes_path = Path(publication["input_fingerprints"]["release_notes"]["path"])
    release_notes_path.write_text("# v0.159.0-source\n", encoding="utf-8")
    thin_notes_fingerprint = {
        "path": str(release_notes_path),
        "sha256": _sha256(release_notes_path),
    }

    publication["input_fingerprints"]["release_notes"] = thin_notes_fingerprint
    publication["evidence_bundle_preflight_artifact_fingerprints"][
        "release_notes"
    ] = thin_notes_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_input_fingerprints"][
        "release_notes"
    ] = thin_notes_fingerprint
    handoff["publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"][
        "release_notes"
    ] = thin_notes_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-release-notes-claims"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet release notes claims invalid"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_release_notes_with_wrong_source_sha(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    release_notes_path = Path(publication["input_fingerprints"]["release_notes"]["path"])
    release_notes_path.write_text(
        "\n".join(
            [
                "# v0.159.0-source",
                "",
                "This is a source-only release for manual GitHub Release review.",
                "",
                "## Source Reference",
                "",
                "- Source archive SHA-256: " + ("0" * 64),
                "",
                "## Included",
                "",
                "- Source archive and proof manifest.",
                "",
                "## Not Included",
                "",
                "- No APK artifacts.",
                "- No EXE artifacts.",
                "- No store release.",
                "- No trusted Windows signing claim.",
                "- No official binary claim.",
                "",
                "## Known Limitations",
                "",
                "- Maintainers must review the packet and publish manually.",
                "",
            ]
        ),
        encoding="utf-8",
    )
    wrong_sha_notes_fingerprint = {
        "path": str(release_notes_path),
        "sha256": _sha256(release_notes_path),
    }

    publication["input_fingerprints"]["release_notes"] = wrong_sha_notes_fingerprint
    publication["evidence_bundle_preflight_artifact_fingerprints"][
        "release_notes"
    ] = wrong_sha_notes_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_input_fingerprints"][
        "release_notes"
    ] = wrong_sha_notes_fingerprint
    handoff["publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"][
        "release_notes"
    ] = wrong_sha_notes_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-release-notes-proof"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet release notes proof mismatch"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_invalid_proof_manifest_schema(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    proof_manifest_path = Path(
        publication["evidence_bundle_preflight_artifact_fingerprints"][
            "proof_manifest"
        ]["path"]
    )
    _write_json(proof_manifest_path, {"source_only": True})
    invalid_fingerprint = {
        "path": str(proof_manifest_path),
        "sha256": _sha256(proof_manifest_path),
    }

    publication["evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ] = invalid_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ] = invalid_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-proof-manifest-schema"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet artifact schema invalid for proof_manifest"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_proof_manifest_source_sha_mismatch(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    proof_manifest_path = Path(
        publication["evidence_bundle_preflight_artifact_fingerprints"][
            "proof_manifest"
        ]["path"]
    )
    proof_manifest = json.loads(proof_manifest_path.read_text(encoding="utf-8"))
    proof_manifest["source_archive_sha256"] = "0" * 64
    _write_json(proof_manifest_path, proof_manifest)
    mismatched_fingerprint = {
        "path": str(proof_manifest_path),
        "sha256": _sha256(proof_manifest_path),
    }

    publication["evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ] = mismatched_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ] = mismatched_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-proof-manifest-source-sha"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet proof manifest source archive SHA mismatch"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_proof_manifest_source_archive_name_mismatch(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    proof_manifest_path = Path(
        publication["evidence_bundle_preflight_artifact_fingerprints"][
            "proof_manifest"
        ]["path"]
    )
    proof_manifest = json.loads(proof_manifest_path.read_text(encoding="utf-8"))
    proof_manifest["source_archive"] = "different-source.zip"
    _write_json(proof_manifest_path, proof_manifest)
    mismatched_fingerprint = {
        "path": str(proof_manifest_path),
        "sha256": _sha256(proof_manifest_path),
    }

    publication["evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ] = mismatched_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ] = mismatched_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-proof-manifest-source-archive-name"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet proof manifest source archive name mismatch"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_proof_manifest_commit_sha_mismatch(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    proof_manifest_path = Path(
        publication["evidence_bundle_preflight_artifact_fingerprints"][
            "proof_manifest"
        ]["path"]
    )
    proof_manifest = json.loads(proof_manifest_path.read_text(encoding="utf-8"))
    proof_manifest["commit_sha"] = "b" * 40
    _write_json(proof_manifest_path, proof_manifest)
    mismatched_fingerprint = {
        "path": str(proof_manifest_path),
        "sha256": _sha256(proof_manifest_path),
    }

    publication["evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ] = mismatched_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ] = mismatched_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-proof-manifest-commit-sha"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet proof manifest commit SHA mismatch"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_proof_manifest_tag_mismatch(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    proof_manifest_path = Path(
        publication["evidence_bundle_preflight_artifact_fingerprints"][
            "proof_manifest"
        ]["path"]
    )
    proof_manifest = json.loads(proof_manifest_path.read_text(encoding="utf-8"))
    proof_manifest["tag"] = "v0.1.0-source"
    _write_json(proof_manifest_path, proof_manifest)
    mismatched_fingerprint = {
        "path": str(proof_manifest_path),
        "sha256": _sha256(proof_manifest_path),
    }

    publication["evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ] = mismatched_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ] = mismatched_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-proof-manifest-tag"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet proof manifest tag mismatch"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_release_evidence_bundle_tag_mismatch(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    evidence_bundle_path = Path(
        publication["input_fingerprints"]["evidence_bundle"]["path"]
    )
    evidence_bundle = json.loads(evidence_bundle_path.read_text(encoding="utf-8"))
    evidence_bundle["tag"] = "v0.1.0-source"
    _write_json(evidence_bundle_path, evidence_bundle)
    mismatched_fingerprint = {
        "path": str(evidence_bundle_path),
        "sha256": _sha256(evidence_bundle_path),
    }

    publication["input_fingerprints"]["evidence_bundle"] = mismatched_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_input_fingerprints"][
        "evidence_bundle"
    ] = mismatched_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-release-evidence-bundle-tag"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet release evidence bundle tag mismatch"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_release_evidence_bundle_commit_sha_mismatch(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    evidence_bundle_path = Path(
        publication["input_fingerprints"]["evidence_bundle"]["path"]
    )
    evidence_bundle = json.loads(evidence_bundle_path.read_text(encoding="utf-8"))
    evidence_bundle["commit_sha"] = "b" * 40
    _write_json(evidence_bundle_path, evidence_bundle)
    mismatched_fingerprint = {
        "path": str(evidence_bundle_path),
        "sha256": _sha256(evidence_bundle_path),
    }

    publication["input_fingerprints"]["evidence_bundle"] = mismatched_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_input_fingerprints"][
        "evidence_bundle"
    ] = mismatched_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-release-evidence-bundle-commit"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet release evidence bundle commit SHA mismatch"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_release_evidence_bundle_source_archive_sha_mismatch(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    evidence_bundle_path = Path(
        publication["input_fingerprints"]["evidence_bundle"]["path"]
    )
    evidence_bundle = json.loads(evidence_bundle_path.read_text(encoding="utf-8"))
    evidence_bundle["source_archive_sha256"] = "3" * 64
    _write_json(evidence_bundle_path, evidence_bundle)
    mismatched_fingerprint = {
        "path": str(evidence_bundle_path),
        "sha256": _sha256(evidence_bundle_path),
    }

    publication["input_fingerprints"]["evidence_bundle"] = mismatched_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_input_fingerprints"][
        "evidence_bundle"
    ] = mismatched_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-release-evidence-bundle-source-archive-sha"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet release evidence bundle source archive SHA mismatch"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_release_evidence_bundle_source_archive_name_mismatch(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    evidence_bundle_path = Path(
        publication["input_fingerprints"]["evidence_bundle"]["path"]
    )
    evidence_bundle = json.loads(evidence_bundle_path.read_text(encoding="utf-8"))
    evidence_bundle["source_archive"] = "other-source.zip"
    _write_json(evidence_bundle_path, evidence_bundle)
    mismatched_fingerprint = {
        "path": str(evidence_bundle_path),
        "sha256": _sha256(evidence_bundle_path),
    }

    publication["input_fingerprints"]["evidence_bundle"] = mismatched_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_input_fingerprints"][
        "evidence_bundle"
    ] = mismatched_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-release-evidence-bundle-source-archive-name"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet release evidence bundle source archive name mismatch"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_artifact_path_outside_expected_root(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    outside_notes = tmp_path / "outside-release-notes.md"
    outside_notes.write_text("# outside\n", encoding="utf-8")
    outside_fingerprint = {
        "path": str(outside_notes),
        "sha256": _sha256(outside_notes),
    }

    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    publication["input_fingerprints"]["release_notes"] = outside_fingerprint
    publication["evidence_bundle_preflight_artifact_fingerprints"][
        "release_notes"
    ] = outside_fingerprint
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["publication_dry_run_input_fingerprints"][
        "release_notes"
    ] = outside_fingerprint
    handoff["publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"][
        "release_notes"
    ] = outside_fingerprint
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-artifact-root-boundary"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet artifact path outside expected root for release_notes"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_unexpected_release_asset_fingerprint(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    unexpected_asset = tmp_path / "client.apk"
    unexpected_asset.write_bytes(b"not a source release asset")

    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    publication["release_asset_fingerprints"] = {
        "android_apk": {
            "path": str(unexpected_asset),
            "sha256": _sha256(unexpected_asset),
        }
    }
    _write_json(publication_path, publication)

    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    handoff["input_fingerprints"]["publication_dry_run"] = {
        "path": str(publication_path),
        "sha256": _sha256(publication_path),
    }
    _write_json(handoff_path, handoff)

    out_dir = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-unexpected-release-asset"
    )
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert (
        "source publication packet unexpected release asset fingerprint: android_apk"
        in packet["blocking_errors"]
    )


def test_source_publication_packet_rejects_stale_or_unparseable_input_generated_at(
    tmp_path: Path,
) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    publication = json.loads(publication_path.read_text(encoding="utf-8"))
    handoff["generated_at"] = _stale_generated_at()
    publication["generated_at"] = "not-a-timestamp"
    _write_json(handoff_path, handoff)
    _write_json(publication_path, publication)
    out_dir = ROOT / "build" / "source-publication-packet" / "test-stale-inputs"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
                "-ReleaseHandoffPath",
                str(handoff_path),
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
        packet = json.loads(
            (
                out_dir / "v0.159.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert "release handoff has stale generated_at timestamp" in packet[
        "blocking_errors"
    ]
    assert "publication dry-run must include parseable generated_at timestamp" in packet[
        "blocking_errors"
    ]
    assert packet["input_generated_at"] == {
        "release_handoff": handoff["generated_at"],
        "publication_dry_run": publication["generated_at"],
    }


def test_source_publication_packet_rejects_non_build_output(tmp_path: Path) -> None:
    handoff_path, publication_path = _write_input_summaries(tmp_path)
    out_dir = tmp_path / "outside-build"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "prepare-source-publication-packet.ps1"),
            "-ReleaseHandoffPath",
            str(handoff_path),
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
    assert not (out_dir / "v0.159.0-source" / "source-publication-packet.json").exists()
    assert "build\\source-publication-packet" in (result.stderr + result.stdout)


def test_source_publication_packet_is_documented_and_validated() -> None:
    docs = "\n".join(
        [
            _read("docs/README.md"),
            _read("docs/RELEASE_BLOCKERS.md"),
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("docs/RELEASE_POLICY.md"),
            _read("scripts/README.md"),
        ]
    )
    validator = _read("scripts/validate-seed.ps1")
    changelog = _read("CHANGELOG.md")

    assert "prepare-source-publication-packet.ps1" in docs
    assert "source publication packet" in docs
    assert "config\\\\source-publication-packet.seed.json" in validator
    assert "scripts\\\\prepare-source-publication-packet.ps1" in validator
    assert "requires_release_handoff_summary" in validator
    assert "packet_ready_for_manual_publish_review" in validator
    assert "artifact_roots" in validator
    assert "source publication packet artifact path outside expected root" in validator
    assert "allowed_release_assets" in validator
    assert "source publication packet unexpected release asset fingerprint" in validator
    assert "artifact_file_extensions" in validator
    assert "source publication packet artifact file extension mismatch" in validator
    assert "artifact_content_types" in validator
    assert "source publication packet artifact content invalid" in validator
    assert "artifact_schema_contracts" in validator
    assert "source publication packet artifact schema invalid" in validator
    assert "source publication packet" in changelog.lower()
