from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def test_required_checks_seed_defines_ci_and_release_gate_policy() -> None:
    seed = _read_json("config/required-checks.seed.json")

    assert seed["workflow"] == ".github/workflows/ci.yml"
    assert seed["policy"]["pull_request_ci_required"] is True
    assert seed["policy"]["main_push_ci_required"] is True
    assert seed["policy"]["contents_read_permission_required"] is True
    assert seed["policy"]["source_release_preflight_smoke_required"] is True
    assert seed["policy"]["clean_clone_source_boundary_required"] is True
    assert seed["policy"]["flutter_analyze_required"] is True
    assert seed["policy"]["workspace_tests_required"] is True
    assert seed["policy"]["branch_protection_documented_not_claimed"] is True
    assert seed["policy"]["skip_test_commands_forbidden_for_public_release"] is True


def test_ci_workflow_contains_required_jobs_and_steps() -> None:
    seed = _read_json("config/required-checks.seed.json")
    workflow = _read(".github/workflows/ci.yml")

    assert "pull_request:" in workflow
    assert "contents: read" in workflow
    assert "- main" in workflow

    for job_name in seed["required_jobs"]:
        assert f"name: {job_name}" in workflow

    for step_name in seed["required_steps"]:
        assert f"name: {step_name}" in workflow


def test_required_checks_docs_do_not_overclaim_branch_protection() -> None:
    doc = _read("docs/REQUIRED_CHECKS.md")

    for phrase in (
        "not proof that GitHub branch protection settings are already enabled",
        "Source import and public tree checks",
        "Flutter analyze and tests",
        "contents",
        "CODEOWNERS review",
        "-SkipTestCommands",
        "must not be used for a public source release",
        "Green checks do not claim APK, EXE, store release, trusted signing",
    ):
        assert phrase in doc


def test_release_docs_link_required_checks_policy() -> None:
    docs = "\n".join(
        [
            _read("docs/RELEASE_POLICY.md"),
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("docs/README.md"),
        ]
    )

    assert "REQUIRED_CHECKS.md" in docs
    assert "config/required-checks.seed.json" in docs
    assert "GitHub check names" in docs


def test_validate_seed_knows_required_checks_policy() -> None:
    validator = _read("scripts/validate-seed.ps1")

    assert "config\\\\required-checks.seed.json" in validator
    assert "required_jobs" in validator
    assert "required_steps" in validator
    assert "branch_protection_documented_not_claimed" in validator
