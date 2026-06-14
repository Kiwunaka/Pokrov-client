from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def _codeowner_routes() -> dict[str, list[str]]:
    routes: dict[str, list[str]] = {}
    for line in _read(".github/CODEOWNERS").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        pattern, *owners = stripped.split()
        routes[pattern] = owners
    return routes


def test_codeowners_seed_defines_review_routing_policy() -> None:
    seed = _read_json("config/codeowners-review.seed.json")

    assert seed["codeowners_path"] == ".github/CODEOWNERS"
    assert seed["policy"]["maintainer_led_until_broader_governance"] is True
    assert seed["policy"]["default_owner_required"] is True
    assert seed["policy"]["security_and_release_routes_required"] is True
    assert seed["policy"]["android_and_windows_routes_required"] is True
    assert seed["policy"]["operator_contract_routes_required"] is True
    assert seed["policy"]["source_only_boundary_routes_required"] is True
    assert seed["allowed_owners"] == ["@Kiwunaka"]


def test_codeowners_contains_every_seed_required_route() -> None:
    seed = _read_json("config/codeowners-review.seed.json")
    routes = _codeowner_routes()

    for route in seed["required_routes"]:
        assert route["pattern"] in routes
        assert routes[route["pattern"]] == [route["owner"]]

    assert routes["*"] == ["@Kiwunaka"]


def test_codeowners_routes_sensitive_public_source_areas() -> None:
    routes = _codeowner_routes()

    for pattern in (
        "/.github/workflows/",
        "/.github/ISSUE_TEMPLATE/",
        "/SECURITY.md",
        "/docs/releases/",
        "/docs/operator/",
        "/config/",
        "/scripts/",
        "/tools/source_import/",
        "/apps/android_shell/",
        "/apps/windows_shell/",
        "/packages/app_shell/",
        "/packages/runtime_engine/",
        "/assets/",
    ):
        assert routes[pattern] == ["@Kiwunaka"]


def test_codeowners_docs_explain_review_routing_without_release_claims() -> None:
    codeowners = _read(".github/CODEOWNERS")
    docs = "\n".join([_read("docs/GITHUB_TRIAGE.md"), _read("docs/GOVERNANCE.md")])

    for phrase in (
        "Source-only public review routing",
        "security intake",
        "runtime artifacts",
        "operator contracts",
    ):
        assert phrase in codeowners

    for phrase in (
        "CODEOWNERS",
        "config/codeowners-review.seed.json",
        "maintainer-led",
        "not a guarantee",
        "official POKROV build",
    ):
        assert phrase in docs


def test_validate_seed_knows_codeowners_review_policy() -> None:
    validator = _read("scripts/validate-seed.ps1")

    assert "config\\\\codeowners-review.seed.json" in validator
    assert ".github\\\\CODEOWNERS" in validator
    assert "maintainer_led_until_broader_governance" in validator
    assert "required_routes" in validator
