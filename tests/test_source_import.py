import json
from pathlib import Path

import pytest

from tools.source_import.safe_import import (
    ImportPolicy,
    SecretFinding,
    load_policy,
    plan_import,
    scan_text,
)


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def policy_path() -> Path:
    return Path(__file__).resolve().parents[1] / "tools/source_import/policy.pokrov_client.json"


def test_load_policy_rejects_empty_allowlist(tmp_path: Path) -> None:
    policy_file = tmp_path / "policy.json"
    policy_file.write_text(json.dumps({"allow": []}), encoding="utf-8")

    with pytest.raises(ValueError, match="allow"):
        load_policy(policy_file)


def test_plan_import_copies_only_allowlisted_files(tmp_path: Path) -> None:
    source = tmp_path / "source"
    staging = tmp_path / "staging"
    write(source / "packages/app_shell/lib/app_shell.dart", "void main() {}\n")
    write(source / "apps/android_shell/lib/main.dart", "void main() {}\n")
    write(source / "portal_bot/api.py", "PRIVATE_BACKEND = True\n")

    policy = ImportPolicy(
        allow=[
            "packages/app_shell/lib/**/*.dart",
            "apps/android_shell/lib/**/*.dart",
        ],
        deny=[],
    )

    result = plan_import(source, staging, policy, apply=True)

    copied = {item.relative_path for item in result.included}
    assert copied == {
        "packages/app_shell/lib/app_shell.dart",
        "apps/android_shell/lib/main.dart",
    }
    assert (staging / "packages/app_shell/lib/app_shell.dart").exists()
    assert not (staging / "portal_bot/api.py").exists()


def test_manifest_includes_schema_policy_and_file_hashes(tmp_path: Path) -> None:
    source = tmp_path / "source"
    staging = tmp_path / "staging"
    write(source / "packages/core_domain/lib/core_domain.dart", "class Core {}\n")
    policy = ImportPolicy(
        allow=["packages/core_domain/lib/**/*.dart"],
        deny=[],
        policy_sha256="policy-hash",
    )

    result = plan_import(source, staging, policy, apply=False)
    manifest = result.to_manifest()

    assert manifest["manifest_version"] == 1
    assert manifest["tool_version"].startswith("safe_import/")
    assert manifest["source_repo"] == "POKROV-app"
    assert manifest["target_repo"] == "Pokrov-client"
    assert manifest["policy_sha256"] == "policy-hash"
    assert manifest["secret_scan"] == "pass"
    assert manifest["manual_review"] == []
    assert manifest["license_notes"] == []
    allowed_file = manifest["allowed_files"][0]
    assert allowed_file["relative_path"] == "packages/core_domain/lib/core_domain.dart"
    assert allowed_file["size"] > 0
    assert len(allowed_file["sha256"]) == 64


def test_plan_import_blocks_denylisted_allowlist_matches(tmp_path: Path) -> None:
    source = tmp_path / "source"
    staging = tmp_path / "staging"
    write(source / "apps/windows_shell/windows/runner/resources/runtime/libcore.dll", "binary")
    write(source / "apps/windows_shell/lib/main.dart", "void main() {}\n")

    policy = ImportPolicy(
        allow=["apps/windows_shell/**/*"],
        deny=["**/*.dll", "**/resources/runtime/**"],
    )

    result = plan_import(source, staging, policy, apply=True)

    assert [item.relative_path for item in result.included] == [
        "apps/windows_shell/lib/main.dart"
    ]
    assert result.blocked[0].relative_path.endswith("libcore.dll")
    assert not (staging / "apps/windows_shell/windows/runner/resources/runtime/libcore.dll").exists()


def test_plan_import_rejects_unsafe_staging_paths(tmp_path: Path) -> None:
    source = tmp_path / "source"
    write(source / "packages/core_domain/lib/core_domain.dart", "class Core {}\n")
    policy = ImportPolicy(allow=["packages/core_domain/lib/**/*.dart"])

    with pytest.raises(ValueError, match="inside the source tree"):
        plan_import(source, source / "stage", policy, apply=False)

    git_root_stage = tmp_path / "public-repo"
    (git_root_stage / ".git").mkdir(parents=True)
    with pytest.raises(ValueError, match="git repository root"):
        plan_import(source, git_root_stage, policy, apply=False)

    non_empty_stage = tmp_path / "stage"
    write(non_empty_stage / "stale.txt", "old")
    with pytest.raises(ValueError, match="empty before apply"):
        plan_import(source, non_empty_stage, policy, apply=True)


def test_default_policy_blocks_release_signing_archives_logs_and_reports(tmp_path: Path) -> None:
    default_policy = load_policy(policy_path())
    policy = ImportPolicy(allow=["**/*"], deny=default_policy.deny)
    source = tmp_path / "source"
    staging = tmp_path / "staging"
    dangerous_paths = [
        "apps/android_shell/android/app/release.aab",
        "apps/android_shell/android/app/upload.mobileprovision",
        "apps/android_shell/android/app/signing.cer",
        "apps/windows_shell/windows/build/installer.msi",
        "apps/windows_shell/windows/build/portable.zip",
        "apps/windows_shell/logs/session.log",
        "apps/windows_shell/screenshots/account.png",
        "apps/windows_shell/reports/device.txt",
    ]
    for relative_path in dangerous_paths:
        write(source / relative_path, "blocked")

    result = plan_import(source, staging, policy, apply=False)
    blocked = {item.relative_path for item in result.blocked}

    assert set(dangerous_paths).issubset(blocked)


def test_plan_import_matches_recursive_patterns_with_direct_children(tmp_path: Path) -> None:
    source = tmp_path / "source"
    staging = tmp_path / "staging"
    write(source / "packages/core_domain/lib/core_domain.dart", "class Core {}\n")
    write(source / "packages/app_shell/test/app_shell_test.dart", "void main() {}\n")

    policy = ImportPolicy(
        allow=[
            "packages/**/lib/**/*.dart",
            "packages/**/test/**/*.dart",
        ],
        deny=[],
    )

    result = plan_import(source, staging, policy, apply=False)

    assert [item.relative_path for item in result.included] == [
        "packages/app_shell/test/app_shell_test.dart",
        "packages/core_domain/lib/core_domain.dart",
    ]


def test_dry_run_does_not_write_to_staging(tmp_path: Path) -> None:
    source = tmp_path / "source"
    staging = tmp_path / "staging"
    write(source / "packages/core_domain/lib/core_domain.dart", "class Core {}\n")

    policy = ImportPolicy(allow=["packages/core_domain/lib/**/*.dart"], deny=[])

    result = plan_import(source, staging, policy, apply=False)

    assert result.included[0].relative_path == "packages/core_domain/lib/core_domain.dart"
    assert not staging.exists()


def test_secret_scan_flags_high_risk_material() -> None:
    text = """
DATABASE_URL=postgres://user:password@example.invalid/db
-----BEGIN PRIVATE KEY-----
"""

    findings = scan_text(text)

    assert SecretFinding("database-url", 2) in findings
    assert SecretFinding("private-key", 3) in findings


def test_secret_scan_blocks_private_urls_proxy_links_and_subscription_urls() -> None:
    text = """
subscription=https://10.0.0.5/sub/token
profile=vless://11111111-1111-1111-1111-111111111111@vpn.customer.net:443?security=tls
safe=https://api.pokrov.space/status
fixture=trojan://secret@example.com:443
"""

    findings = scan_text(text, allowed_hosts=["*.pokrov.space"])

    assert SecretFinding("private-url", 2) in findings
    assert SecretFinding("proxy-uri", 3) in findings
    assert all(finding.line != 4 for finding in findings)
    assert all(finding.line != 5 for finding in findings)


def test_scan_file_blocks_unknown_binary_artifacts(tmp_path: Path) -> None:
    source = tmp_path / "source"
    staging = tmp_path / "staging"
    binary_path = source / "packages/core_domain/lib/blob.bin"
    binary_path.parent.mkdir(parents=True)
    binary_path.write_bytes(b"\xff\xfe\x00\x00")
    policy = ImportPolicy(allow=["packages/core_domain/lib/**/*"], deny=[])

    result = plan_import(source, staging, policy, apply=False)

    assert result.blocked[0].relative_path == "packages/core_domain/lib/blob.bin"
    assert result.blocked[0].findings == (SecretFinding("binary-unknown", 0),)


def test_secret_scan_ignores_normal_token_variables_and_short_test_values() -> None:
    text = """
final token = _readText(response['token']);
token: 'short-cabinet-token',
handoff_token=short-cabinet-token
"""

    assert scan_text(text) == []
