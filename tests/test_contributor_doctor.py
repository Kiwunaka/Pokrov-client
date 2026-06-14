from __future__ import annotations

import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def test_contributor_doctor_seed_defines_read_only_policy() -> None:
    seed = _read_json("config/contributor-doctor.seed.json")

    assert seed["script"] == "scripts/doctor.ps1"
    assert seed["policy"]["read_only_by_default"] is True
    assert seed["policy"]["no_dependency_install"] is True
    assert seed["policy"]["no_build_or_release_artifacts"] is True
    assert seed["policy"]["no_network_required"] is True
    assert seed["policy"]["json_output_supported"] is True
    assert seed["policy"]["command_checks_can_be_skipped"] is True
    assert "flutter" in seed["required_commands"]
    assert "dart" in seed["required_commands"]
    assert "apps/android_shell/android/gradlew.bat" in seed["required_public_files"]
    assert "apps/windows_shell/windows/CMakeLists.txt" in seed["required_public_files"]
    assert "config/templates/device-overrides.seed.json" in seed["required_public_files"]


def test_contributor_doctor_runs_without_mutating_when_command_checks_skipped() -> None:
    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "doctor.ps1"),
            "-SkipCommandChecks",
            "-Json",
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    payload = json.loads(result.stdout)

    assert payload["ok"] is True
    assert payload["read_only"] is True
    assert payload["skipped_command_checks"] is True

    checks = {check["name"]: check for check in payload["checks"]}
    assert checks["file:README.md"]["status"] == "pass"
    assert checks["file:apps\\android_shell\\android\\gradlew.bat"]["status"] == "pass"
    assert checks["file:apps\\windows_shell\\windows\\CMakeLists.txt"]["status"] == "pass"
    assert checks["file:config\\templates\\device-overrides.seed.json"]["status"] == "pass"
    assert checks["command:flutter"]["status"] == "skip"
    assert checks["command:dart"]["status"] == "skip"


def test_contributor_doctor_docs_and_script_stay_safe() -> None:
    script = _read("scripts/doctor.ps1")
    docs = "\n".join(
        [
            _read("CONTRIBUTING.md"),
            _read("docs/BUILD_FROM_SOURCE.md"),
            _read("scripts/README.md"),
        ]
    )

    assert "Contributor doctor OK." in script
    assert "-SkipCommandChecks" in script
    assert "flutter pub get" not in script
    assert "flutter build" not in script
    assert "Copy-Item" not in script
    assert "scripts\\doctor.ps1" in docs
    assert "read-only" in docs


def test_validate_seed_knows_contributor_doctor() -> None:
    validator = _read("scripts/validate-seed.ps1")

    assert "config\\\\contributor-doctor.seed.json" in validator
    assert "scripts\\\\doctor.ps1" in validator
    assert "device-overrides.seed.json" in validator
