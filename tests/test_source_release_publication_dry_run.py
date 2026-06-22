from __future__ import annotations

import json
import hashlib
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


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
        "evidence bundle is missing input fingerprints",
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
    out_dir = tmp_path / "out"

    evidence.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "commit_sha": "a" * 40,
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
                "input_fingerprints": {
                    "preflight_summary": {
                        "path": "build/source-release-preflight/v9.9.9-source/preflight.json",
                        "sha256": "e" * 64,
                    }
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
    ] == "e" * 64
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
