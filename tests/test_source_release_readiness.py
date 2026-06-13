from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read_json(relative_path: str) -> dict:
    return json.loads((ROOT / relative_path).read_text(encoding="utf-8"))


def test_source_release_readiness_milestones_are_source_only() -> None:
    readiness = _read_json("config/source-release-readiness.seed.json")
    milestones = readiness["milestones"]

    assert readiness["policy"]["source_only_milestones_must_not_claim_binaries"] is True
    assert readiness["policy"]["pending_milestones_must_not_claim_tags"] is True
    assert len(milestones) >= 21

    for milestone in milestones:
        assert milestone["tag"].startswith("v")
        assert milestone["tag"].endswith("-source")
        assert milestone["status"] in {
            "tagged",
            "not_tagged",
            "stacked_pr_green_not_tagged",
        }
        assert milestone["source_only"] is True
        assert milestone["ships_apk"] is False
        assert milestone["ships_exe"] is False
        assert milestone["store_release"] is False
        assert milestone["trusted_signing_claim"] is False
        assert milestone["scope"]
        assert milestone["evidence"]


def test_current_stacked_pr_milestones_are_recorded() -> None:
    readiness = _read_json("config/source-release-readiness.seed.json")
    by_tag = {milestone["tag"]: milestone for milestone in readiness["milestones"]}

    expected = {
        "v0.4.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/23",
        "v0.5.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/24",
        "v0.6.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/25",
        "v0.7.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/26",
        "v0.8.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/27",
        "v0.9.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/28",
        "v0.10.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/29",
        "v0.11.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/30",
        "v0.12.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/31",
        "v0.13.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/32",
        "v0.14.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/33",
        "v0.15.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/34",
        "v0.16.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/35",
        "v0.17.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/36",
        "v0.18.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/38",
        "v0.19.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/39",
        "v0.20.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/40",
        "v0.21.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/41",
    }

    for tag, evidence in expected.items():
        milestone = by_tag[tag]
        assert milestone["status"] == "stacked_pr_green_not_tagged"
        assert milestone["evidence"] == evidence
        assert milestone["source_only"] is True
        assert milestone["ships_apk"] is False
        assert milestone["ships_exe"] is False


def test_readiness_docs_and_readmes_mention_every_source_milestone() -> None:
    readiness = _read_json("config/source-release-readiness.seed.json")
    docs_text = "\n".join(
        [
            (ROOT / "README.md").read_text(encoding="utf-8"),
            (ROOT / "README.en.md").read_text(encoding="utf-8"),
            (ROOT / "README.ru.md").read_text(encoding="utf-8"),
            (ROOT / "docs" / "releases" / "source-readiness-v0.2-v0.3.md").read_text(
                encoding="utf-8"
            ),
        ]
    )

    for milestone in readiness["milestones"]:
        assert milestone["tag"] in docs_text


def test_tagged_milestones_have_release_notes_and_pending_milestones_are_clear() -> None:
    readiness = _read_json("config/source-release-readiness.seed.json")

    for milestone in readiness["milestones"]:
        if milestone["status"] == "tagged":
            evidence = ROOT / milestone["evidence"]
            assert evidence.is_file()
            assert "No APK or EXE binaries" in evidence.read_text(encoding="utf-8")
        else:
            assert "not_tagged" in milestone["status"]
