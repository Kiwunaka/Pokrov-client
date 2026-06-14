from __future__ import annotations

import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def test_android_device_validation_seed_records_manual_owner_gate() -> None:
    seed = _read_json("config/android-device-validation.seed.json")

    assert seed["schema_version"] == 1
    assert seed["script"] == "scripts/android-device-smoke.ps1"
    assert seed["checklist_doc"] == "docs/device-validation/android.md"
    assert seed["default_output_dir"] == "build/android-device-validation"
    assert seed["policy"]["read_only"] is True
    assert seed["policy"]["no_device_mutation_by_default"] is True
    assert seed["policy"]["physical_device_result_is_manual_owner_test"] is True
    assert seed["policy"]["does_not_claim_store_or_trusted_signing"] is True
    assert seed["policy"]["does_not_replace_release_build_audit"] is True

    required_checks = {
        "vpn_permission_flow",
        "foreground_service_special_use",
        "notification_disconnect",
        "system_vpn_revoke",
        "wifi_full_tunnel",
        "mobile_network_full_tunnel",
        "airplane_mode_recovery",
        "reconnect_loop",
        "subscription_refresh_failure_preserves_profile",
        "dns_no_desktop_loopback",
        "route_materialization",
        "false_connected_guard",
    }
    assert required_checks.issubset(set(seed["manual_checks"]))


def test_android_device_validation_docs_are_claim_safe_and_actionable() -> None:
    docs = _read("docs/device-validation/android.md")

    for phrase in (
        "MANUAL_OWNER_TEST",
        "Android device validation",
        "scripts\\android-device-smoke.ps1",
        "VpnService permission",
        "Android 14 specialUse foreground service",
        "notification disconnect",
        "system VPN settings",
        "Wi-Fi",
        "mobile network",
        "airplane mode",
        "old profile must remain available",
        "does not prove store readiness",
        "does not prove trusted signing",
        "does not replace the release-build audit",
    ):
        assert phrase in docs

    forbidden_claims = (
        "store ready",
        "trusted signed",
        "production ready",
        "official binary proof",
    )
    lowered = docs.lower()
    for claim in forbidden_claims:
        assert claim not in lowered


def test_android_device_smoke_script_writes_claim_safe_summary() -> None:
    script = ROOT / "scripts" / "android-device-smoke.ps1"
    assert script.is_file()

    command = [
        "powershell",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(script),
        "-Json",
    ]
    result = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=True,
    )
    summary = json.loads(result.stdout)

    assert summary["local_precheck_passed"] is True
    assert summary["physical_device_status"] == "MANUAL_OWNER_TEST"
    assert summary["release_claims"]["store_ready"] is False
    assert summary["release_claims"]["trusted_signing"] is False
    assert summary["release_claims"]["production_ready"] is False
    assert summary["release_claims"]["official_binary_proof"] is False
    assert summary["output_path"].startswith("build/android-device-validation/")
    assert "android.permission.BIND_VPN_SERVICE" in summary["manifest_checks"]
    assert "FOREGROUND_SERVICE_SPECIAL_USE" in summary["manifest_checks"]
    assert "onRevoke" in summary["service_checks"]
    assert "notification disconnect" in summary["service_checks"]

    output = ROOT / summary["output_path"]
    assert output.is_file()
    saved = json.loads(output.read_text(encoding="utf-8"))
    assert saved == summary


def test_android_device_validation_is_indexed_by_docs_scripts_and_seed_gate() -> None:
    combined = "\n".join(
        [
            _read("docs/README.md"),
            _read("apps/android_shell/README.md"),
            _read("scripts/README.md"),
            _read("scripts/validate-seed.ps1"),
        ]
    )

    for phrase in (
        "docs/device-validation/android.md",
        "scripts\\android-device-smoke.ps1",
        "android-device-validation.seed.json",
        "Android device validation",
        "MANUAL_OWNER_TEST",
    ):
        assert phrase in combined
