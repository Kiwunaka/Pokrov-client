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


def test_secret_scan_ignores_normal_token_variables_and_short_test_values() -> None:
    text = """
final token = _readText(response['token']);
token: 'short-cabinet-token',
handoff_token=short-cabinet-token
"""

    assert scan_text(text) == []
