from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def test_github_ruleset_seed_defines_manual_enforcement_contract() -> None:
    seed = _read_json("config/github-ruleset.seed.json")

    assert seed["mode"] == "setup_guidance_not_remote_enforcement"
    assert seed["docs"] == "docs/GITHUB_RULESET_SETUP.md"
    assert seed["verifier_script"] == "scripts/check-github-ruleset.ps1"
    assert seed["target_branches"] == ["main"]
    assert seed["policy"]["repository_ruleset_preferred"] is True
    assert seed["policy"]["branch_protection_fallback_supported"] is True
    assert seed["policy"]["remote_enforcement_not_claimed"] is True
    assert seed["policy"]["pull_request_required"] is True
    assert seed["policy"]["required_status_checks_required"] is True
    assert seed["policy"]["codeowners_review_required"] is True
    assert seed["policy"]["conversation_resolution_required"] is True
    assert seed["policy"]["block_force_pushes_required"] is True
    assert seed["policy"]["block_branch_deletion_required"] is True
    assert seed["policy"]["bypass_must_be_explicit_and_minimal"] is True
    assert seed["policy"]["verifier_is_read_only"] is True
    assert seed["policy"]["verifier_report_only_supported"] is True
    assert seed["policy"]["verifier_not_required_in_ci_until_remote_settings_exist"] is True
    assert seed["policy"]["verifier_reports_checked_at"] is True
    assert seed["policy"]["verifier_reports_covered_required_status_checks"] is True


def test_github_ruleset_required_checks_match_required_checks_seed() -> None:
    ruleset = _read_json("config/github-ruleset.seed.json")
    required_checks = _read_json("config/required-checks.seed.json")

    assert ruleset["required_status_checks"] == required_checks["required_jobs"]


def test_github_ruleset_docs_avoid_remote_enforcement_claims() -> None:
    doc = _read("docs/GITHUB_RULESET_SETUP.md")

    for phrase in (
        "not proof that remote GitHub settings are already active",
        "scripts/check-github-ruleset.ps1",
        "does not create, edit, or delete GitHub settings",
        "repository ruleset or branch protection is active for `main`",
        "required status checks exactly match `config/required-checks.seed.json`",
        "CODEOWNERS review is required",
        "conversation resolution before merge",
        "blocked force pushes",
        "blocked branch deletion",
        "a test pull request without required checks cannot be merged",
        "GitHub ruleset or branch protection settings do not prove APK, EXE, store release, trusted signing",
    ):
        assert phrase in doc


def test_release_and_governance_docs_link_github_ruleset_setup() -> None:
    docs = "\n".join(
        [
            _read("docs/README.md"),
            _read("docs/REQUIRED_CHECKS.md"),
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("docs/GOVERNANCE.md"),
        ]
    )

    assert "GITHUB_RULESET_SETUP.md" in docs
    assert "config/github-ruleset.seed.json" in docs
    assert "scripts/check-github-ruleset.ps1" in docs
    assert "not proof" in docs


def test_github_ruleset_verifier_script_is_read_only() -> None:
    script = _read("scripts/check-github-ruleset.ps1")
    docs = _read("scripts/README.md")

    for phrase in (
        "gh api",
        "ReportOnly",
        "read_only",
        "checked_at",
        "required_status_checks",
        "covered_required_status_checks",
        "coveredRequiredChecks",
        "branch_protection",
        "ruleset",
    ):
        assert phrase in script

    for forbidden in (
        "-X POST",
        "-X PATCH",
        "-X PUT",
        "-X DELETE",
        "gh repo edit",
        "gh ruleset",
        "Invoke-RestMethod -Method Post",
        "Invoke-RestMethod -Method Patch",
        "Invoke-RestMethod -Method Put",
        "Invoke-RestMethod -Method Delete",
    ):
        assert forbidden not in script

    assert "check-github-ruleset.ps1" in docs
    assert "read-only" in docs
    assert "-ReportOnly -Json" in docs


def test_validate_seed_knows_github_ruleset_setup() -> None:
    validator = _read("scripts/validate-seed.ps1")

    assert "config\\\\github-ruleset.seed.json" in validator
    assert "scripts\\\\check-github-ruleset.ps1" in validator
    assert "GITHUB_RULESET_SETUP.md" in validator
    assert "required_status_checks" in validator
    assert "verifier_reports_checked_at" in validator
    assert "covered_required_status_checks" in validator
    assert "remote_enforcement_not_claimed" in validator
    assert "verifier_is_read_only" in validator
