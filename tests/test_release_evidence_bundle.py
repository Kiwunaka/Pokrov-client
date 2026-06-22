from __future__ import annotations

import hashlib
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def test_release_evidence_bundle_seed_defines_source_only_policy() -> None:
    seed = _read_json("config/release-evidence-bundle.seed.json")

    assert seed["script"] == "scripts/prepare-release-evidence-bundle.ps1"
    assert seed["default_output_dir"] == "build/release-evidence"
    assert seed["policy"]["source_only_boundary_required"] is True
    assert seed["policy"]["no_publish_side_effects"] is True
    assert seed["policy"]["writes_only_ignored_build_output"] is True
    assert seed["policy"]["ruleset_report_may_be_failing"] is True
    assert seed["policy"]["failing_ruleset_report_blocks_enforcement_claims"] is True
    assert seed["policy"]["does_not_replace_full_preflight"] is True
    assert seed["policy"]["windows_bundle_verifier_required"] is True
    assert seed["policy"]["requires_input_fingerprints"] is True

    for flag in (
        "source_only",
        "no_apk",
        "no_exe",
        "no_store_release",
        "no_trusted_signing_claim",
        "windows_bundle_verifier_ok",
    ):
        assert flag in seed["required_summary_flags"]


def test_release_evidence_bundle_script_preserves_claim_boundaries() -> None:
    script = _read("scripts/prepare-release-evidence-bundle.ps1")

    for phrase in (
        "Assert-SourceOnlySummary",
        "check-github-ruleset.ps1 -ReportOnly -Json",
        "github_enforcement_claim_allowed",
        "ships_apk = $false",
        "ships_exe = $false",
        "store_release = $false",
        "trusted_signing_claim = $false",
        "official_binary_claim = $false",
        "windows_bundle_verifier_ok",
        "windows_bundle_verifier_summary",
        "input_fingerprints",
        "SHA256",
        "ComputeHash",
        "build\\release-evidence",
    ):
        assert phrase in script

    for forbidden in (
        "gh release create",
        "git push",
        "-X POST",
        "-X PATCH",
        "-X PUT",
        "-X DELETE",
    ):
        assert forbidden not in script


def test_release_evidence_bundle_script_writes_bundle_from_fixture(tmp_path: Path) -> None:
    preflight = tmp_path / "preflight.json"
    ruleset = tmp_path / "ruleset.json"
    out_dir = tmp_path / "out"

    preflight.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": "build/windows-bundle-verifier/windows-bundle-verifier.json",
                "proof_manifest": "proof.json",
                "release_notes": "notes.md",
                "source_archive_sha256": "a" * 64,
            }
        ),
        encoding="utf-8",
    )
    ruleset.write_text(
        json.dumps({"schema_version": 1, "ok": False, "read_only": True}),
        encoding="utf-8",
    )

    subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "prepare-release-evidence-bundle.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-PreflightSummaryPath",
            str(preflight),
            "-RulesetReportPath",
            str(ruleset),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )

    bundle = json.loads((out_dir / "v9.9.9-source-release-evidence.json").read_text())
    assert bundle["source_only"] is True
    assert bundle["no_apk"] is True
    assert bundle["no_exe"] is True
    assert bundle["windows_bundle_verifier_ok"] is True
    assert bundle["windows_bundle_verifier_summary"].endswith(
        "windows-bundle-verifier.json"
    )
    assert bundle["github_ruleset_ok"] is False
    assert bundle["github_enforcement_claim_allowed"] is False
    assert bundle["input_fingerprints"]["preflight_summary"]["sha256"] == _sha256(
        preflight
    )
    assert bundle["input_fingerprints"]["preflight_summary"]["path"] == str(
        preflight.resolve()
    )
    assert bundle["release_boundary"]["official_binary_claim"] is False


def test_release_evidence_bundle_rejects_preflight_without_windows_proof(
    tmp_path: Path,
) -> None:
    preflight = tmp_path / "preflight.json"
    out_dir = tmp_path / "out"

    preflight.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.9-source",
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "proof_manifest": "proof.json",
                "release_notes": "notes.md",
                "source_archive_sha256": "a" * 64,
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
            str(ROOT / "scripts" / "prepare-release-evidence-bundle.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-PreflightSummaryPath",
            str(preflight),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "v9.9.9-source-release-evidence.json").exists()
    assert "windows_bundle_verifier_ok" in (result.stderr + result.stdout)


def test_release_docs_link_release_evidence_bundle() -> None:
    docs = "\n".join(
        [
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("docs/RELEASE_POLICY.md"),
            _read("scripts/README.md"),
        ]
    )

    assert "prepare-release-evidence-bundle.ps1" in docs
    assert "release evidence bundle" in docs


def test_validate_seed_knows_release_evidence_bundle() -> None:
    validator = _read("scripts/validate-seed.ps1")

    assert "config\\\\release-evidence-bundle.seed.json" in validator
    assert "scripts\\\\prepare-release-evidence-bundle.ps1" in validator
    assert "failing_ruleset_report_blocks_enforcement_claims" in validator
