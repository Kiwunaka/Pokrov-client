from __future__ import annotations

import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_prepare_source_release_script_has_release_honesty_guards() -> None:
    script = (ROOT / "scripts" / "prepare-source-release.ps1").read_text(
        encoding="utf-8"
    )

    assert "ValidatePattern('^v\\d+\\.\\d+\\.\\d+-source$')" in script
    assert "no_apk" in script
    assert "no_exe" in script
    assert "no_store_release" in script
    assert "no_trusted_signing_claim" in script
    assert "forbiddenExtensionPattern" in script
    assert "tag_object_sha" in script
    assert "$Ref^{}" in script


def test_prepare_source_release_script_writes_proof_manifest(tmp_path: Path) -> None:
    out_dir = tmp_path / "proof"
    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "prepare-source-release.ps1"),
            "-Tag",
            "v9.9.9-source",
            "-OutDir",
            str(out_dir),
            "-AllowDirty",
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )

    assert "Source release proof prepared" in result.stdout

    archive = out_dir / "v9.9.9-source-source.zip"
    manifest_path = out_dir / "v9.9.9-source-source-proof.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))

    assert archive.is_file()
    assert manifest["schema_version"] == 1
    assert manifest["tag"] == "v9.9.9-source"
    assert manifest["source_archive"] == archive.name
    assert len(manifest["source_archive_sha256"]) == 64
    assert manifest["tag_object_sha"] == ""
    assert manifest["source_only"] is True
    assert manifest["no_apk"] is True
    assert manifest["no_exe"] is True
    assert manifest["no_store_release"] is True
    assert manifest["no_trusted_signing_claim"] is True
    assert manifest["forbidden_file_count"] == 0


def test_prepare_source_release_script_peels_annotated_tags(tmp_path: Path) -> None:
    tag = "v9.9.8-source"
    out_dir = tmp_path / "annotated-proof"

    subprocess.run(["git", "tag", "-d", tag], cwd=ROOT, check=False, capture_output=True)
    try:
        subprocess.run(
            [
                "git",
                "-c",
                "user.name=POKROV Source Test",
                "-c",
                "user.email=source-test@example.invalid",
                "tag",
                "-a",
                tag,
                "-m",
                "test annotated source tag",
            ],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        expected_commit = subprocess.check_output(
            ["git", "rev-parse", f"refs/tags/{tag}^{{}}"],
            cwd=ROOT,
            text=True,
        ).strip()
        tag_object = subprocess.check_output(
            ["git", "rev-parse", f"refs/tags/{tag}"],
            cwd=ROOT,
            text=True,
        ).strip()

        subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "prepare-source-release.ps1"),
                "-Tag",
                tag,
                "-OutDir",
                str(out_dir),
                "-RequireTag",
                "-AllowDirty",
            ],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )

        manifest = json.loads(
            (out_dir / f"{tag}-source-proof.json").read_text(encoding="utf-8-sig")
        )

        assert manifest["commit_sha"] == expected_commit
        assert manifest["tag_object_sha"] == tag_object
        assert manifest["tag_object_sha"] != manifest["commit_sha"]
        assert manifest["commit_date"].startswith("20")
    finally:
        subprocess.run(["git", "tag", "-d", tag], cwd=ROOT, check=False, capture_output=True)
