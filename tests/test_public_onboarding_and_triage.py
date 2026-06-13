from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _issue_template_names() -> list[str]:
    return [
        path.name
        for path in sorted((ROOT / ".github" / "ISSUE_TEMPLATE").glob("*.yml"))
        if path.name != "config.yml"
    ]


def test_readmes_explain_the_two_public_tracks_and_official_boundary() -> None:
    for relative_path in ("README.md", "README.en.md", "README.ru.md"):
        text = _read(relative_path)

        assert "Personal Key Client" in text
        assert "Operator / Company Client" in text
        assert "POKROV Service Mode" in text
        assert "no POKROV API calls by default" in text
        assert "does not provide POKROV nodes or a default free service" in text
        assert "not official POKROV builds" in text
        assert "vless://" in text
        assert "subscription URL" in text
        assert "QR" in text
        assert "PR green" not in text


def test_track_docs_keep_first_run_paths_for_people_and_operators() -> None:
    docs = "\n".join(
        [
            _read("docs/PRODUCT_VARIANTS.md"),
            _read("docs/CLIENT_PRODUCT_TRACKS.md"),
            _read("docs/BUILD_FROM_SOURCE.md"),
            _read("docs/OPERATOR_INTEGRATION.md"),
        ]
    )

    for phrase in (
        "First-run path for ordinary users",
        "choose the `community` variant",
        "paste a `vless://`, `trojan://`, `ss://`, or `vmess://` key",
        "scan a QR code",
        "add a subscription URL",
        "First-run path for operators",
        "run the local fixture backend",
        "export white-label color tokens",
        "implement the minimal managed-profile contract",
    ):
        assert phrase in docs

    assert "OS background refresh is not claimed" in docs
    assert "operators own signing, support, backend compatibility" in docs
    assert 'Optional Third-Party Public Config Catalog ("Free VPN" UI Label)' in docs
    assert "operator-managed profile delivery, plus optional local user-owned" in docs


def test_support_and_security_define_public_tracks_and_private_reporting() -> None:
    support = _read("SUPPORT.md")
    security = _read("SECURITY.md")

    for phrase in (
        "Personal Key / Community Client",
        "Operator / Company Client",
        "Official POKROV Service Mode",
        "Do not paste keys, QR payloads, subscription URLs",
    ):
        assert phrase in support

    for phrase in (
        "Supported Versions",
        "source-only tags",
        "Unsupported Or Out Of Scope",
        "Private Reporting",
        "Coordinated Disclosure",
        "Do not open a public issue",
    ):
        assert phrase in security

    assert "public third-party config feeds" in security
    assert "official POKROV backend" in security


def test_issue_templates_collect_track_variant_and_redaction_context() -> None:
    required_track_options = (
        "Personal Key / Community Client",
        "Operator / Company Client",
        "Official POKROV Service Mode",
        "Repository docs/process",
    )

    for name in _issue_template_names():
        text = _read(f".github/ISSUE_TEMPLATE/{name}")

        assert "id: track" in text, name
        assert "label: Track / variant" in text, name
        for option in required_track_options:
            assert option in text, name

        assert "Do not include secrets" in text or "Do not paste secrets" in text, name
        assert "Do not report vulnerabilities here" in text, name
        assert "QR payloads" in text, name
        assert "subscription URLs" in text, name


def test_pull_request_template_guards_tracks_release_claims_and_catalog() -> None:
    text = _read(".github/PULL_REQUEST_TEMPLATE.md")

    for phrase in (
        "Track / variant",
        "Personal Key / Community Client",
        "Operator / Company Client",
        "Official POKROV Service Mode",
        "no secrets, tokens, personal links, QR payloads, subscription URLs",
        "does not imply official POKROV service claims",
        "third-party public config catalog behavior disabled",
        "source-only release notes",
    ):
        assert phrase in text
