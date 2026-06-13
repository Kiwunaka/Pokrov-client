from __future__ import annotations

import hashlib
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_source_release_preflight_script_runs_smoke_and_writes_outputs(
    tmp_path: Path,
) -> None:
    out_dir = tmp_path / "preflight"
    tag = "v9.9.4-source"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "source-release-preflight.ps1"),
            "-Tag",
            tag,
            "-OutDir",
            str(out_dir),
            "-AllowDirty",
            "-SkipTestCommands",
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )

    assert "Skipping test commands by request" in result.stdout
    assert "Source release preflight completed" in result.stdout

    proof_manifest = out_dir / "proof" / f"{tag}-source-proof.json"
    release_notes = out_dir / f"{tag}-release-notes.md"
    summary_path = out_dir / f"{tag}-source-preflight.json"

    assert proof_manifest.is_file()
    assert release_notes.is_file()
    assert summary_path.is_file()

    proof = json.loads(proof_manifest.read_text(encoding="utf-8-sig"))
    summary = json.loads(summary_path.read_text(encoding="utf-8-sig"))
    notes = release_notes.read_text(encoding="utf-8-sig")

    assert summary["schema_version"] == 1
    assert summary["tag"] == tag
    assert summary["skipped_test_commands"] is True
    assert summary["skipped_flutter_tests"] is False
    assert summary["source_only"] is True
    assert summary["no_apk"] is True
    assert summary["no_exe"] is True
    assert summary["no_store_release"] is True
    assert summary["no_trusted_signing_claim"] is True
    assert summary["forbidden_file_count"] == 0
    assert summary["commit_sha"] == proof["commit_sha"]
    assert summary["source_archive_sha256"] == proof["source_archive_sha256"]
    assert Path(summary["proof_manifest"]).name == proof_manifest.name
    assert Path(summary["release_notes"]).name == release_notes.name
    assert Path(summary["source_archive"]).name == proof["source_archive"]

    source_archive = out_dir / "proof" / proof["source_archive"]
    assert source_archive.is_file()
    assert hashlib.sha256(source_archive.read_bytes()).hexdigest() == proof[
        "source_archive_sha256"
    ]

    assert f"# {tag}" in notes
    assert "This is a source-only release." in notes
    assert "render-source-release-notes.ps1" in notes
    assert f'-ManifestLabel "{proof_manifest.name}"' in notes
    assert "<proof-manifest.json>" not in notes
    assert "<release-notes.md>" not in notes
    assert str(tmp_path) not in notes


def test_source_release_preflight_script_documents_full_release_checks() -> None:
    script = (ROOT / "scripts" / "source-release-preflight.ps1").read_text(
        encoding="utf-8"
    )

    assert "ValidatePattern('^v\\d+\\.\\d+\\.\\d+-source$')" in script
    assert "python -m pytest tests" in script
    assert "validate-seed.ps1" in script
    assert "verify-clean-clone.ps1" in script
    assert "run-tests.ps1" in script
    assert "prepare-source-release.ps1" in script
    assert "render-source-release-notes.ps1" in script
    assert "SkipTestCommands" in script
    assert "Use this only for local/CI smoke tests, not for publishing" in script
    assert "SkipFlutterTests" in script
    assert "Source preflight refused proof manifest" in script
