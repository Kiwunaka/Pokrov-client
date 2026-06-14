from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def test_docs_index_routes_first_steps_users_operators_and_maintainers() -> None:
    text = _read("docs/README.md")

    for phrase in (
        "Build from source",
        "TROUBLESHOOTING.md",
        "OPEN_SOURCE_SCOPE.md",
        "PRODUCT_VARIANTS.md",
        "CLIENT_PRODUCT_TRACKS.md",
        "FREE_VPN_CATALOG_GATE.md",
        "OPERATOR_INTEGRATION.md",
        "ENTERPRISE.md",
        "operator/openapi.yaml",
        "WHITE_LABEL_BRANDING.md",
        "RELEASE_POLICY.md",
        "RELEASE_CHECKLIST.md",
        "releases/SOURCE_RELEASE_TEMPLATE.md",
        "releases/source-readiness-v0.2-v0.3.md",
        "../CHANGELOG.md",
        "../SECURITY.md",
        "../SUPPORT.md",
    ):
        assert phrase in text


def test_docs_index_mentions_read_only_contributor_doctor() -> None:
    text = _read("docs/README.md")

    assert "scripts\\doctor.ps1" in text
    assert "read-only" in text
    assert "does not install" in text
    assert "does not" in text
    assert "Troubleshooting" in text
