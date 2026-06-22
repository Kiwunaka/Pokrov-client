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
    assert readiness["policy"]["release_notes_require_proof_manifest_after_v0_7"] is True
    assert len(milestones) >= 50

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
        "v0.22.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/42",
        "v0.23.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/43",
        "v0.24.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/44",
        "v0.25.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/45",
        "v0.26.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/46",
        "v0.27.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/47",
        "v0.28.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/48",
        "v0.29.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/49",
        "v0.30.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/50",
        "v0.31.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/51",
        "v0.32.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/52",
        "v0.33.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/53",
        "v0.34.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/54",
        "v0.35.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/55",
        "v0.36.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/56",
        "v0.37.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/57",
        "v0.38.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/58",
        "v0.39.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/59",
        "v0.40.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/60",
        "v0.41.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/61",
        "v0.42.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/62",
        "v0.43.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/63",
        "v0.44.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/64",
        "v0.45.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/65",
        "v0.46.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/66",
        "v0.47.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/67",
        "v0.48.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/68",
        "v0.49.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/69",
        "v0.50.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/70",
        "v0.51.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/71",
        "v0.52.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/72",
        "v0.53.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/73",
        "v0.54.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/74",
        "v0.55.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/75",
        "v0.56.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/76",
        "v0.57.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/77",
        "v0.58.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/78",
        "v0.59.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/79",
        "v0.60.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/80",
        "v0.61.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/81",
        "v0.62.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/82",
        "v0.63.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/83",
        "v0.64.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/84",
        "v0.65.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/85",
        "v0.66.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/86",
        "v0.67.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/87",
        "v0.68.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/88",
        "v0.69.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/89",
        "v0.70.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/90",
        "v0.71.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/91",
        "v0.72.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/92",
        "v0.73.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/93",
        "v0.74.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/94",
        "v0.75.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/95",
        "v0.76.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/96",
        "v0.77.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/97",
        "v0.78.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/98",
        "v0.79.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/99",
        "v0.80.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/100",
        "v0.81.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/101",
        "v0.82.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/102",
        "v0.83.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/103",
        "v0.84.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/104",
        "v0.85.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/105",
        "v0.86.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/107",
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
