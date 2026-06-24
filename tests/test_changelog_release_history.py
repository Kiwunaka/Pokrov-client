from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def test_changelog_policy_seed_defines_release_history_contract() -> None:
    policy = _read_json("config/changelog-policy.seed.json")

    assert policy["changelog_path"] == "CHANGELOG.md"
    assert policy["policy"]["keep_unreleased_section"] is True
    assert policy["policy"]["track_source_readiness_milestones"] is True
    assert policy["policy"]["pending_prs_must_not_be_presented_as_tags"] is True
    assert policy["policy"]["source_only_boundary_required"] is True
    assert policy["source_readiness_inventory"] == (
        "config/source-release-readiness.seed.json"
    )


def test_changelog_tracks_every_source_readiness_milestone() -> None:
    readiness = _read_json("config/source-release-readiness.seed.json")
    changelog = _read("CHANGELOG.md")

    assert "## Unreleased" in changelog
    assert "### Source Readiness Candidates" in changelog

    for milestone in readiness["milestones"]:
        assert milestone["tag"] in changelog
        if milestone["status"] == "stacked_pr_green_not_tagged":
            assert f"`{milestone['tag']}` | Pending stacked PR, not tagged" in changelog
        elif milestone["status"] == "ready_for_tag":
            assert f"`{milestone['tag']}` | Ready for source tag" in changelog
        elif milestone["status"] == "not_tagged":
            assert f"`{milestone['tag']}` | Not tagged" in changelog


def test_changelog_preserves_source_only_release_honesty() -> None:
    policy = _read_json("config/changelog-policy.seed.json")
    changelog = _read("CHANGELOG.md")

    for phrase in policy["required_source_only_phrases"]:
        assert phrase in changelog

    for claim in policy["forbidden_unreleased_claims"]:
        assert claim.lower() not in changelog.lower()

    for phrase in (
        "evidence-honest release notes",
        "No APK, EXE, store release, trusted signing, or official binary claim",
        "Pending stacked PR, not tagged",
    ):
        assert phrase in changelog


def test_validate_seed_knows_changelog_policy() -> None:
    validator = _read("scripts/validate-seed.ps1")

    assert "config\\\\changelog-policy.seed.json" in validator
    assert "CHANGELOG.md" in validator
    assert "source_readiness_inventory" in validator
    assert "pending_prs_must_not_be_presented_as_tags" in validator
    assert "forbidden_unreleased_claims" in validator
