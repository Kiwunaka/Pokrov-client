from __future__ import annotations

import hashlib
import json
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload), encoding="utf-8")


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _fresh_generated_at() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _stale_generated_at() -> str:
    return (
        datetime.now(timezone.utc) - timedelta(hours=48)
    ).isoformat().replace("+00:00", "Z")


def _packet_summary(tmp_path: Path, ready: bool = True) -> tuple[Path, dict]:
    packet_path = (
        ROOT
        / "build"
        / "source-publication-packet"
        / "test-inputs"
        / tmp_path.name
        / "v0.169.0-source"
        / "source-publication-packet.json"
    )
    packet = {
        "schema_version": 1,
        "tag": "v0.169.0-source",
        "generated_at": _fresh_generated_at(),
        "read_only": True,
        "source_only": True,
        "manual_publish_only": True,
        "packet_ready_for_manual_publish_review": ready,
        "publish_performed": False,
        "tag_push_performed": False,
        "asset_upload_performed": False,
        "no_apk": True,
        "no_exe": True,
        "no_store_release": True,
        "no_trusted_signing_claim": True,
        "release_notes": "build/source-release-preflight/release-notes.md",
        "proof_manifest": "build/source-release-preflight/proof.json",
        "source_archive": "build/source-release-preflight/source.zip",
        "release_evidence_bundle": "build/release-evidence/release-evidence.json",
        "clean_clone_or_import_proof": "build/source-release-preflight/preflight.json",
        "release_handoff_github_ruleset_report": (
            "build/release-evidence/github-ruleset-report.json"
        ),
        "blocking_errors": [] if ready else ["source publication packet blocked"],
        "input_fingerprints": {
            "release_handoff": {
                "path": "build/release-merge-handoff/release-merge-handoff.json",
                "sha256": "1" * 64,
            },
            "publication_dry_run": {
                "path": (
                    "build/source-release-publication/v0.169.0-source/"
                    "v0.169.0-source-publication-dry-run.json"
                ),
                "sha256": "2" * 64,
            },
        },
        "artifact_file_fingerprints": {
            "release_notes": {
                "path": "build/source-release-preflight/release-notes.md",
                "sha256": "3" * 64,
            },
            "proof_manifest": {
                "path": "build/source-release-preflight/proof.json",
                "sha256": "4" * 64,
            },
            "source_archive": {
                "path": "build/source-release-preflight/source.zip",
                "sha256": "5" * 64,
            },
            "release_evidence_bundle": {
                "path": "build/release-evidence/release-evidence.json",
                "sha256": "6" * 64,
            },
            "clean_clone_or_import_proof": {
                "path": "build/source-release-preflight/preflight.json",
                "sha256": "7" * 64,
            },
            "github_ruleset_report": {
                "path": "build/release-evidence/github-ruleset-report.json",
                "sha256": "8" * 64,
            },
        },
    }
    _write_json(packet_path, packet)
    return packet_path, packet


def test_source_publication_gate_seed_defines_read_only_final_gate() -> None:
    seed = _read_json("config/source-publication-gate.seed.json")

    assert seed["script"] == "scripts/check-source-publication-gate.ps1"
    assert seed["default_output_dir"] == "build/source-publication-gate"
    assert seed["policy"]["read_only"] is True
    assert seed["policy"]["source_only"] is True
    assert seed["policy"]["manual_publish_review_gate"] is True
    assert seed["policy"]["no_tag_creation"] is True
    assert seed["policy"]["no_tag_push"] is True
    assert seed["policy"]["no_github_release_publish"] is True
    assert seed["policy"]["no_asset_upload"] is True
    assert seed["policy"]["requires_source_publication_packet_summary"] is True
    assert seed["policy"]["requires_source_publication_packet_ready"] is True
    assert seed["policy"]["requires_source_publication_packet_input_fingerprint"] is True
    assert seed["policy"]["requires_packet_generated_at_freshness"] is True
    assert seed["policy"]["requires_source_only_flags"] is True
    assert seed["inputs"]["source_publication_packet"].endswith(
        "v0.169.0-source/source-publication-packet.json"
    )
    assert seed["output"]["gate"].endswith(
        "v0.169.0-source/v0.169.0-source-publication-gate.json"
    )


def test_source_publication_gate_script_is_read_only() -> None:
    script = _read("scripts/check-source-publication-gate.ps1")

    for phrase in (
        "source-publication-gate.seed.json",
        "source_publication_packet",
        "publication_gate_ready_for_manual_publish",
        "packet_ready_for_manual_publish_review",
        "source publication packet is not ready for manual publish review",
        "source publication packet has stale generated_at timestamp",
        "source publication packet input fingerprint mismatch",
        "source publication packet has unsafe source-only flags",
        "manual_publish_review_gate",
        "read_only = $true",
        "publish_performed = $false",
        "asset_upload_performed = $false",
        "tag_push_performed = $false",
        "ComputeHash",
        "build\\source-publication-gate",
    ):
        assert phrase in script

    for forbidden in (
        "gh release create",
        "gh release upload",
        "git tag",
        "git push",
        "-X POST",
        "-X PATCH",
        "-X PUT",
        "-X DELETE",
    ):
        assert forbidden not in script


def test_source_publication_gate_writes_ready_summary(tmp_path: Path) -> None:
    packet_path, packet = _packet_summary(tmp_path)
    out_dir = ROOT / "build" / "source-publication-gate" / "test-ready"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "check-source-publication-gate.ps1"),
            "-PacketPath",
            str(packet_path),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    summary = json.loads(
        (
            out_dir
            / "v0.169.0-source"
            / "v0.169.0-source-publication-gate.json"
        ).read_text(encoding="utf-8-sig")
    )

    assert result.returncode == 0
    assert summary["read_only"] is True
    assert summary["manual_publish_review_gate"] is True
    assert summary["publication_gate_ready_for_manual_publish"] is True
    assert summary["publish_performed"] is False
    assert summary["asset_upload_performed"] is False
    assert summary["tag_push_performed"] is False
    assert summary["source_publication_packet"] == str(packet_path)
    assert summary["source_publication_packet_sha256"] == _sha256(packet_path)
    assert summary["source_publication_packet_generated_at"] == packet["generated_at"]
    assert summary["packet_artifact_file_fingerprints"] == packet[
        "artifact_file_fingerprints"
    ]
    assert summary["blocking_errors"] == []


def test_source_publication_gate_blocks_unready_packet(tmp_path: Path) -> None:
    packet_path, _packet = _packet_summary(tmp_path, ready=False)
    out_dir = ROOT / "build" / "source-publication-gate" / "test-unready-packet"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "check-source-publication-gate.ps1"),
            "-PacketPath",
            str(packet_path),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    summary = json.loads(
        (
            out_dir
            / "v0.169.0-source"
            / "v0.169.0-source-publication-gate.json"
        ).read_text(encoding="utf-8-sig")
    )

    assert result.returncode == 2
    assert summary["publication_gate_ready_for_manual_publish"] is False
    assert "source publication packet is not ready for manual publish review" in summary[
        "blocking_errors"
    ]


def test_source_publication_gate_blocks_stale_packet(tmp_path: Path) -> None:
    packet_path, packet = _packet_summary(tmp_path)
    packet["generated_at"] = _stale_generated_at()
    _write_json(packet_path, packet)
    out_dir = ROOT / "build" / "source-publication-gate" / "test-stale-packet"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "check-source-publication-gate.ps1"),
            "-PacketPath",
            str(packet_path),
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    summary = json.loads(
        (
            out_dir
            / "v0.169.0-source"
            / "v0.169.0-source-publication-gate.json"
        ).read_text(encoding="utf-8-sig")
    )

    assert result.returncode == 2
    assert "source publication packet has stale generated_at timestamp" in summary[
        "blocking_errors"
    ]


def test_source_publication_gate_is_documented_and_validated() -> None:
    docs = "\n".join(
        [
            _read("docs/RELEASE_BLOCKERS.md"),
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("docs/RELEASE_POLICY.md"),
            _read("scripts/README.md"),
        ]
    )
    validator = _read("scripts/validate-seed.ps1")
    changelog = _read("CHANGELOG.md")

    assert "check-source-publication-gate.ps1" in docs
    assert "source publication gate" in docs
    assert "config\\\\source-publication-gate.seed.json" in validator
    assert "scripts\\\\check-source-publication-gate.ps1" in validator
    assert "manual_publish_review_gate" in validator
    assert "publication_gate_ready_for_manual_publish" in validator
    assert "source publication gate" in changelog.lower()
