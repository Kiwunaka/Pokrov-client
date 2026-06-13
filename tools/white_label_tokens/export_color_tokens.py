from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REQUIRED_ROLES = (
    "canvas",
    "canvasAlt",
    "ink",
    "accent",
    "accentBright",
    "success",
    "warning",
    "surface",
    "surfaceMuted",
    "line",
    "muted",
)
FORBIDDEN_OFFICIAL_ENDPOINTS = (
    "api.pokrov.space",
    "app.pokrov.space",
    "pay.pokrov.space",
    "connect.pokrov.space",
    "kiwunaka.space",
)
HEX_RE = re.compile(r"^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")


class TokenExportError(ValueError):
    pass


@dataclass(frozen=True)
class ColorToken:
    name: str
    value: str
    usage: str
    editable: bool

    @property
    def argb(self) -> str:
        raw = self.value.removeprefix("#").upper()
        if len(raw) == 6:
            return f"FF{raw}"
        return raw

    @property
    def css_value(self) -> str:
        raw = self.argb
        alpha = int(raw[0:2], 16) / 255
        red = int(raw[2:4], 16)
        green = int(raw[4:6], 16)
        blue = int(raw[6:8], 16)
        if alpha >= 0.999:
            return f"#{raw[2:]}"
        return f"rgba({red}, {green}, {blue}, {alpha:.3f})"

    @property
    def css_name(self) -> str:
        return "--open-client-" + re.sub(
            r"([a-z0-9])([A-Z])",
            r"\1-\2",
            self.name,
        ).lower()


def load_config(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate_config(config: dict[str, Any]) -> list[ColorToken]:
    if config.get("schema") != 1:
        raise TokenExportError("schema must be 1")
    if config.get("variant") != "operator":
        raise TokenExportError("variant must be operator")

    serialized = json.dumps(config, sort_keys=True)
    for endpoint in FORBIDDEN_OFFICIAL_ENDPOINTS:
        if endpoint in serialized:
            raise TokenExportError(f"official endpoint is not allowed: {endpoint}")

    policy = _as_dict(config.get("policy"))
    if policy.get("operator_owned_branding") is not True:
        raise TokenExportError("policy.operator_owned_branding must be true")
    if policy.get("official_pokrov_brand_allowed") is not False:
        raise TokenExportError("official POKROV brand must be disallowed")
    if policy.get("official_endpoint_allowed") is not False:
        raise TokenExportError("official endpoints must be disallowed")

    roles = _as_dict(config.get("roles"))
    role_names = tuple(roles.keys())
    if role_names != REQUIRED_ROLES:
        raise TokenExportError(
            "roles must appear in canonical order: " + ", ".join(REQUIRED_ROLES)
        )

    tokens = []
    for name in REQUIRED_ROLES:
        role = _as_dict(roles.get(name))
        value = str(role.get("value", ""))
        if not HEX_RE.match(value):
            raise TokenExportError(f"{name} must be #RRGGBB or #AARRGGBB")
        usage = str(role.get("usage", "")).strip()
        if not usage:
            raise TokenExportError(f"{name} must document usage")
        tokens.append(
            ColorToken(
                name=name,
                value=value.upper(),
                usage=usage,
                editable=role.get("editable") is True,
            )
        )

    _validate_contrast(config, tokens)
    return tokens


def export_tokens(config: dict[str, Any], output_dir: Path) -> list[Path]:
    tokens = validate_config(config)
    export_config = _as_dict(config.get("export"))
    formats = export_config.get("formats", ["json", "dart", "css"])
    if not isinstance(formats, list):
        raise TokenExportError("export.formats must be a list")

    output_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    if "json" in formats:
        path = output_dir / "white-label-colors.json"
        path.write_text(_json_export(tokens), encoding="utf-8")
        written.append(path)
    if "dart" in formats:
        path = output_dir / "white_label_palette.dart"
        path.write_text(
            _dart_export(tokens, str(export_config.get("dart_class_name", ""))),
            encoding="utf-8",
        )
        written.append(path)
    if "css" in formats:
        path = output_dir / "white-label-colors.css"
        path.write_text(
            _css_export(tokens, str(export_config.get("css_selector", ":root"))),
            encoding="utf-8",
        )
        written.append(path)
    return written


def contrast_ratio(foreground: ColorToken, background: ColorToken) -> float:
    fg = _relative_luminance(foreground)
    bg = _relative_luminance(background)
    light = max(fg, bg)
    dark = min(fg, bg)
    return (light + 0.05) / (dark + 0.05)


def _validate_contrast(config: dict[str, Any], tokens: list[ColorToken]) -> None:
    by_name = {token.name: token for token in tokens}
    checks = config.get("contrast_checks", [])
    if not isinstance(checks, list) or not checks:
        raise TokenExportError("contrast_checks must be a non-empty list")
    for check in checks:
        if not isinstance(check, dict):
            raise TokenExportError("contrast check must be an object")
        foreground = by_name.get(str(check.get("foreground", "")))
        background = by_name.get(str(check.get("background", "")))
        minimum = float(check.get("minimum", 0))
        if foreground is None or background is None:
            raise TokenExportError("contrast check references an unknown role")
        if contrast_ratio(foreground, background) < minimum:
            raise TokenExportError(
                f"contrast {foreground.name}/{background.name} is below {minimum}"
            )


def _relative_luminance(token: ColorToken) -> float:
    raw = token.argb
    channels = [int(raw[index : index + 2], 16) / 255 for index in (2, 4, 6)]
    linear = [
        channel / 12.92
        if channel <= 0.03928
        else ((channel + 0.055) / 1.055) ** 2.4
        for channel in channels
    ]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def _json_export(tokens: list[ColorToken]) -> str:
    return (
        json.dumps(
            {
                "schema": 1,
                "roles": {
                    token.name: {
                        "hex": token.value,
                        "argb": f"0x{token.argb}",
                        "css": token.css_value,
                        "usage": token.usage,
                    }
                    for token in tokens
                },
            },
            indent=2,
            sort_keys=False,
        )
        + "\n"
    )


def _dart_export(tokens: list[ColorToken], class_name: str) -> str:
    safe_class = (
        class_name
        if re.match(r"^[A-Za-z][A-Za-z0-9_]*$", class_name)
        else "WhiteLabelPalette"
    )
    lines = [
        "// Generated from config/white-label-color-tokens.seed.json.",
        "// Review accessibility and operator brand policy before shipping.",
        "import 'package:flutter/material.dart';",
        "",
        f"abstract final class {safe_class} {{",
    ]
    for token in tokens:
        lines.append(f"  static const {token.name} = Color(0x{token.argb});")
    lines.append("}")
    return "\n".join(lines) + "\n"


def _css_export(tokens: list[ColorToken], selector: str) -> str:
    safe_selector = selector.strip() or ":root"
    lines = [
        "/* Generated from config/white-label-color-tokens.seed.json. */",
        "/* Review accessibility and operator brand policy before shipping. */",
        f"{safe_selector} {{",
    ]
    for token in tokens:
        lines.append(f"  {token.css_name}: {token.css_value};")
    lines.append("}")
    return "\n".join(lines) + "\n"


def _as_dict(value: object) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise TokenExportError("expected object")
    return value


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Export white-label color tokens.")
    parser.add_argument(
        "--config",
        type=Path,
        default=Path("config/white-label-color-tokens.seed.json"),
    )
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args(argv)

    config = load_config(args.config)
    export_config = _as_dict(config.get("export"))
    output_dir = args.out or Path(str(export_config.get("default_directory")))
    written = export_tokens(config, output_dir)
    for path in written:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
