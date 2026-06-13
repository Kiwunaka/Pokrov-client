from __future__ import annotations

import json
import re
from pathlib import PurePosixPath, Path


ROOT = Path(__file__).resolve().parents[1]
PENDING_REVIEW = "PENDING_PUBLIC_BINARY_REVIEW"


def _read_json(relative_path: str) -> dict:
    return json.loads((ROOT / relative_path).read_text(encoding="utf-8"))


def test_runtime_artifact_manifest_has_source_only_review_boundaries() -> None:
    manifest = _read_json("config/runtime-artifacts.seed.json")
    libcore = manifest["libcore"]

    assert manifest["schema_version"] == 1
    assert libcore["repository"] == "hiddify/hiddify-core"
    assert libcore["source_url"] == "https://github.com/hiddify/hiddify-core"
    assert libcore["release_tag"].startswith("v")
    assert "{tag}" in libcore["release_url_template"]
    assert libcore["license_review"] in {"pending", "approved"}
    assert libcore["binary_review"] in {"pending", "approved"}
    assert "not committed" in libcore["source_release_scope"]
    assert "source-only releases" in libcore["source_release_scope"]
    assert PENDING_REVIEW in libcore["sha256_policy"]


def test_runtime_artifact_manifest_records_review_state_for_each_asset() -> None:
    manifest = _read_json("config/runtime-artifacts.seed.json")
    assets = manifest["libcore"]["assets"]

    expected = {
        "android": {
            "asset": "hiddify-core-android.tar.gz",
            "entry": "libcore.aar",
            "sync_destination": "apps/android_shell/android/app/libs",
        },
        "ios": {
            "asset": "hiddify-core-ios.tar.gz",
            "entry": "Libcore.xcframework",
            "sync_destination": "apps/ios_shell/ios/Frameworks",
        },
        "macos": {
            "asset": "hiddify-core-macos-universal.tar.gz",
            "entry": "libcore.dylib",
            "sync_destination": "apps/macos_shell/macos/Runner/Frameworks",
        },
        "windows": {
            "asset": "hiddify-core-windows-amd64.tar.gz",
            "entry": "libcore.dll",
            "sync_destination": "apps/windows_shell/windows/runner/resources/runtime",
        },
    }

    assert set(assets) == set(expected)

    for platform, expected_fields in expected.items():
        asset = assets[platform]
        for key, expected_value in expected_fields.items():
            assert asset[key] == expected_value

        assert asset["asset"].endswith(".tar.gz")
        assert asset["license_review"] in {"pending", "approved"}
        assert asset["binary_review"] in {"pending", "approved"}
        assert asset["sha256"] == PENDING_REVIEW or re.fullmatch(
            r"[a-f0-9]{64}", asset["sha256"]
        )


def test_runtime_sync_destinations_are_repo_relative_native_paths() -> None:
    manifest = _read_json("config/runtime-artifacts.seed.json")
    assets = manifest["libcore"]["assets"]
    allowed_prefixes = {
        "android": PurePosixPath("apps/android_shell"),
        "ios": PurePosixPath("apps/ios_shell"),
        "macos": PurePosixPath("apps/macos_shell"),
        "windows": PurePosixPath("apps/windows_shell"),
    }

    for platform, asset in assets.items():
        destination = PurePosixPath(asset["sync_destination"])
        assert not destination.is_absolute()
        assert ".." not in destination.parts
        assert destination.is_relative_to(allowed_prefixes[platform])
        assert destination.parts[0] == "apps"


def test_fetch_libcore_assets_enforces_hash_and_path_guards() -> None:
    script = (ROOT / "scripts" / "fetch-libcore-assets.ps1").read_text(
        encoding="utf-8"
    )

    assert "config\\runtime-artifacts.seed.json" in script
    assert "artifacts\\libcore\\$Tag" in script
    assert "Get-Sha256Hex" in script
    assert "PENDING_PUBLIC_BINARY_REVIEW" in script
    assert "SHA-256 mismatch" in script
    assert "Assert-PathInsideRepo" in script
    assert "sync_destination" in script


def test_runtime_artifacts_cache_is_ignored() -> None:
    gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")

    assert "artifacts/" in gitignore
