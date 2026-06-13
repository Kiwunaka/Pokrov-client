from __future__ import annotations

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _issue_template_names() -> list[str]:
    return [
        path.name
        for path in sorted((ROOT / ".github" / "ISSUE_TEMPLATE").glob("*.yml"))
        if path.name != "config.yml"
    ]


def _github_labels() -> set[str]:
    text = _read(".github/labels.yml")
    return set(re.findall(r"^- name: (.+)$", text, flags=re.MULTILINE))


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
    template_names = set(_issue_template_names())
    assert {
        "bug_report.yml",
        "build_problem.yml",
        "documentation.yml",
        "feature_request.yml",
        "operator_integration_question.yml",
        "profile_import_problem.yml",
        "security_redirect.yml",
    }.issubset(template_names)

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


def test_specialized_issue_templates_route_import_operator_and_security() -> None:
    import_template = _read(".github/ISSUE_TEMPLATE/profile_import_problem.yml")
    operator_template = _read(".github/ISSUE_TEMPLATE/operator_integration_question.yml")
    security_template = _read(".github/ISSUE_TEMPLATE/security_redirect.yml")
    config = _read(".github/ISSUE_TEMPLATE/config.yml")

    for phrase in (
        "Pasted single key",
        "QR scan",
        "Subscription URL",
        "Third-party public config catalog",
        "whether old imported profiles were preserved",
    ):
        assert phrase in import_template

    for phrase in (
        "Managed profile API",
        "White-label branding",
        "operators bring their own backend, billing, support",
        "not asking for private POKROV backend",
    ):
        assert phrase in operator_template

    for phrase in (
        "Do not open a public issue for vulnerabilities",
        "GitHub private vulnerability reporting",
        "security-private",
    ):
        assert phrase in security_template

    assert "https://github.com/Kiwunaka/Pokrov-client/security/policy" in config


def test_github_label_catalog_covers_public_triage_routes() -> None:
    labels = _github_labels()
    triage_doc = _read("docs/GITHUB_TRIAGE.md")

    required_labels = {
        "bug",
        "build",
        "docs",
        "enhancement",
        "import",
        "operator",
        "community",
        "android",
        "windows",
        "parser",
        "runtime",
        "release",
        "source-boundary",
        "security-private",
        "help wanted",
        "good first issue",
    }
    assert required_labels.issubset(labels)

    for name in _issue_template_names():
        text = _read(f".github/ISSUE_TEMPLATE/{name}")
        template_labels = re.findall(r'labels: \["([^"]+)"\]', text)
        assert template_labels, name
        for label in template_labels:
            assert label in labels, f"{name} uses unknown label {label}"

    for phrase in (
        "canonical label catalog",
        "Do not use labels to imply official POKROV support",
        "Keep `security-private` as a redirect label",
        "Do not apply `good first issue` until the task is safe",
        "private POKROV backend, signing, billing, deployment",
    ):
        assert phrase in triage_doc


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


def test_community_variant_keeps_free_catalog_import_flag_disabled() -> None:
    text = _read("config/variants/community-client.seed.json")

    assert '"manual_import_build_define": "OPEN_CLIENT_ENABLE_FREE_CATALOG"' in text
    assert '"manual_import_default": false' in text
    assert '"OPEN_CLIENT_ENABLE_FREE_CATALOG": "false"' in text
