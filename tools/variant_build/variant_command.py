from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


VARIANT_FILES = {
    "community": Path("config/variants/community-client.seed.json"),
    "operator": Path("config/variants/operator-client.seed.json"),
    "pokrov": Path("config/variants/pokrov-service.seed.json"),
}
HOST_DIRS = {
    "android": Path("apps/android_shell"),
    "windows": Path("apps/windows_shell"),
}
BUILD_COMMANDS = {
    "android": ["flutter", "build", "apk"],
    "windows": ["flutter", "build", "windows"],
}
RUN_COMMANDS = {
    "android": ["flutter", "run"],
    "windows": ["flutter", "run", "-d", "windows"],
}
FORBIDDEN_COMMUNITY_ENDPOINTS = (
    "api.pokrov.space",
    "app.pokrov.space",
    "pay.pokrov.space",
    "connect.pokrov.space",
    "kiwunaka.space",
)


class VariantCommandError(ValueError):
    pass


@dataclass(frozen=True)
class VariantCommand:
    variant: str
    platform: str
    action: str
    shell_dir: Path
    lines: tuple[str, ...]

    @property
    def text(self) -> str:
        return "\n".join(self.lines) + "\n"


def load_variant_seed(root: Path, variant: str) -> dict[str, Any]:
    try:
        relative_path = VARIANT_FILES[variant]
    except KeyError as error:
        raise VariantCommandError(f"unknown variant: {variant}") from error

    path = root / relative_path
    if not path.is_file():
        raise VariantCommandError(f"missing variant seed: {relative_path}")
    return json.loads(path.read_text(encoding="utf-8"))


def build_variant_command(
    *,
    root: Path,
    variant: str,
    platform: str,
    action: str = "run",
    release: bool = False,
) -> VariantCommand:
    if platform not in HOST_DIRS:
        raise VariantCommandError(f"unknown platform: {platform}")
    if action not in {"run", "build"}:
        raise VariantCommandError(f"unknown action: {action}")

    seed = load_variant_seed(root, variant)
    if seed.get("variant") != variant:
        raise VariantCommandError(f"{VARIANT_FILES[variant]} must declare {variant}")

    build_defines = seed.get("build_defines")
    if not isinstance(build_defines, dict) or not build_defines:
        raise VariantCommandError(f"{VARIANT_FILES[variant]} must define build_defines")

    _validate_variant_boundary(variant, build_defines)

    command = list(BUILD_COMMANDS[platform] if action == "build" else RUN_COMMANDS[platform])
    if release and action == "build":
        command.append("--release")
    for key, value in build_defines.items():
        command.append(f"--dart-define={key}={_ps_quote(str(value))}")

    lines = [
        "# Preview only: review native host metadata, signing, privacy, support, and release channels before distribution.",
        f"# Variant: {variant}",
        f"# Platform: {platform}",
    ]
    if variant == "community":
        lines.append(
            "# Community builds use local user profiles and do not provide POKROV nodes by default."
        )
    elif variant == "operator":
        lines.append(
            "# Operator builds must replace placeholder API, support, privacy, signing, and release surfaces."
        )
    elif variant == "pokrov":
        lines.append(
            "# WARNING: pokrov is reserved for official POKROV builds and is not fork-friendly."
        )
    if platform == "android":
        lines.append(
            "# Keep OPEN_CLIENT_ANDROID_PACKAGE_NAME aligned with Android openClientApplicationId."
        )
    lines.append(f"Push-Location {_ps_quote(str(HOST_DIRS[platform]).replace('/', '\\'))}")
    lines.extend(_format_command(command))
    lines.append("Pop-Location")

    return VariantCommand(
        variant=variant,
        platform=platform,
        action=action,
        shell_dir=HOST_DIRS[platform],
        lines=tuple(lines),
    )


def _validate_variant_boundary(variant: str, build_defines: dict[str, object]) -> None:
    serialized = json.dumps(build_defines, sort_keys=True)
    declared_variant = str(build_defines.get("OPEN_CLIENT_VARIANT", ""))
    if declared_variant != variant:
        raise VariantCommandError(
            f"OPEN_CLIENT_VARIANT must be {variant}, got {declared_variant or '<empty>'}"
        )
    if variant == "community":
        for endpoint in FORBIDDEN_COMMUNITY_ENDPOINTS:
            if endpoint in serialized:
                raise VariantCommandError(
                    f"community build defines must not contain {endpoint}"
                )
    if variant == "operator" and "api.pokrov.space" in serialized:
        raise VariantCommandError("operator build defines must not use POKROV API")
    if variant == "pokrov" and build_defines.get("OPEN_CLIENT_OFFICIAL_BUILD") != "true":
        raise VariantCommandError("pokrov variant must require OPEN_CLIENT_OFFICIAL_BUILD=true")


def _format_command(parts: list[str]) -> list[str]:
    if not parts:
        return []
    if len(parts) == 1:
        return parts
    lines = [" ".join(parts[:3]) + " `"] if parts[:3] in (
        ["flutter", "build", "apk"],
        ["flutter", "build", "windows"],
    ) else [" ".join(parts[:2]) + " `"]
    start = 3 if parts[:2] == ["flutter", "build"] else 2
    if parts[:3] == ["flutter", "run", "-d"]:
        lines = ["flutter run `"]
        start = 2
    for index, part in enumerate(parts[start:]):
        suffix = " `" if index < len(parts[start:]) - 1 else ""
        lines.append(f"  {part}{suffix}")
    return lines


def _ps_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Print a PowerShell Flutter command from a variant seed."
    )
    parser.add_argument("--variant", choices=sorted(VARIANT_FILES), required=True)
    parser.add_argument("--platform", choices=sorted(HOST_DIRS), required=True)
    parser.add_argument("--action", choices=("run", "build"), default="run")
    parser.add_argument(
        "--release",
        action="store_true",
        help="Add --release for build actions. Ignored for run previews.",
    )
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args(argv)

    command = build_variant_command(
        root=args.root,
        variant=args.variant,
        platform=args.platform,
        action=args.action,
        release=args.release,
    )
    print(command.text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
