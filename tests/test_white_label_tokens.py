from __future__ import annotations

import json
from pathlib import Path

import pytest

from tools.white_label_tokens.export_color_tokens import (
    REQUIRED_ROLES,
    TokenExportError,
    export_tokens,
    load_config,
    validate_config,
)


ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "config" / "white-label-color-tokens.seed.json"


def test_white_label_color_seed_matches_operator_boundary() -> None:
    config = load_config(CONFIG_PATH)
    tokens = validate_config(config)

    assert config["variant"] == "operator"
    assert config["policy"]["operator_owned_branding"] is True
    assert config["policy"]["official_pokrov_brand_allowed"] is False
    assert config["policy"]["official_endpoint_allowed"] is False
    assert tuple(token.name for token in tokens) == REQUIRED_ROLES

    serialized = json.dumps(config, sort_keys=True)
    for forbidden in [
        "api.pokrov.space",
        "app.pokrov.space",
        "pay.pokrov.space",
        "connect.pokrov.space",
        "kiwunaka.space",
    ]:
        assert forbidden not in serialized


def test_white_label_export_writes_json_dart_and_css(tmp_path: Path) -> None:
    config = load_config(CONFIG_PATH)
    written = export_tokens(config, tmp_path)

    names = {path.name for path in written}
    assert names == {
        "white-label-colors.json",
        "white_label_palette.dart",
        "white-label-colors.css",
    }

    dart = (tmp_path / "white_label_palette.dart").read_text(encoding="utf-8")
    assert "abstract final class WhiteLabelPalette" in dart
    assert "static const accent = Color(0xFF0F725D);" in dart
    assert "PokrovPalette" not in dart

    css = (tmp_path / "white-label-colors.css").read_text(encoding="utf-8")
    assert "--open-client-accent: #0F725D;" in css
    assert "--open-client-line: rgba(16, 19, 26, 0.102);" in css

    exported_json = json.loads(
        (tmp_path / "white-label-colors.json").read_text(encoding="utf-8")
    )
    assert exported_json["roles"]["accent"]["argb"] == "0xFF0F725D"
    assert exported_json["roles"]["line"]["argb"] == "0x1A10131A"


def test_white_label_seed_rejects_low_contrast() -> None:
    config = load_config(CONFIG_PATH)
    config["roles"]["ink"]["value"] = "#F9FAFA"

    with pytest.raises(TokenExportError, match="contrast"):
        validate_config(config)


def test_white_label_seed_rejects_official_endpoints() -> None:
    config = load_config(CONFIG_PATH)
    config["policy"]["notes"].append("https://api.pokrov.space")

    with pytest.raises(TokenExportError, match="official endpoint"):
        validate_config(config)
