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
    assert "cat-file" in script
    assert "Source release tags must be annotated tags" in script
    assert "$Ref^{}" in script


def test_render_source_release_notes_uses_proof_manifest(tmp_path: Path) -> None:
    manifest_path = tmp_path / "source-proof.json"
    manifest_path.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.7-source",
                "ref": "refs/tags/v9.9.7-source",
                "tag_object_sha": "b" * 40,
                "commit_sha": "a" * 40,
                "commit_date": "2026-06-13T00:00:00+00:00",
                "verification_date": "2026-06-13T00:10:00.0000000Z",
                "source_archive": "v9.9.7-source-source.zip",
                "source_archive_sha256": "c" * 64,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "tracked_file_count": 123,
                "forbidden_file_count": 0,
            }
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "render-source-release-notes.ps1"),
            "-ManifestPath",
            str(manifest_path),
            "-Included",
            "Manual source-only release notes test item.",
            "-KnownLimitations",
            "Manual limitation item.",
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )

    assert "# v9.9.7-source" in result.stdout
    assert "- Tag object SHA: " + ("b" * 40) in result.stdout
    assert "- Commit SHA: " + ("a" * 40) in result.stdout
    assert "- Source archive SHA-256: " + ("c" * 64) in result.stdout
    assert "- Source proof manifest: source-proof.json" in result.stdout
    assert str(tmp_path) not in result.stdout
    assert "Manual source-only release notes test item." in result.stdout
    assert "Manual limitation item." in result.stdout
    assert "No APK or EXE binaries." in result.stdout
    assert "No store release." in result.stdout
    assert "No trusted Windows signing claim." in result.stdout
    assert "```powershell" in result.stdout
    assert "render-source-release-notes.ps1" in result.stdout
    assert '-ManifestLabel "source-proof.json"' in result.stdout
    assert "<proof-manifest.json>" not in result.stdout
    assert "<release-notes.md>" not in result.stdout
    assert "source-only release" in result.stdout


def test_render_source_release_notes_can_use_public_manifest_label(
    tmp_path: Path,
) -> None:
    manifest_path = tmp_path / "local-proof.json"
    manifest_path.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "tag": "v9.9.5-source",
                "ref": "refs/tags/v9.9.5-source",
                "tag_object_sha": "b" * 40,
                "commit_sha": "a" * 40,
                "commit_date": "2026-06-13T00:00:00+00:00",
                "verification_date": "2026-06-13T00:10:00.0000000Z",
                "source_archive": "v9.9.5-source-source.zip",
                "source_archive_sha256": "c" * 64,
                "source_only": True,
                "no_apk": True,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "tracked_file_count": 123,
                "forbidden_file_count": 0,
            }
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "render-source-release-notes.ps1"),
            "-ManifestPath",
            str(manifest_path),
            "-ManifestLabel",
            "attached-source-proof.json",
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )

    assert "- Source proof manifest: attached-source-proof.json" in result.stdout
    assert "local-proof.json" not in result.stdout


def test_render_source_release_notes_rejects_binary_claim_manifest(
    tmp_path: Path,
) -> None:
    manifest_path = tmp_path / "source-proof.json"
    manifest_path.write_text(
        json.dumps(
            {
                "tag": "v9.9.6-source",
                "commit_sha": "a" * 40,
                "source_archive_sha256": "c" * 64,
                "source_archive": "v9.9.6-source-source.zip",
                "source_only": True,
                "no_apk": False,
                "no_exe": True,
                "no_store_release": True,
                "no_trusted_signing_claim": True,
                "forbidden_file_count": 0,
            }
        ),
        encoding="utf-8",
    )

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "render-source-release-notes.ps1"),
            "-ManifestPath",
            str(manifest_path),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert "no_apk=true" in result.stderr


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

    notes_path = out_dir / "v9.9.9-source-release-notes.md"
    render_result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "render-source-release-notes.ps1"),
            "-ManifestPath",
            str(manifest_path),
            "-ManifestLabel",
            manifest_path.name,
            "-OutFile",
            str(notes_path),
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )

    assert "Source release notes written" in render_result.stdout
    rendered_notes = notes_path.read_text(encoding="utf-8-sig")
    assert "# v9.9.9-source" in rendered_notes
    assert f"- Commit SHA: {manifest['commit_sha']}" in rendered_notes
    assert (
        f"- Source archive SHA-256: {manifest['source_archive_sha256']}"
        in rendered_notes
    )
    assert f"- Source proof manifest: {manifest_path.name}" in rendered_notes
    assert "No APK or EXE binaries." in rendered_notes
    assert "No store release." in rendered_notes
    assert "No trusted Windows signing claim." in rendered_notes
    assert "This is a source-only release." in rendered_notes
    assert "render-source-release-notes.ps1" in rendered_notes
    assert f'-ManifestLabel "{manifest_path.name}"' in rendered_notes
    assert "<proof-manifest.json>" not in rendered_notes
    assert "<release-notes.md>" not in rendered_notes
    assert str(out_dir) not in rendered_notes


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


def test_prepare_source_release_script_rejects_lightweight_tags(tmp_path: Path) -> None:
    tag = "v9.9.3-source"
    out_dir = tmp_path / "lightweight-proof"

    subprocess.run(["git", "tag", "-d", tag], cwd=ROOT, check=False, capture_output=True)
    try:
        subprocess.run(
            ["git", "tag", tag],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )

        result = subprocess.run(
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
            capture_output=True,
            text=True,
        )

        combined_output = result.stdout + result.stderr
        assert result.returncode != 0
        assert "Source release tags must be annotated tags" in combined_output
        assert not (out_dir / f"{tag}-source-proof.json").exists()
    finally:
        subprocess.run(["git", "tag", "-d", tag], cwd=ROOT, check=False, capture_output=True)
