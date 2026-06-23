from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
from datetime import datetime, timezone
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


def _fresh_generated_at() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _release_handoff_summary(ready: bool = True) -> dict:
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
        "latest_candidate": "v0.138.0-source",
        "latest_pr": 159,
        "latest_pr_url": "https://github.com/Kiwunaka/Pokrov-client/pull/159",
        "publication_dry_run_ok": True,
        "blocking_errors": [] if ready else ["release stack is not clean"],
    }


def _publication_dry_run_summary(tmp_path: Path, ready: bool = True) -> dict:
    release_notes = tmp_path / "release-notes.md"
    release_notes.write_text("# v0.138.0-source\n", encoding="utf-8")
    evidence_bundle = tmp_path / "release-evidence.json"
    evidence_bundle.write_text('{"source_only":true}', encoding="utf-8")
    proof_manifest = tmp_path / "proof.json"
    proof_manifest.write_text('{"source_only":true}', encoding="utf-8")
    source_archive = tmp_path / "source.zip"
    source_archive.write_bytes(b"source archive fixture")
    clean_clone = tmp_path / "preflight.json"
    clean_clone.write_text('{"clean_clone_or_import_proof":true}', encoding="utf-8")
    windows_verifier = tmp_path / "windows-bundle-verifier.json"
    windows_verifier.write_text('{"ok":true}', encoding="utf-8")

    return {
        "schema_version": 1,
        "generated_at": _fresh_generated_at(),
        "read_only": True,
        "tag": "v0.138.0-source",
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
        / "v0.138.0-source-publication-dry-run.json"
    )
    _write_json(handoff_path, _release_handoff_summary(handoff_ready))
    _write_json(publication_path, _publication_dry_run_summary(tmp_path, publication_ready))
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
    assert seed["policy"]["writes_only_ignored_build_output"] is True
    assert seed["inputs"]["release_handoff"] == (
        "build/release-merge-handoff/release-merge-handoff.json"
    )
    assert seed["inputs"]["publication_dry_run"].endswith(
        "v0.138.0-source-publication-dry-run.json"
    )


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
                out_dir / "v0.138.0-source" / "source-publication-packet.json"
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
    assert packet["latest_candidate"] == "v0.138.0-source"
    assert packet["latest_pr"] == 159
    assert packet["latest_pr_url"] == "https://github.com/Kiwunaka/Pokrov-client/pull/159"
    assert packet["release_notes"]["sha256"]
    assert packet["proof_manifest"]["sha256"]
    assert packet["source_archive"]["sha256"] == packet["source_archive_sha256"]
    assert packet["release_evidence_bundle"]["sha256"]
    assert packet["clean_clone_or_import_proof"]["sha256"]
    assert packet["input_fingerprints"]["release_handoff"]["sha256"] == _sha256(
        handoff_path
    )
    assert packet["input_fingerprints"]["publication_dry_run"]["sha256"] == _sha256(
        publication_path
    )
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
                out_dir / "v0.138.0-source" / "source-publication-packet.json"
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
                out_dir / "v0.138.0-source" / "source-publication-packet.json"
            ).read_text(encoding="utf-8-sig")
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert result.returncode == 2
    assert "source publication packet is missing proof_manifest fingerprint" in packet[
        "blocking_errors"
    ]


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
    assert not (out_dir / "v0.138.0-source" / "source-publication-packet.json").exists()
    assert "build\\source-publication-packet" in (result.stderr + result.stdout)


def test_source_publication_packet_is_documented_and_validated() -> None:
    docs = "\n".join(
        [
            _read("docs/README.md"),
            _read("docs/RELEASE_BLOCKERS.md"),
            _read("docs/RELEASE_CHECKLIST.md"),
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
    assert "source publication packet" in changelog.lower()
