from __future__ import annotations

import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read_json(relative_path: str) -> dict:
    return json.loads((ROOT / relative_path).read_text(encoding="utf-8"))


def _write_json(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload), encoding="utf-8")


def _snapshot_files(paths: list[Path]) -> dict[Path, bytes | None]:
    snapshots: dict[Path, bytes | None] = {}
    for path in paths:
        snapshots[path] = path.read_bytes() if path.exists() else None
    return snapshots


def _restore_files(snapshots: dict[Path, bytes | None]) -> None:
    for path, content in snapshots.items():
        if content is None:
            path.unlink(missing_ok=True)
        else:
            path.write_bytes(content)


def test_release_blocker_inventory_tracks_manual_source_tag_steps() -> None:
    inventory = _read_json("config/release-blocker-inventory.seed.json")

    assert inventory["schema_version"] == 1
    assert inventory["release_line"] == "source-only"
    assert inventory["target_tag_family"] == "v0.x.0-source"
    assert inventory["status"] == "not_ready_for_tag"
    assert inventory["source_only"] is True
    assert inventory["ships_apk"] is False
    assert inventory["ships_exe"] is False
    assert inventory["store_release"] is False
    assert inventory["trusted_signing_claim"] is False

    blocker_ids = {blocker["id"] for blocker in inventory["blockers"]}
    for required in {
        "merge_stacked_pr_sequence",
        "choose_exact_commit_sha",
        "run_full_source_preflight",
        "review_release_evidence_bundle",
        "review_public_release_notes",
        "confirm_no_binary_claims",
        "confirm_catalog_and_diagnostics_boundaries",
    }:
        assert required in blocker_ids

    for blocker in inventory["blockers"]:
        assert blocker["status"] in {"manual_owner_test", "pending_maintainer_review"}
        assert blocker["required_before_tag"] is True
        assert blocker["evidence"]


def test_release_blocker_inventory_records_current_candidate_scope() -> None:
    inventory = _read_json("config/release-blocker-inventory.seed.json")
    candidates = inventory["tracked_candidates"]

    assert candidates["latest_stacked_pr"] == 156
    assert candidates["latest_candidate"] == "v0.135.0-source"
    assert candidates["base_candidate"] == "v0.1.0-source"
    assert (
        candidates["covered_range"]
        == f"{candidates['base_candidate']} through {candidates['latest_candidate']}"
    )
    assert candidates["tag_creation_allowed"] is False
    assert "v0.135.0-source" in candidates["covered_range"]


def test_release_blocker_inventory_is_documented_and_indexed() -> None:
    doc = (ROOT / "docs" / "RELEASE_BLOCKERS.md").read_text(encoding="utf-8")
    docs_index = (ROOT / "docs" / "README.md").read_text(encoding="utf-8")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    validator = (ROOT / "scripts" / "validate-seed.ps1").read_text(
        encoding="utf-8"
    )

    for required in [
        "not ready for tag",
        "merge the stacked PR sequence",
        "choose the exact commit SHA",
        "full source release preflight",
        "release evidence bundle",
        "no APK, EXE, store release, or trusted signing claim",
        "manual maintainer step",
    ]:
        assert required in doc

    assert "RELEASE_BLOCKERS.md" in docs_index
    assert "release blocker inventory" in changelog.lower()
    assert "covered_range must match base_candidate through latest_candidate" in (
        validator
    )


def test_readiness_tracking_mentions_release_blocker_inventory() -> None:
    readiness = _read_json("config/source-release-readiness.seed.json")
    by_tag = {milestone["tag"]: milestone for milestone in readiness["milestones"]}

    milestone = by_tag["v0.43.0-source"]
    assert milestone["status"] == "stacked_pr_green_not_tagged"
    assert milestone["evidence"] == "https://github.com/Kiwunaka/Pokrov-client/pull/63"
    assert "Release blocker inventory" in milestone["scope"]


def test_validate_seed_blocks_release_blocker_inventory_covered_range_drift() -> None:
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    snapshots = _snapshot_files([inventory_path])

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["tracked_candidates"][
            "covered_range"
        ] = "v0.1.0-source through v0.129.0-source"
        _write_json(inventory_path, inventory)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "validate-seed.ps1"),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode != 0
    assert "release-blocker-inventory.seed.json covered_range must match" in (
        result.stdout + result.stderr
    )
