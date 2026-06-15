from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def test_android_native_ci_is_a_required_source_only_check() -> None:
    seed = _read_json("config/required-checks.seed.json")
    workflow = _read(".github/workflows/ci.yml")

    assert "android_native_gradle_required" in seed["policy"]
    assert seed["policy"]["android_native_gradle_required"] is True
    assert "Android native Gradle unit tests" in seed["required_jobs"]
    assert "Run Android native Gradle unit tests" in seed["required_steps"]

    assert "name: Android native Gradle unit tests" in workflow
    assert "scripts\\run-android-native-tests.ps1 -SourceOnly" in workflow
    assert "fetch-libcore-assets" not in workflow


def test_android_native_source_only_runner_uses_stubs_not_runtime_artifacts() -> None:
    script = _read("scripts/run-android-native-tests.ps1")
    build_gradle = _read("apps/android_shell/android/app/build.gradle")

    assert "openClientUseLibcoreStub" in build_gradle
    assert "src/libcoreStub/kotlin" in build_gradle
    assert "testDebugUnitTest" in script
    assert ":app:testDebugUnitTest" in script
    assert "-PopenClientUseLibcoreStub=true" in script
    assert "app\\libs\\libcore.aar" in script
    assert "fetch-libcore-assets" not in script


def test_android_native_ci_docs_keep_source_only_boundaries() -> None:
    docs = "\n".join(
        [
            _read("apps/android_shell/README.md"),
            _read("docs/BUILD_FROM_SOURCE.md"),
            _read("docs/REQUIRED_CHECKS.md"),
            _read("docs/TROUBLESHOOTING.md"),
            _read("CHANGELOG.md"),
        ]
    )

    for phrase in (
        "Android native Gradle unit tests",
        "source-only stub lane",
        "does not fetch or commit libcore.aar",
        "does not prove APK, store, trusted signing, or runtime readiness",
    ):
        assert phrase in docs
