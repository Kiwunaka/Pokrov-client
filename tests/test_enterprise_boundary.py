from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def test_enterprise_boundary_seed_keeps_gpl_and_no_default_commercial_license() -> None:
    seed = _read_json("config/enterprise-boundary.seed.json")

    assert seed["doc"] == "docs/ENTERPRISE.md"
    assert seed["current_public_license"] == "GPL-3.0-only"
    assert seed["policy"]["does_not_change_license"] is True
    assert seed["policy"]["not_legal_advice"] is True
    assert seed["policy"]["no_commercial_license_offered_by_default"] is True
    assert seed["policy"]["dual_license_requires_owner_decision"] is True
    assert seed["policy"]["gpl_source_obligations_not_waived"] is True
    assert "operator builds are official POKROV builds" in seed["forbidden_claims"]


def test_enterprise_boundary_doc_defines_operator_and_paid_service_boundaries() -> None:
    text = _read("docs/ENTERPRISE.md")

    for phrase in (
        "This is not legal advice",
        "does not change [LICENSE](../LICENSE)",
        "does not waive GPLv3 obligations",
        "does not offer a commercial license by default",
        "official POKROV backend",
        "What Operators Bring",
        "Operator builds are not official POKROV builds",
        "Paid Work Around The Client",
        "Dual license: possible only after an explicit owner decision",
        "No dual license is offered by default",
        "Before Distributing A Fork",
        "source-compliance path",
    ):
        assert phrase in text


def test_enterprise_boundary_is_linked_from_public_docs() -> None:
    docs = "\n".join(
        [
            _read("README.md"),
            _read("README.en.md"),
            _read("README.ru.md"),
            _read("docs/README.md"),
            _read("docs/OPERATOR_INTEGRATION.md"),
            _read("docs/OPEN_SOURCE_SCOPE.md"),
        ]
    )

    assert "docs/ENTERPRISE.md" in docs
    assert "Enterprise boundary" in docs
    assert "commercial license" in docs


def test_license_file_remains_gplv3() -> None:
    license_text = _read("LICENSE")

    assert "GNU GENERAL PUBLIC LICENSE" in license_text
    assert "Version 3, 29 June 2007" in license_text


def test_validate_seed_knows_enterprise_boundary() -> None:
    validator = _read("scripts/validate-seed.ps1")

    assert "config\\\\enterprise-boundary.seed.json" in validator
    assert "docs\\\\ENTERPRISE.md" in validator
    assert "dual_license_requires_owner_decision" in validator
