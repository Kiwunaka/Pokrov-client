from __future__ import annotations

import hashlib
import json
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


def _git_head() -> str:
    return subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def _write_valid_preflight_fixture(tmp_path: Path) -> Path:
    proof = tmp_path / "proof.json"
    notes = tmp_path / "notes.md"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    preflight = tmp_path / "preflight.json"

    proof.write_text('{"source_only":true}', encoding="utf-8")
    notes.write_text("# v9.9.9-source\nThis is a source-only release.", encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    commit_sha = _git_head()
    preflight.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "generated_at": _fresh_input_generated_at(),
                "tag": "v9.9.9-source",
                "commit_sha": commit_sha,
                "ref_commit_sha": commit_sha,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "proof_manifest": str(proof),
                "release_notes": str(notes),
                "source_archive": str(source),
                "source_archive_sha256": _sha256(source),
                "artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
                },
            }
        ),
        encoding="utf-8",
    )
    return preflight


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
    assert seed["policy"]["requires_preflight_generated_at"] is True
    assert seed["policy"]["requires_preflight_generated_at_freshness"] is True
    assert seed["policy"]["requires_ruleset_report_input_fingerprint_when_present"] is True
    assert seed["policy"]["requires_ruleset_report_shape"] is True
    assert seed["policy"]["requires_ruleset_report_target"] is True
    assert seed["policy"]["requires_ruleset_report_ok_consistency"] is True
    assert seed["policy"]["requires_ruleset_report_checked_at"] is True
    assert seed["policy"]["requires_ruleset_report_freshness"] is True
    assert seed["policy"]["requires_ruleset_report_check_entry_shape"] is True
    assert seed["policy"]["requires_ruleset_report_required_status_checks"] is True
    assert (
        seed["policy"]["requires_ruleset_report_covered_required_status_checks"]
        is True
    )
    assert seed["policy"]["requires_preflight_artifact_fingerprints"] is True
    assert seed["policy"]["requires_preflight_artifact_fingerprint_integrity"] is True
    assert seed["policy"]["requires_preflight_commit_sha_consistency"] is True
    assert seed["policy"]["requires_preflight_ref_commit_sha_consistency"] is True

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
        "github_ruleset_report",
        "Assert-RulesetReportShape",
        "ruleset report without schema_version 1",
        "ruleset report that is not read-only",
        "ruleset report without ok status",
        "ruleset report without checked_at timestamp",
        "stale ruleset report checked_at timestamp",
        "ruleset report repository mismatch",
        "ruleset report branch mismatch",
        "ruleset report ok status without checks",
        "ruleset report ok status with failed checks",
        "ruleset report check entry shape mismatch",
        "ruleset report required status checks mismatch",
        "ruleset report covered required status checks mismatch",
        "preflight_artifact_fingerprints",
        "preflight_commit_sha",
        "preflight_ref_commit_sha",
        "preflight commit SHA does not match current HEAD",
        "preflight commit SHA does not match resolved ref commit SHA",
        "preflight summary is missing artifact fingerprints",
        "artifact fingerprint mismatch",
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
    proof = tmp_path / "proof.json"
    notes = tmp_path / "notes.md"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    out_dir = tmp_path / "out"

    proof.write_text('{"source_only":true}', encoding="utf-8")
    notes.write_text("# v9.9.9-source\nThis is a source-only release.", encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    commit_sha = _git_head()
    preflight.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "generated_at": _fresh_input_generated_at(),
                "tag": "v9.9.9-source",
                "commit_sha": commit_sha,
                "ref_commit_sha": commit_sha,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "proof_manifest": str(proof),
                "release_notes": str(notes),
                "source_archive": str(source),
                "source_archive_sha256": _sha256(source),
                "artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
                },
            }
        ),
        encoding="utf-8",
    )
    ruleset.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "ok": False,
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
    assert bundle["commit_sha"] == commit_sha
    assert bundle["preflight_commit_sha"] == commit_sha
    assert bundle["preflight_ref_commit_sha"] == commit_sha
    assert bundle["no_apk"] is True
    assert bundle["no_exe"] is True
    assert bundle["windows_bundle_verifier_ok"] is True
    assert bundle["windows_bundle_verifier_summary"].endswith(
        "windows-bundle-verifier.json"
    )
    assert bundle["source_archive"] == str(source)
    assert bundle["source_archive_sha256"] == _sha256(source)
    assert bundle["github_ruleset_ok"] is False
    assert bundle["github_enforcement_claim_allowed"] is False
    assert bundle["input_fingerprints"]["preflight_summary"]["sha256"] == _sha256(
        preflight
    )
    assert bundle["input_fingerprints"]["preflight_summary"]["path"] == str(
        preflight.resolve()
    )
    assert bundle["input_fingerprints"]["github_ruleset_report"]["sha256"] == _sha256(
        ruleset
    )
    assert bundle["input_fingerprints"]["github_ruleset_report"]["path"] == str(
        ruleset.resolve()
    )
    assert bundle["preflight_artifact_fingerprints"]["proof_manifest"][
        "sha256"
    ] == _sha256(proof)
    assert bundle["preflight_artifact_fingerprints"]["release_notes"][
        "sha256"
    ] == _sha256(notes)
    assert bundle["preflight_artifact_fingerprints"]["source_archive"][
        "sha256"
    ] == _sha256(source)
    assert bundle["preflight_artifact_fingerprints"][
        "windows_bundle_verifier_summary"
    ]["sha256"] == _sha256(windows)
    assert bundle["release_boundary"]["official_binary_claim"] is False


@pytest.mark.parametrize(
    ("generated_at", "expected_error"),
    [
        ("", "preflight summary without generated_at timestamp"),
        ("not-a-date", "preflight summary without parseable generated_at timestamp"),
        (
            _stale_input_generated_at(),
            "stale preflight summary generated_at timestamp",
        ),
        (
            _future_input_generated_at(),
            "stale preflight summary generated_at timestamp",
        ),
    ],
)
def test_release_evidence_bundle_rejects_unfresh_preflight_generated_at(
    tmp_path: Path, generated_at: str, expected_error: str
) -> None:
    preflight = _write_valid_preflight_fixture(tmp_path)
    preflight_payload = json.loads(preflight.read_text(encoding="utf-8"))
    preflight_payload["generated_at"] = generated_at
    preflight.write_text(json.dumps(preflight_payload), encoding="utf-8")
    out_dir = tmp_path / "out"

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
    assert expected_error in (result.stderr + result.stdout)


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
        (
            {
                "schema_version": 1,
                "ok": True,
                "read_only": True,
                "repository": "Kiwunaka/Pokrov-client",
                "branch": "main",
                "required_status_checks": REQUIRED_STATUS_CHECKS,
            },
            "ruleset report without checked_at timestamp",
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
            "stale ruleset report checked_at timestamp",
        ),
    ],
)
def test_release_evidence_bundle_rejects_malformed_ruleset_report(
    tmp_path: Path,
    ruleset_payload: dict[str, object],
    expected_error: str,
) -> None:
    preflight = _write_valid_preflight_fixture(tmp_path)
    ruleset = tmp_path / "ruleset.json"
    out_dir = tmp_path / "out"

    ruleset.write_text(json.dumps(ruleset_payload), encoding="utf-8")

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
            "-RulesetReportPath",
            str(ruleset),
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
    assert expected_error in (result.stderr + result.stdout)


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
            "ruleset report repository mismatch",
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
            "ruleset report branch mismatch",
        ),
    ],
)
def test_release_evidence_bundle_rejects_wrong_ruleset_report_target(
    tmp_path: Path,
    ruleset_payload: dict[str, object],
    expected_error: str,
) -> None:
    preflight = _write_valid_preflight_fixture(tmp_path)
    ruleset = tmp_path / "ruleset.json"
    out_dir = tmp_path / "out"

    ruleset.write_text(json.dumps(ruleset_payload), encoding="utf-8")

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
            "-RulesetReportPath",
            str(ruleset),
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
    assert expected_error in (result.stderr + result.stdout)


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
            "ruleset report ok status without checks",
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
            "ruleset report check entry shape mismatch",
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
            "ruleset report ok status with failed checks",
        ),
    ],
)
def test_release_evidence_bundle_rejects_inconsistent_ruleset_report_ok_status(
    tmp_path: Path,
    ruleset_payload: dict[str, object],
    expected_error: str,
) -> None:
    preflight = _write_valid_preflight_fixture(tmp_path)
    ruleset = tmp_path / "ruleset.json"
    out_dir = tmp_path / "out"

    ruleset.write_text(json.dumps(ruleset_payload), encoding="utf-8")

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
            "-RulesetReportPath",
            str(ruleset),
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
    assert expected_error in (result.stderr + result.stdout)


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
def test_release_evidence_bundle_rejects_ruleset_report_required_status_check_mismatch(
    tmp_path: Path,
    required_status_checks: list[str],
) -> None:
    preflight = _write_valid_preflight_fixture(tmp_path)
    ruleset = tmp_path / "ruleset.json"
    out_dir = tmp_path / "out"

    ruleset.write_text(
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
            "-RulesetReportPath",
            str(ruleset),
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
    assert "ruleset report required status checks mismatch" in (
        result.stderr + result.stdout
    )


def test_release_evidence_bundle_rejects_ruleset_report_covered_required_status_check_mismatch(
    tmp_path: Path,
) -> None:
    preflight = _write_valid_preflight_fixture(tmp_path)
    ruleset = tmp_path / "ruleset.json"
    out_dir = tmp_path / "out"

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
                "covered_required_status_checks": REQUIRED_STATUS_CHECKS[:-1],
                "checks": REQUIRED_RULESET_CHECKS,
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
            "-RulesetReportPath",
            str(ruleset),
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
    assert "ruleset report covered required status checks mismatch" in (
        result.stderr + result.stdout
    )


def test_release_evidence_bundle_rejects_preflight_without_artifact_fingerprints(
    tmp_path: Path,
) -> None:
    preflight = tmp_path / "preflight.json"
    out_dir = tmp_path / "out"

    preflight.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "generated_at": _fresh_input_generated_at(),
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
    assert "preflight summary is missing artifact fingerprints" in (
        result.stderr + result.stdout
    )


def test_release_evidence_bundle_rejects_stale_preflight_artifact_fingerprint(
    tmp_path: Path,
) -> None:
    proof = tmp_path / "proof.json"
    notes = tmp_path / "notes.md"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    preflight = tmp_path / "preflight.json"
    out_dir = tmp_path / "out"

    proof.write_text('{"source_only":true}', encoding="utf-8")
    notes.write_text("# v9.9.9-source\nThis is a source-only release.", encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")

    preflight.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "generated_at": _fresh_input_generated_at(),
                "tag": "v9.9.9-source",
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "proof_manifest": str(proof),
                "release_notes": str(notes),
                "source_archive": str(source),
                "source_archive_sha256": _sha256(source),
                "artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": "0" * 64},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
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
    assert "artifact fingerprint mismatch" in (result.stderr + result.stdout)


def test_release_evidence_bundle_rejects_preflight_commit_sha_mismatch(
    tmp_path: Path,
) -> None:
    proof = tmp_path / "proof.json"
    notes = tmp_path / "notes.md"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    preflight = tmp_path / "preflight.json"
    out_dir = tmp_path / "out"

    proof.write_text('{"source_only":true}', encoding="utf-8")
    notes.write_text("# v9.9.9-source\nThis is a source-only release.", encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")

    preflight.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "generated_at": _fresh_input_generated_at(),
                "tag": "v9.9.9-source",
                "commit_sha": "0" * 40,
                "ref_commit_sha": "0" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "proof_manifest": str(proof),
                "release_notes": str(notes),
                "source_archive": str(source),
                "source_archive_sha256": _sha256(source),
                "artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
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
    assert "preflight commit SHA does not match current HEAD" in (
        result.stderr + result.stdout
    )


def test_release_evidence_bundle_rejects_preflight_ref_commit_sha_mismatch(
    tmp_path: Path,
) -> None:
    proof = tmp_path / "proof.json"
    notes = tmp_path / "notes.md"
    source = tmp_path / "source.zip"
    windows = tmp_path / "windows-bundle-verifier.json"
    preflight = tmp_path / "preflight.json"
    out_dir = tmp_path / "out"

    proof.write_text('{"source_only":true}', encoding="utf-8")
    notes.write_text("# v9.9.9-source\nThis is a source-only release.", encoding="utf-8")
    source.write_bytes(b"source archive")
    windows.write_text('{"windows_bundle_ok":true}', encoding="utf-8")
    commit_sha = _git_head()

    preflight.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "generated_at": _fresh_input_generated_at(),
                "tag": "v9.9.9-source",
                "commit_sha": commit_sha,
                "ref_commit_sha": "0" * 40,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
                "windows_bundle_verifier_ok": True,
                "windows_bundle_verifier_summary": str(windows),
                "proof_manifest": str(proof),
                "release_notes": str(notes),
                "source_archive": str(source),
                "source_archive_sha256": _sha256(source),
                "artifact_fingerprints": {
                    "proof_manifest": {"path": str(proof), "sha256": _sha256(proof)},
                    "release_notes": {"path": str(notes), "sha256": _sha256(notes)},
                    "source_archive": {"path": str(source), "sha256": _sha256(source)},
                    "windows_bundle_verifier_summary": {
                        "path": str(windows),
                        "sha256": _sha256(windows),
                    },
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
    assert "preflight commit SHA does not match resolved ref commit SHA" in (
        result.stderr + result.stdout
    )


def test_release_evidence_bundle_rejects_preflight_without_windows_proof(
    tmp_path: Path,
) -> None:
    preflight = tmp_path / "preflight.json"
    out_dir = tmp_path / "out"

    preflight.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "generated_at": _fresh_input_generated_at(),
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
