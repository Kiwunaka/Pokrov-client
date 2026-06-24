from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read_json(relative_path: str) -> dict:
    return json.loads((ROOT / relative_path).read_text(encoding="utf-8"))


def _lock_packages() -> dict[str, set[str]]:
    packages: dict[str, set[str]] = {}
    current_name: str | None = None

    for lock_path in ROOT.rglob("pubspec.lock"):
        for line in lock_path.read_text(encoding="utf-8").splitlines():
            package_match = re.match(r"^  ([A-Za-z0-9_]+):$", line)
            if package_match:
                current_name = package_match.group(1)
                packages.setdefault(current_name, set())
                continue

            version_match = re.match(r'^    version: "([^"]+)"$', line)
            if current_name and version_match:
                packages[current_name].add(version_match.group(1))

    return packages


def test_dependency_license_inventory_matches_pubspec_locks() -> None:
    inventory = _read_json("config/dependency-license-inventory.seed.json")
    lock_packages = _lock_packages()
    inventory_packages = {
        package["name"]: set(package["versions"]) for package in inventory["packages"]
    }

    assert inventory["policy"]["fail_on_missing_package_review"] is True
    assert len(inventory_packages) >= 90

    for package_name in {
        "camera_windows",
        "mobile_scanner",
        "pokrov_app_shell",
        "url_launcher",
        "zxing2",
    }:
        assert package_name in inventory_packages

    if lock_packages:
        assert set(inventory_packages) == set(lock_packages)

        for name, versions in lock_packages.items():
            assert inventory_packages[name] == versions


def test_dependency_license_inventory_is_publishable_for_source_release() -> None:
    inventory = _read_json("config/dependency-license-inventory.seed.json")
    allowed_licenses = set(inventory["policy"]["allowed_license_families"])

    for package in inventory["packages"]:
        assert package["license"] in allowed_licenses
        assert package["review"]
        assert package["review"] != "REVIEW_REQUIRED"
        assert package["source"] in {"hosted", "path", "sdk"}


def test_generated_asset_inventory_matches_png_tree() -> None:
    inventory = _read_json("config/generated-assets.seed.json")
    actual_pngs = {
        png_path.as_posix().removeprefix(ROOT.as_posix() + "/")
        for png_path in ROOT.joinpath("assets").rglob("*.png")
    }
    inventoried_pngs = {asset["path"] for asset in inventory["assets"]}

    assert inventory["policy"]["all_png_assets_must_be_listed"] is True
    assert inventoried_pngs == actual_pngs


def test_generated_asset_provenance_and_brand_boundaries_are_explicit() -> None:
    inventory = _read_json("config/generated-assets.seed.json")

    for asset in inventory["assets"]:
        assert (ROOT / asset["path"]).is_file()
        assert (ROOT / asset["provenance_doc"]).is_file()
        assert asset["public_release_ok"] is True

        if asset["kind"] == "imagegen-raster":
            assert asset["provenance_doc"] == "assets/IMAGEGEN_PROMPTS.md"
            assert asset["official_brand_asset"] is False
            assert asset["fork_reuse_allowed"] is True

        if asset["official_brand_asset"]:
            assert asset["fork_reuse_allowed"] is False
            assert "BRAND.md" in asset["reuse"]
            assert asset["provenance_doc"] == "assets/branding/README.md"
