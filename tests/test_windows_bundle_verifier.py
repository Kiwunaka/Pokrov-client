from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def test_windows_bundle_verifier_seed_defines_source_only_boundary() -> None:
    seed = _read_json("config/windows-bundle-verifier.seed.json")

    assert seed["script"] == "scripts/verify-windows-bundle.ps1"
    assert seed["default_output_dir"] == "build/windows-bundle-verifier"
    assert seed["policy"]["read_only"] is True
    assert seed["policy"]["source_only"] is True
    assert seed["policy"]["no_flutter_build"] is True
    assert seed["policy"]["no_runtime_download"] is True
    assert seed["policy"]["no_signing"] is True
    assert seed["policy"]["no_packaging"] is True
    assert seed["policy"]["no_publish"] is True
    assert seed["policy"]["forbid_committed_windows_binaries"] is True

    required_paths = set(seed["required_paths"])
    assert "apps/windows_shell/pubspec.yaml" in required_paths
    assert "apps/windows_shell/lib/main.dart" in required_paths
    assert "apps/windows_shell/windows/CMakeLists.txt" in required_paths
    assert "apps/windows_shell/windows/runner/runner.exe.manifest" in required_paths
    assert "config/windows-release.seed.json" in required_paths


def test_windows_bundle_verifier_script_is_read_only() -> None:
    script = _read("scripts/verify-windows-bundle.ps1")

    for phrase in (
        "windows-bundle-verifier.seed.json",
        "windows_bundle_ok",
        "build\\windows-bundle-verifier",
        "forbidden_artifact_count",
        "no_flutter_build = $true",
        "no_signing = $true",
        "no_publish = $true",
    ):
        assert phrase in script

    for forbidden in (
        "flutter build",
        "signtool",
        "New-SelfSignedCertificate",
        "makeappx",
        "msbuild",
        "gh release",
        "gh api",
        "Invoke-WebRequest",
        "Start-BitsTransfer",
    ):
        assert forbidden not in script


def test_windows_bundle_verifier_command_writes_summary() -> None:
    out_dir = ROOT / "build" / "windows-bundle-verifier" / "test-output"
    shutil.rmtree(out_dir, ignore_errors=True)

    try:
        subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "verify-windows-bundle.ps1"),
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "windows-bundle-verifier.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        shutil.rmtree(out_dir, ignore_errors=True)

    assert summary["windows_bundle_ok"] is True
    assert summary["source_only"] is True
    assert summary["read_only"] is True
    assert summary["build_performed"] is False
    assert summary["signing_performed"] is False
    assert summary["publish_performed"] is False
    assert summary["runtime_download_performed"] is False
    assert summary["forbidden_artifact_count"] == 0
    assert summary["required_path_count"] >= 5
    assert summary["release_claim_boundary"]["ships_exe"] is False
    assert summary["release_claim_boundary"]["store_release"] is False
    assert summary["release_claim_boundary"]["trusted_signing_claim"] is False


def test_windows_bundle_verifier_rejects_non_build_output(tmp_path: Path) -> None:
    out_dir = tmp_path / "outside-build"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "verify-windows-bundle.ps1"),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert not (out_dir / "windows-bundle-verifier.json").exists()
    assert "build\\windows-bundle-verifier" in (result.stderr + result.stdout)


def test_windows_bundle_verifier_is_documented_and_validated() -> None:
    docs = "\n".join(
        [
            _read("docs/BUILD_FROM_SOURCE.md"),
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("docs/TROUBLESHOOTING.md"),
            _read("scripts/README.md"),
            _read("CHANGELOG.md"),
        ]
    )
    validator = _read("scripts/validate-seed.ps1")

    assert "verify-windows-bundle.ps1" in docs
    assert "Windows bundle verifier" in docs
    assert "source-only Windows bundle proof" in docs
    assert "does not build, sign, package, publish, or download runtime artifacts" in docs
    assert "config\\\\windows-bundle-verifier.seed.json" in validator
    assert "scripts\\\\verify-windows-bundle.ps1" in validator
