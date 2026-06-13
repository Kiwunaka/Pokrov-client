from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def test_security_intake_seed_defines_private_reporting_boundary() -> None:
    intake = _read_json("config/security-intake.seed.json")
    policy = intake["policy"]

    assert policy["public_vulnerability_issues_allowed"] is False
    assert policy["blank_issues_enabled"] is False
    assert (
        policy["private_security_policy_url"]
        == "https://github.com/Kiwunaka/Pokrov-client/security/policy"
    )
    assert policy["telegram_support_url"] == "https://t.me/pokrov_supportbot"
    assert policy["security_redirect_label"] == "security-private"
    assert policy["public_issue_action"] == "close_or_redact_and_redirect"

    reporting_paths = {path["id"]: path for path in intake["private_reporting_paths"]}
    assert reporting_paths["github-private-vulnerability-reporting"]["preferred"] is True
    assert reporting_paths["telegram-support"]["preferred"] is False

    forbidden = set(intake["forbidden_public_content"])
    for phrase in (
        "secrets",
        "account tokens",
        "QR payloads",
        "subscription URLs",
        "personal connection links",
        "private backend details",
        "exploit steps",
        "signing material",
    ):
        assert phrase in forbidden


def test_security_intake_seed_preserves_scope_and_source_release_claims() -> None:
    intake = _read_json("config/security-intake.seed.json")

    for phrase in (
        "public client source code",
        "public source release process",
        "operator fixture and OpenAPI contracts",
        "Android and Windows host source",
    ):
        assert phrase in intake["supported_scope"]

    out_of_scope = "\n".join(intake["out_of_scope"])
    for phrase in (
        "official backend, billing, admin, infrastructure",
        "private operator backends",
        "third-party public config feed speed, privacy, uptime, safety",
        "exploit steps",
    ):
        assert phrase in out_of_scope

    boundary = intake["release_claim_boundary"]
    assert boundary["source_only_repository"] is True
    for field in (
        "ships_apk",
        "ships_exe",
        "store_release",
        "trusted_signing_claim",
        "official_binary_claim",
    ):
        assert boundary[field] is False
    assert boundary["require_public_evidence_for_binary_claims"] is True


def test_security_docs_and_templates_match_security_intake_seed() -> None:
    intake = _read_json("config/security-intake.seed.json")
    security = _read("SECURITY.md")
    support = _read("SUPPORT.md")
    config = _read(".github/ISSUE_TEMPLATE/config.yml")
    redirect = _read(".github/ISSUE_TEMPLATE/security_redirect.yml")
    labels = _read(".github/labels.yml")
    triage = _read("docs/GITHUB_TRIAGE.md")

    assert "config/security-intake.seed.json" in security
    assert "blank_issues_enabled: false" in config
    assert intake["policy"]["private_security_policy_url"] in config
    assert intake["policy"]["private_security_policy_url"] in redirect
    assert f'labels: ["{intake["policy"]["security_redirect_label"]}"]' in redirect
    assert re.search(r"^- name: security-private$", labels, flags=re.MULTILINE)

    for text in (security, support, redirect, triage):
        assert "Do not open" in text or "Do not discuss" in text
        for phrase in (
            "secrets",
            "QR payloads",
            "subscription URLs",
            "private backend",
        ):
            assert phrase in text

    assert "not a public investigation lane" in triage
    assert "vulnerability details" in redirect
    assert "GitHub private vulnerability reporting" in redirect


def test_validate_seed_knows_security_intake_manifest() -> None:
    validator = _read("scripts/validate-seed.ps1")

    assert "config\\\\security-intake.seed.json" in validator
    assert "public_vulnerability_issues_allowed" in validator
    assert "blank_issues_enabled" in validator
    assert "release_claim_boundary" in validator
