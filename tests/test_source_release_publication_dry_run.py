from __future__ import annotations

import json
import hashlib
import subprocess
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _write_preflight_fixture(tmp_path: Path) -> Path:
    preflight = tmp_path / "preflight.json"
    preflight.write_text('{"source_only":true}', encoding="utf-8")
    return preflight


def _preflight_input_fingerprints(preflight: Path) -> dict:
    return {
        "preflight_summary": {
            "path": str(preflight),
            "sha256": _sha256(preflight),
        }
    }


def _release_notes_text(source_sha256: str) -> str:
    return "\n".join(
        [
            "# v9.9.9-source",
            "Source archive SHA-256: " + source_sha256,
            "Source proof manifest: proof.json",
            "Verification date: 2026-06-14T00:00:00Z",
            "This is a source-only release.",
            "No APK or EXE binaries.",
            "No store release.",
            "No trusted Windows signing claim.",
            "No official POKROV backend, billing, admin, deployment, signing, or private release evidence.",
            "Release evidence is separate public evidence.",
            "scripts\\source-release-preflight.ps1",
            "scripts\\prepare-source-release.ps1",
            "scripts\\render-source-release-notes.ps1",
        ]
    )


def test_publication_dry_run_seed_defines_no_publish_policy() -> None:
    seed = _read_json("config/source-release-publication-dry-run.seed.json")

    assert seed["script"] == "scripts/validate-source-release-publication.ps1"
    assert seed["default_output_dir"] == "build/source-release-publication"
    assert seed["policy"]["read_only"] is True
    assert seed["policy"]["dry_run_only"] is True
    assert seed["policy"]["no_github_release_publish"] is True
    assert seed["policy"]["no_tag_push"] is True
    assert seed["policy"]["writes_only_ignored_build_output"] is True
    assert seed["policy"]["requires_source_only_evidence_bundle"] is True
    assert seed["policy"]["requires_release_copy_check"] is True
    assert seed["policy"]["requires_input_fingerprints"] is True
    assert seed["policy"]["requires_evidence_bundle_input_fingerprints"] is True
    assert (
        seed["policy"]["requires_evidence_bundle_preflight_input_fingerprint_integrity"]
        is True
    )
    assert (
        seed["policy"][
            "requires_evidence_bundle_ruleset_report_input_fingerprint_integrity"
        ]
        is True
    )
    assert seed["policy"]["requires_evidence_bundle_ruleset_report_shape"] is True
    assert seed["policy"]["requires_evidence_bundle_ruleset_report_target"] is True
    assert (
        seed["policy"]["requires_evidence_bundle_ruleset_report_ok_consistency"]
        is True
    )
    assert seed["policy"]["requires_evidence_bundle_preflight_artifact_fingerprints"] is True
    assert (
        seed["policy"]["requires_evidence_bundle_preflight_artifact_fingerprint_integrity"]
        is True
    )
    assert (
        seed["policy"]["requires_evidence_bundle_preflight_commit_sha_consistency"]
        is True
    )
    assert (
        seed["policy"]["requires_evidence_bundle_preflight_ref_commit_sha_consistency"]
        is True
    )
    assert seed["policy"]["github_enforcement_claim_requires_bundle_approval"] is True
    assert seed["policy"]["windows_bundle_verifier_claim_requires_bundle_proof"] is True
    assert "windows_bundle_verifier_ok" in seed["required_evidence_flags"]


def test_publication_dry_run_script_is_local_only() -> None:
    script = _read("scripts/validate-source-release-publication.ps1")

    for phrase in (
        "check-source-release-copy.ps1",
        "github_enforcement_claim_allowed",
        "publish_performed = $false",
        "tag_push_performed = $false",
        "read_only = $true",
        "dry_run_only = $true",
        "windows_bundle_verifier_ok",
        "windows_bundle_verifier_summary",
        "input_fingerprints",
        "evidence_bundle_input_fingerprints",
        "Assert-InputFingerprintIntegrity",
        "Assert-RulesetReportInputFingerprintIntegrity",
        "github ruleset report fingerprint mismatch",
        "ruleset report without schema_version 1",
        "ruleset report that is not read-only",
        "ruleset report without ok status",
        "ruleset report repository mismatch",
        "ruleset report branch mismatch",
        "ruleset report ok status without checks",
        "ruleset report ok status with failed checks",
        "evidence_bundle_preflight_artifact_fingerprints",
        "evidence_bundle_preflight_commit_sha",
        "evidence_bundle_preflight_ref_commit_sha",
        "evidence commit SHA does not match preflight commit SHA",
        "evidence preflight commit SHA does not match resolved ref commit SHA",
        "evidence bundle is missing input fingerprints",
        "evidence bundle preflight summary fingerprint mismatch",
        "evidence bundle is missing preflight artifact fingerprints",
        "artifact fingerprint mismatch",
        "SHA256",
        "ComputeHash",
        "build\\source-release-publication",
    ):
        assert phrase in script

    for forbidden in (
        "gh release create",
        "gh release upload",
        "git push",
        "-X POST",
        "-X PATCH",
        "-X PUT",
        "-X DELETE",
    ):
        assert forbidden not in script


def test_publication_dry_run_writes_summary_from_fixtures(tmp_path: Path) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    preflight = _write_preflight_fixture(tmp_path)
    proof = tmp_path / "proof.json"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    out_dir = tmp_path / "out"

    proof.write_text('{"source_only":true}', encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    notes.write_text(
        "\n".join(
            [
                "# v9.9.9-source",
                "Source archive SHA-256: " + _sha256(source),
                "Source proof manifest: proof.json",
                "Verification date: 2026-06-14T00:00:00Z",
                "This is a source-only release.",
                "No APK or EXE binaries.",
                "No store release.",
                "No trusted Windows signing claim.",
                "No official POKROV backend, billing, admin, deployment, signing, or private release evidence.",
                "Release evidence is separate public evidence.",
                "scripts\\source-release-preflight.ps1",
                "scripts\\prepare-source-release.ps1",
                "scripts\\render-source-release-notes.ps1",
            ]
        ),
        encoding="utf-8",
    )
    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "a" * 40,
                "preflight_ref_commit_sha": "a" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": _sha256(source),
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "github_ruleset_ok": False,
                "github_enforcement_claim_allowed": False,
                "input_fingerprints": _preflight_input_fingerprints(preflight),
                "preflight_artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
                },
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )

    summary = json.loads((out_dir / "v9.9.9-source-publication-dry-run.json").read_text())
    assert summary["read_only"] is True
    assert summary["dry_run_only"] is True
    assert summary["publish_performed"] is False
    assert summary["tag_push_performed"] is False
    assert summary["github_enforcement_claim_allowed"] is False
    assert summary["commit_sha"] == "a" * 40
    assert summary["evidence_bundle_preflight_commit_sha"] == "a" * 40
    assert summary["evidence_bundle_preflight_ref_commit_sha"] == "a" * 40
    assert summary["windows_bundle_verifier_ok"] is True
    assert summary["windows_bundle_verifier_summary"].endswith(
        "windows-bundle-verifier.json"
    )
    assert summary["input_fingerprints"]["evidence_bundle"]["sha256"] == _sha256(
        evidence
    )
    assert summary["input_fingerprints"]["release_notes"]["sha256"] == _sha256(
        notes
    )
    assert summary["evidence_bundle_input_fingerprints"]["preflight_summary"][
        "sha256"
    ] == _sha256(preflight)
    assert summary["evidence_bundle_preflight_artifact_fingerprints"][
        "proof_manifest"
    ]["sha256"] == _sha256(proof)
    assert summary["evidence_bundle_preflight_artifact_fingerprints"][
        "source_archive"
    ]["sha256"] == _sha256(source)
    assert summary["ready_for_manual_review"] is True


def test_publication_dry_run_rejects_evidence_without_input_fingerprints(
    tmp_path: Path,
) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    out_dir = tmp_path / "out"

    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "a" * 40,
                "preflight_ref_commit_sha": "a" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": "b" * 64,
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": "build/windows-bundle-verifier/windows-bundle-verifier.json",
                "github_ruleset_ok": False,
                "github_enforcement_claim_allowed": False,
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    notes.write_text(
        "\n".join(
            [
                "# v9.9.9-source",
                "Source archive SHA-256: " + "b" * 64,
                "Source proof manifest: proof.json",
                "Verification date: 2026-06-14T00:00:00Z",
                "This is a source-only release.",
                "No APK or EXE binaries.",
                "No store release.",
                "No trusted Windows signing claim.",
                "No official POKROV backend, billing, admin, deployment, signing, or private release evidence.",
                "Release evidence is separate public evidence.",
                "scripts\\source-release-preflight.ps1",
                "scripts\\prepare-source-release.ps1",
                "scripts\\render-source-release-notes.ps1",
            ]
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-publication-dry-run.json").exists()
    assert "evidence bundle is missing input fingerprints" in (
        result.stderr + result.stdout
    )


def test_publication_dry_run_rejects_stale_preflight_input_fingerprint(
    tmp_path: Path,
) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    preflight = tmp_path / "preflight.json"
    proof = tmp_path / "proof.json"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    out_dir = tmp_path / "out"

    preflight.write_text('{"source_only":true}', encoding="utf-8")
    proof.write_text('{"source_only":true}', encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    notes.write_text(
        "\n".join(
            [
                "# v9.9.9-source",
                "Source archive SHA-256: " + _sha256(source),
                "Source proof manifest: proof.json",
                "Verification date: 2026-06-14T00:00:00Z",
                "This is a source-only release.",
                "No APK or EXE binaries.",
                "No store release.",
                "No trusted Windows signing claim.",
                "No official POKROV backend, billing, admin, deployment, signing, or private release evidence.",
                "Release evidence is separate public evidence.",
                "scripts\\source-release-preflight.ps1",
                "scripts\\prepare-source-release.ps1",
                "scripts\\render-source-release-notes.ps1",
            ]
        ),
        encoding="utf-8",
    )
    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "a" * 40,
                "preflight_ref_commit_sha": "a" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": _sha256(source),
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "github_ruleset_ok": False,
                "github_enforcement_claim_allowed": False,
                "input_fingerprints": {
                    "preflight_summary": {
                        "path": str(preflight),
                        "sha256": "0" * 64,
                    }
                },
                "preflight_artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
                },
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-publication-dry-run.json").exists()
    assert "evidence bundle preflight summary fingerprint mismatch" in (
        result.stderr + result.stdout
    )


def test_publication_dry_run_rejects_stale_github_ruleset_report_input_fingerprint(
    tmp_path: Path,
) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    preflight = _write_preflight_fixture(tmp_path)
    ruleset = tmp_path / "ruleset.json"
    proof = tmp_path / "proof.json"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    out_dir = tmp_path / "out"

    ruleset.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
                "checks": [{"name": "ruleset:active", "status": "pass"}],
            }
        ),
        encoding="utf-8",
    )
    proof.write_text('{"source_only":true}', encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    notes.write_text(_release_notes_text(_sha256(source)), encoding="utf-8")
    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "a" * 40,
                "preflight_ref_commit_sha": "a" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": _sha256(source),
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "github_ruleset_ok": True,
                "github_enforcement_claim_allowed": True,
                "github_ruleset_report": str(ruleset),
                "input_fingerprints": {
                    "preflight_summary": {
                        "path": str(preflight),
                        "sha256": _sha256(preflight),
                    },
                    "github_ruleset_report": {
                        "path": str(ruleset),
                        "sha256": "0" * 64,
                    },
                },
                "preflight_artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
                },
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-publication-dry-run.json").exists()
    assert "github ruleset report fingerprint mismatch" in (
        result.stderr + result.stdout
    )


@pytest.mark.parametrize(
    ("ruleset_payload", "expected_error"),
    [
        ({"ok": True}, "ruleset report without schema_version 1"),
        (
            {"schema_version": 1, "ok": True, "read_only": False},
            "ruleset report that is not read-only",
        ),
        (
            {"schema_version": 1, "read_only": True},
            "ruleset report without ok status",
        ),
    ],
)
def test_publication_dry_run_rejects_malformed_github_ruleset_report(
    tmp_path: Path,
    ruleset_payload: dict[str, object],
    expected_error: str,
) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    preflight = _write_preflight_fixture(tmp_path)
    ruleset = tmp_path / "ruleset.json"
    proof = tmp_path / "proof.json"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    out_dir = tmp_path / "out"

    ruleset.write_text(json.dumps(ruleset_payload), encoding="utf-8")
    proof.write_text('{"source_only":true}', encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    notes.write_text(_release_notes_text(_sha256(source)), encoding="utf-8")
    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "a" * 40,
                "preflight_ref_commit_sha": "a" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": _sha256(source),
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "github_ruleset_ok": True,
                "github_enforcement_claim_allowed": True,
                "github_ruleset_report": str(ruleset),
                "input_fingerprints": {
                    "preflight_summary": {
                        "path": str(preflight),
                        "sha256": _sha256(preflight),
                    },
                    "github_ruleset_report": {
                        "path": str(ruleset),
                        "sha256": _sha256(ruleset),
                    },
                },
                "preflight_artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
                },
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-publication-dry-run.json").exists()
    assert expected_error in (result.stderr + result.stdout)


@pytest.mark.parametrize(
    ("ruleset_payload", "expected_error"),
    [
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "repository": "example/fork",
                "branch": "main",
            },
            "ruleset report repository mismatch",
        ),
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "release",
            },
            "ruleset report branch mismatch",
        ),
    ],
)
def test_publication_dry_run_rejects_wrong_github_ruleset_report_target(
    tmp_path: Path,
    ruleset_payload: dict[str, object],
    expected_error: str,
) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    preflight = _write_preflight_fixture(tmp_path)
    ruleset = tmp_path / "ruleset.json"
    proof = tmp_path / "proof.json"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    out_dir = tmp_path / "out"

    ruleset.write_text(json.dumps(ruleset_payload), encoding="utf-8")
    proof.write_text('{"source_only":true}', encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    notes.write_text(_release_notes_text(_sha256(source)), encoding="utf-8")
    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "a" * 40,
                "preflight_ref_commit_sha": "a" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": _sha256(source),
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "github_ruleset_ok": True,
                "github_enforcement_claim_allowed": True,
                "github_ruleset_report": str(ruleset),
                "input_fingerprints": {
                    "preflight_summary": {
                        "path": str(preflight),
                        "sha256": _sha256(preflight),
                    },
                    "github_ruleset_report": {
                        "path": str(ruleset),
                        "sha256": _sha256(ruleset),
                    },
                },
                "preflight_artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
                },
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-publication-dry-run.json").exists()
    assert expected_error in (result.stderr + result.stdout)


@pytest.mark.parametrize(
    ("ruleset_payload", "expected_error"),
    [
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
            },
            "ruleset report ok status without checks",
        ),
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
                "checks": [{"name": "ruleset:active", "status": "fail"}],
            },
            "ruleset report ok status with failed checks",
        ),
    ],
)
def test_publication_dry_run_rejects_inconsistent_github_ruleset_report_ok_status(
    tmp_path: Path,
    ruleset_payload: dict[str, object],
    expected_error: str,
) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    preflight = _write_preflight_fixture(tmp_path)
    ruleset = tmp_path / "ruleset.json"
    proof = tmp_path / "proof.json"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    out_dir = tmp_path / "out"

    ruleset.write_text(json.dumps(ruleset_payload), encoding="utf-8")
    proof.write_text('{"source_only":true}', encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    notes.write_text(_release_notes_text(_sha256(source)), encoding="utf-8")
    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "a" * 40,
                "preflight_ref_commit_sha": "a" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": _sha256(source),
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "github_ruleset_ok": True,
                "github_enforcement_claim_allowed": True,
                "github_ruleset_report": str(ruleset),
                "input_fingerprints": {
                    "preflight_summary": {
                        "path": str(preflight),
                        "sha256": _sha256(preflight),
                    },
                    "github_ruleset_report": {
                        "path": str(ruleset),
                        "sha256": _sha256(ruleset),
                    },
                },
                "preflight_artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
                },
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-publication-dry-run.json").exists()
    assert expected_error in (result.stderr + result.stdout)


def test_publication_dry_run_rejects_evidence_without_preflight_artifact_fingerprints(
    tmp_path: Path,
) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    preflight = _write_preflight_fixture(tmp_path)
    out_dir = tmp_path / "out"

    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "a" * 40,
                "preflight_ref_commit_sha": "a" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": "b" * 64,
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": "build/windows-bundle-verifier/windows-bundle-verifier.json",
                "github_ruleset_ok": False,
                "github_enforcement_claim_allowed": False,
                "input_fingerprints": _preflight_input_fingerprints(preflight),
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    notes.write_text(
        "\n".join(
            [
                "# v9.9.9-source",
                "Source archive SHA-256: " + "b" * 64,
                "Source proof manifest: proof.json",
                "Verification date: 2026-06-14T00:00:00Z",
                "This is a source-only release.",
                "No APK or EXE binaries.",
                "No store release.",
                "No trusted Windows signing claim.",
                "No official POKROV backend, billing, admin, deployment, signing, or private release evidence.",
                "Release evidence is separate public evidence.",
                "scripts\\source-release-preflight.ps1",
                "scripts\\prepare-source-release.ps1",
                "scripts\\render-source-release-notes.ps1",
            ]
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-publication-dry-run.json").exists()
    assert "evidence bundle is missing preflight artifact fingerprints" in (
        result.stderr + result.stdout
    )


def test_publication_dry_run_rejects_stale_release_notes_artifact_fingerprint(
    tmp_path: Path,
) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    preflight = _write_preflight_fixture(tmp_path)
    proof = tmp_path / "proof.json"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    out_dir = tmp_path / "out"

    proof.write_text('{"source_only":true}', encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    notes.write_text(
        "\n".join(
            [
                "# v9.9.9-source",
                "Source archive SHA-256: " + _sha256(source),
                "Source proof manifest: proof.json",
                "Verification date: 2026-06-14T00:00:00Z",
                "This is a source-only release.",
                "No APK or EXE binaries.",
                "No store release.",
                "No trusted Windows signing claim.",
                "No official POKROV backend, billing, admin, deployment, signing, or private release evidence.",
                "Release evidence is separate public evidence.",
                "scripts\\source-release-preflight.ps1",
                "scripts\\prepare-source-release.ps1",
                "scripts\\render-source-release-notes.ps1",
            ]
        ),
        encoding="utf-8",
    )

    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "a" * 40,
                "preflight_ref_commit_sha": "a" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": _sha256(source),
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "github_ruleset_ok": False,
                "github_enforcement_claim_allowed": False,
                "input_fingerprints": _preflight_input_fingerprints(preflight),
                "preflight_artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": "0" * 64},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
                },
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-publication-dry-run.json").exists()
    assert "artifact fingerprint mismatch" in (result.stderr + result.stdout)


def test_publication_dry_run_rejects_evidence_commit_sha_mismatch(
    tmp_path: Path,
) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    preflight = _write_preflight_fixture(tmp_path)
    proof = tmp_path / "proof.json"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    out_dir = tmp_path / "out"

    proof.write_text('{"source_only":true}', encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    notes.write_text(
        "\n".join(
            [
                "# v9.9.9-source",
                "Source archive SHA-256: " + _sha256(source),
                "Source proof manifest: proof.json",
                "Verification date: 2026-06-14T00:00:00Z",
                "This is a source-only release.",
                "No APK or EXE binaries.",
                "No store release.",
                "No trusted Windows signing claim.",
                "No official POKROV backend, billing, admin, deployment, signing, or private release evidence.",
                "Release evidence is separate public evidence.",
                "scripts\\source-release-preflight.ps1",
                "scripts\\prepare-source-release.ps1",
                "scripts\\render-source-release-notes.ps1",
            ]
        ),
        encoding="utf-8",
    )
    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "b" * 40,
                "preflight_ref_commit_sha": "b" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": _sha256(source),
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "github_ruleset_ok": False,
                "github_enforcement_claim_allowed": False,
                "input_fingerprints": _preflight_input_fingerprints(preflight),
                "preflight_artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
                },
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-publication-dry-run.json").exists()
    assert "evidence commit SHA does not match preflight commit SHA" in (
        result.stderr + result.stdout
    )


def test_publication_dry_run_rejects_evidence_ref_commit_sha_mismatch(
    tmp_path: Path,
) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    preflight = _write_preflight_fixture(tmp_path)
    proof = tmp_path / "proof.json"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    out_dir = tmp_path / "out"

    proof.write_text('{"source_only":true}', encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    notes.write_text(
        "\n".join(
            [
                "# v9.9.9-source",
                "Source archive SHA-256: " + _sha256(source),
                "Source proof manifest: proof.json",
                "Verification date: 2026-06-14T00:00:00Z",
                "This is a source-only release.",
                "No APK or EXE binaries.",
                "No store release.",
                "No trusted Windows signing claim.",
                "No official POKROV backend, billing, admin, deployment, signing, or private release evidence.",
                "Release evidence is separate public evidence.",
                "scripts\\source-release-preflight.ps1",
                "scripts\\prepare-source-release.ps1",
                "scripts\\render-source-release-notes.ps1",
            ]
        ),
        encoding="utf-8",
    )
    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "a" * 40,
                "preflight_ref_commit_sha": "b" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": _sha256(source),
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "github_ruleset_ok": False,
                "github_enforcement_claim_allowed": False,
                "input_fingerprints": _preflight_input_fingerprints(preflight),
                "preflight_artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
                },
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-publication-dry-run.json").exists()
    assert "evidence preflight commit SHA does not match resolved ref commit SHA" in (
        result.stderr + result.stdout
    )


def test_publication_dry_run_rejects_evidence_without_windows_proof(
    tmp_path: Path,
) -> None:
    evidence = tmp_path / "evidence.json"
    notes = tmp_path / "release-notes.md"
    out_dir = tmp_path / "out"

    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
                "preflight_commit_sha": "a" * 40,
                "preflight_ref_commit_sha": "a" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "source_archive_sha256": "b" * 64,
                "github_ruleset_ok": False,
                "github_enforcement_claim_allowed": False,
                "release_boundary": {
                    "ships_apk": False,
                    "ships_exe": False,
                    "store_release": False,
                    "trusted_signing_claim": False,
                    "official_binary_claim": False,
                },
            }
        ),
        encoding="utf-8",
    )

    notes.write_text(
        "\n".join(
            [
                "# v9.9.9-source",
                "Source archive SHA-256: " + "b" * 64,
                "Source proof manifest: proof.json",
                "Verification date: 2026-06-14T00:00:00Z",
                "This is a source-only release.",
                "No APK or EXE binaries.",
                "No store release.",
                "No trusted Windows signing claim.",
                "No official POKROV backend, billing, admin, deployment, signing, or private release evidence.",
                "Release evidence is separate public evidence.",
                "scripts\\source-release-preflight.ps1",
                "scripts\\prepare-source-release.ps1",
                "scripts\\render-source-release-notes.ps1",
            ]
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "validate-source-release-publication.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-EvidenceBundlePath",
            str(evidence),
            "-ReleaseNotesPath",
            str(notes),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-publication-dry-run.json").exists()
    assert "windows_bundle_verifier_ok" in (result.stderr + result.stdout)


def test_publication_dry_run_docs_are_linked() -> None:
    docs = "\n".join(
        [
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("docs/RELEASE_POLICY.md"),
            _read("scripts/README.md"),
        ]
    )

    assert "validate-source-release-publication.ps1" in docs
    assert "publication dry-run" in docs


def test_validate_seed_knows_publication_dry_run() -> None:
    validator = _read("scripts/validate-seed.ps1")

    assert "config\\\\source-release-publication-dry-run.seed.json" in validator
    assert "scripts\\\\validate-source-release-publication.ps1" in validator
    assert "github_enforcement_claim_requires_bundle_approval" in validator
    assert "windows_bundle_verifier_claim_requires_bundle_proof" in validator
