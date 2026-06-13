from __future__ import annotations

import json
from pathlib import Path

from tools.variant_build.variant_command import build_variant_command


ROOT = Path(__file__).resolve().parents[1]


def _seed(variant_file: str) -> dict:
    return json.loads(
        (ROOT / "config" / "variants" / variant_file).read_text(encoding="utf-8")
    )


def test_community_command_uses_seed_defines_and_local_shell_path() -> None:
    seed = _seed("community-client.seed.json")
    command = build_variant_command(
        root=ROOT,
        variant="community",
        platform="android",
    )
    text = command.text

    assert "Push-Location 'apps\\android_shell'" in text
    assert "flutter run `" in text
    for key in seed["build_defines"]:
        assert f"--dart-define={key}=" in text
    assert "--dart-define=OPEN_CLIENT_ENABLE_FREE_CATALOG='false'" in text
    assert "api.pokrov.space" not in text
    assert "app.pokrov.space" not in text
    assert "Community builds use local user profiles" in text


def test_operator_command_includes_owned_api_defines_without_official_endpoints() -> None:
    seed = _seed("operator-client.seed.json")
    command = build_variant_command(
        root=ROOT,
        variant="operator",
        platform="windows",
        action="build",
        release=True,
    )
    text = command.text

    assert "Push-Location 'apps\\windows_shell'" in text
    assert "flutter build windows `" in text
    assert "--release `" in text
    for key in seed["build_defines"]:
        assert f"--dart-define={key}=" in text
    assert "--dart-define=OPEN_CLIENT_API_BASE_URL='https://api.example.invalid/'" in text
    assert "--dart-define=OPEN_CLIENT_PRIVACY_URL='https://example.invalid/privacy/'" in text
    assert "api.pokrov.space" not in text
    assert "Operator builds must replace placeholder" in text


def test_pokrov_command_requires_official_boundary_warning() -> None:
    command = build_variant_command(
        root=ROOT,
        variant="pokrov",
        platform="android",
        action="build",
    )
    text = command.text

    assert "--dart-define=OPEN_CLIENT_OFFICIAL_BUILD='true'" in text
    assert "WARNING: pokrov is reserved for official POKROV builds" in text
    assert "Push-Location 'apps\\android_shell'" in text


def test_windows_run_command_targets_windows_device() -> None:
    command = build_variant_command(
        root=ROOT,
        variant="community",
        platform="windows",
    )

    assert "Push-Location 'apps\\windows_shell'" in command.text
    assert "flutter run `" in command.text
    assert "  -d `" in command.text
    assert "  windows `" in command.text
