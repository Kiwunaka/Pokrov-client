from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_android_native_host_uses_neutral_open_source_defaults() -> None:
    manifest = (
        ROOT
        / "apps"
        / "android_shell"
        / "android"
        / "app"
        / "src"
        / "main"
        / "AndroidManifest.xml"
    ).read_text(encoding="utf-8")
    build_gradle = (
        ROOT / "apps" / "android_shell" / "android" / "app" / "build.gradle"
    ).read_text(encoding="utf-8")
    runtime_bootstrap = (
        ROOT / "packages" / "app_shell" / "lib" / "app_first_runtime_bootstrap.dart"
    ).read_text(encoding="utf-8")

    assert 'android:label="${openClientAppLabel}"' in manifest
    assert 'android:label="POKROV"' not in manifest
    assert 'android:value="${openClientRuntimeVpnSubtype}"' in manifest
    assert 'applicationId = "space.pokrov' not in build_gradle
    assert '"org.pokrovclient.community"' in build_gradle
    assert '"Open Client"' in build_gradle
    assert "manifestPlaceholders +=" in build_gradle
    assert "OPEN_CLIENT_ANDROID_PACKAGE_NAME" in runtime_bootstrap
    assert "org.pokrovclient.community" in runtime_bootstrap


def test_android_runtime_user_messages_are_brand_indirected() -> None:
    source_root = (
        ROOT
        / "apps"
        / "android_shell"
        / "android"
        / "app"
        / "src"
        / "main"
        / "kotlin"
        / "space"
        / "pokrov"
        / "pokrov_android_shell"
    )
    checked_files = [
        source_root / "AndroidDefaultNetworkMonitor.kt",
        source_root / "AndroidLocalResolver.kt",
        source_root / "AndroidRuntimeState.kt",
        source_root / "PokrovRuntimeVpnService.kt",
        source_root / "RuntimeHostBridge.kt",
    ]

    for path in checked_files:
        content = path.read_text(encoding="utf-8")
        assert "NativeBranding" in content
        assert '"POKROV ' not in content
        assert '"Подключение POKROV"' not in content
        assert '"Готовим POKROV' not in content


def test_windows_native_host_uses_neutral_open_source_defaults() -> None:
    windows_root = ROOT / "apps" / "windows_shell" / "windows"
    top_level_cmake = (windows_root / "CMakeLists.txt").read_text(encoding="utf-8")
    runner_cmake = (windows_root / "runner" / "CMakeLists.txt").read_text(
        encoding="utf-8"
    )
    main_cpp = (windows_root / "runner" / "main.cpp").read_text(encoding="utf-8")
    runner_rc = (windows_root / "runner" / "Runner.rc").read_text(encoding="utf-8")

    assert "project(open_client_windows" in top_level_cmake
    assert "project(pokrov_windows_beta" not in top_level_cmake
    assert 'set(OPEN_CLIENT_WINDOWS_APP_NAME "Open Client"' in top_level_cmake
    assert 'set(OPEN_CLIENT_WINDOWS_BINARY_NAME "open_client_windows"' in top_level_cmake
    assert "OPEN_CLIENT_RUNTIME_DIR" in top_level_cmake
    assert "POKROV_RUNTIME_DIR" not in top_level_cmake
    assert "OC_WIN_PRODUCT_NAME" in runner_cmake
    assert "OC_WIN_APP_NAME" in main_cpp
    assert 'window.Create(L"POKROV"' not in main_cpp
    assert '"space.pokrov"' not in runner_rc
    assert '"POKROV"' not in runner_rc
    assert '"pokrov_windows_beta"' not in runner_rc
