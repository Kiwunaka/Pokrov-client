from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read_json(relative_path: str) -> dict:
    return json.loads((ROOT / relative_path).read_text(encoding="utf-8"))


def test_diagnostics_export_policy_is_privacy_first() -> None:
    policy = _read_json("config/diagnostics-export-policy.seed.json")

    assert policy["schema_version"] == 1
    assert policy["defaults"]["local_only"] is True
    assert policy["defaults"]["user_initiated_only"] is True
    assert policy["defaults"]["no_background_upload"] is True
    assert policy["defaults"]["no_raw_logs_by_default"] is True
    assert policy["defaults"]["clipboard_exports_redacted"] is True
    assert policy["defaults"]["support_ticket_attachments_redacted"] is True

    forbidden = set(policy["forbidden_payloads"])
    for payload in {
        "raw_config",
        "subscription_url",
        "proxy_link",
        "token",
        "secret",
        "private_key",
        "wireguard_private_material",
        "warp_private_material",
        "private_backend_details",
        "signing_material",
    }:
        assert payload in forbidden

    allowed_surfaces = set(policy["allowed_surfaces"])
    assert "support_diagnostics_copy_json" in allowed_surfaces
    assert "support_ticket_diagnostics_attachment" in allowed_surfaces
    assert "contributor_doctor_redacted_json" in allowed_surfaces

    assert policy["redaction"]["marker"] == "[redacted]"
    assert policy["redaction"]["max_string_length"] <= 160
    assert "PokrovAssistantRedactor" in policy["implementation"]["shared_redactor"]


def test_diagnostics_export_policy_is_documented() -> None:
    doc = (ROOT / "docs" / "DIAGNOSTICS_EXPORT_POLICY.md").read_text(
        encoding="utf-8"
    )
    docs_index = (ROOT / "docs" / "README.md").read_text(encoding="utf-8")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")

    for required in [
        "local-only",
        "user-initiated",
        "no background upload",
        "raw configs",
        "subscription URLs",
        "private backend details",
        "support diagnostics copy/export",
    ]:
        assert required in doc

    assert "DIAGNOSTICS_EXPORT_POLICY.md" in docs_index
    assert "diagnostics export policy" in changelog.lower()


def test_support_diagnostics_copy_uses_shared_redaction_contract() -> None:
    app_shell = (ROOT / "packages" / "app_shell" / "lib" / "app_shell.dart").read_text(
        encoding="utf-8"
    )

    assert "support-diagnostics-copy-json" in app_shell
    assert "_exportableSupportDiagnostics" in app_shell
    assert "PokrovAssistantRedactor.allowedDiagnosticKeys" in app_shell
    assert "PokrovAssistantRedactor.isSensitiveKey" in app_shell
    assert "PokrovAssistantRedactor.safeRedactedDiagnosticValue" in app_shell
    assert "Clipboard.setData" in app_shell
