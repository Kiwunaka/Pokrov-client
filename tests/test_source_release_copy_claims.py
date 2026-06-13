from __future__ import annotations

import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts" / "check-source-release-copy.ps1"


def _run_checker(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(CHECKER),
            *args,
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )


def test_source_release_copy_checker_accepts_repo_contracts() -> None:
    result = _run_checker()

    assert result.returncode == 0, result.stdout + result.stderr
    assert "Source release copy check OK." in result.stdout


def test_source_release_copy_checker_rejects_weak_rendered_notes(
    tmp_path: Path,
) -> None:
    release_notes = tmp_path / "weak-release-notes.md"
    release_notes.write_text(
        "# v9.9.9-source\n\nThis source release includes the client code.\n",
        encoding="utf-8",
    )

    result = _run_checker("-ReleaseNotesPath", str(release_notes))

    assert result.returncode == 1
    assert "Source release copy check failed." in result.stdout
    assert "No APK or EXE binaries." in result.stdout
    assert "Source archive SHA-256:" in result.stdout


def test_source_release_copy_checker_accepts_rendered_note_shape(
    tmp_path: Path,
) -> None:
    release_notes = tmp_path / "release-notes.md"
    release_notes.write_text(
        "\n".join(
            [
                "# v9.9.9-source",
                "",
                "## Source Reference",
                "",
                "- Source archive SHA-256: "
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                "- Source proof manifest: v9.9.9-source-source-proof.json",
                "- Verification date: 2026-06-13T00:00:00Z",
                "",
                "## Not Included",
                "",
                "- No APK or EXE binaries.",
                "- No store release.",
                "- No trusted Windows signing claim.",
                "- No official POKROV backend, billing, admin, deployment, "
                "signing, or private release evidence.",
                "",
                "## Release Honesty",
                "",
                "This is a source-only release. It does not imply an official "
                "binary, store listing, trusted signing, official POKROV "
                "service operation, or production readiness unless those claims "
                "are backed by separate public evidence.",
            ]
        ),
        encoding="utf-8",
    )

    result = _run_checker("-ReleaseNotesPath", str(release_notes))

    assert result.returncode == 0, result.stdout + result.stderr


def test_source_release_preflight_runs_copy_checker() -> None:
    preflight = (ROOT / "scripts" / "source-release-preflight.ps1").read_text(
        encoding="utf-8"
    )
    scripts_readme = (ROOT / "scripts" / "README.md").read_text(encoding="utf-8")

    assert "Check source release copy boundaries" in preflight
    assert "check-source-release-copy.ps1" in preflight
    assert "-ReleaseNotesPath $releaseNotesPath" in preflight
    assert "check-source-release-copy.ps1" in scripts_readme
