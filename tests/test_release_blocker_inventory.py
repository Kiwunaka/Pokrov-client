from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read_json(relative_path: str) -> dict:
    return json.loads((ROOT / relative_path).read_text(encoding="utf-8"))


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

    assert candidates["latest_stacked_pr"] == 117
    assert candidates["latest_candidate"] == "v0.96.0-source"
    assert candidates["base_candidate"] == "v0.1.0-source"
    assert candidates["tag_creation_allowed"] is False
    assert "v0.96.0-source" in candidates["covered_range"]


def test_release_blocker_inventory_is_documented_and_indexed() -> None:
    doc = (ROOT / "docs" / "RELEASE_BLOCKERS.md").read_text(encoding="utf-8")
    docs_index = (ROOT / "docs" / "README.md").read_text(encoding="utf-8")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")

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


def test_readiness_tracking_mentions_release_blocker_inventory() -> None:
    readiness = _read_json("config/source-release-readiness.seed.json")
    by_tag = {milestone["tag"]: milestone for milestone in readiness["milestones"]}

    milestone = by_tag["v0.43.0-source"]
    assert milestone["status"] == "stacked_pr_green_not_tagged"
    assert milestone["evidence"] == "https://github.com/Kiwunaka/Pokrov-client/pull/63"
    assert "Release blocker inventory" in milestone["scope"]
