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


def test_source_release_readiness_milestones_are_source_only() -> None:
    readiness = _read_json("config/source-release-readiness.seed.json")
    milestones = readiness["milestones"]

    assert readiness["policy"]["source_only_milestones_must_not_claim_binaries"] is True
    assert readiness["policy"]["pending_milestones_must_not_claim_tags"] is True
    assert readiness["policy"]["release_notes_require_proof_manifest_after_v0_7"] is True
    assert readiness["policy"]["milestone_tags_must_be_unique"] is True
    assert (
        readiness["policy"]["stacked_pr_milestone_evidence_must_be_canonical_pr_url"]
        is True
    )
    assert readiness["policy"]["stacked_pr_milestone_evidence_urls_must_be_unique"] is True
    assert (
        readiness["policy"][
            "stacked_pr_milestone_evidence_pr_numbers_must_increase"
        ]
        is True
    )
    assert (
        readiness["policy"]["stacked_pr_milestones_must_match_merge_order_stack"]
        is True
    )
    assert (
        readiness["policy"][
            "stacked_pr_milestones_must_be_covered_by_merge_order_stack"
        ]
        is True
    )
    assert len(milestones) >= 50
    tags = [milestone["tag"] for milestone in milestones]
    assert len(tags) == len(set(tags))
    canonical_pr_prefix = "https://github.com/Kiwunaka/Pokrov-client/pull/"
    stacked_evidence_urls = [
        milestone["evidence"]
        for milestone in milestones
        if milestone["status"].startswith("stacked_pr_")
    ]
    assert len(stacked_evidence_urls) == len(set(stacked_evidence_urls))
    stacked_pr_numbers = [
        int(evidence.removeprefix(canonical_pr_prefix))
        for evidence in stacked_evidence_urls
    ]
    assert stacked_pr_numbers == sorted(stacked_pr_numbers)

    for milestone in milestones:
        assert milestone["tag"].startswith("v")
        assert milestone["tag"].endswith("-source")
        assert milestone["status"] in {
            "tagged",
            "not_tagged",
            "ready_for_tag",
            "stacked_pr_green_not_tagged",
            "stacked_pr_pending_not_tagged",
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
        "v0.87.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/108",
        "v0.88.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/109",
        "v0.89.0-source": "https://github.com/Kiwunaka/Pokrov-client/pull/110",
    }

    for tag, evidence in expected.items():
        milestone = by_tag[tag]
        assert milestone["status"] == "stacked_pr_green_not_tagged"
        assert milestone["evidence"] == evidence
        assert milestone["evidence"].startswith(
            "https://github.com/Kiwunaka/Pokrov-client/pull/"
        )
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
        elif milestone["status"] == "ready_for_tag":
            assert milestone["evidence"].startswith(
                "https://github.com/Kiwunaka/Pokrov-client/pull/"
            )
        else:
            assert "not_tagged" in milestone["status"]


def test_validate_seed_blocks_latest_source_readiness_evidence_mismatch() -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        latest_candidate = _read_json("config/release-blocker-inventory.seed.json")[
            "tracked_candidates"
        ]["latest_candidate"]
        for milestone in readiness["milestones"]:
            if milestone["tag"] == latest_candidate:
                milestone["evidence"] = "https://github.com/example/fork/pull/182"
                break
        _write_json(readiness_path, readiness)

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
    assert (
        "source-release-readiness.seed.json latest_candidate evidence must match latest stacked PR URL"
        in result.stdout + result.stderr
    )


def test_validate_seed_blocks_duplicate_source_readiness_milestone_tags() -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        duplicate = json.loads(json.dumps(readiness["milestones"][0]))
        readiness["milestones"].append(duplicate)
        _write_json(readiness_path, readiness)

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
    assert "source-release-readiness.seed.json milestone 'v0.1.0-source' tag must be unique" in (
        result.stdout + result.stderr
    )


def test_validate_seed_blocks_stacked_pr_source_readiness_evidence_boundary() -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.43.0-source":
                milestone["evidence"] = "https://github.com/example/fork/pull/63"
                break
        _write_json(readiness_path, readiness)

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
    assert (
        "source-release-readiness.seed.json milestone 'v0.43.0-source' stacked PR evidence must use canonical repository PR URL"
        in result.stdout + result.stderr
    )


def test_validate_seed_blocks_duplicate_stacked_pr_source_readiness_evidence() -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        duplicate_evidence = "https://github.com/Kiwunaka/Pokrov-client/pull/63"
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.44.0-source":
                milestone["evidence"] = duplicate_evidence
                break
        _write_json(readiness_path, readiness)

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
    assert (
        "source-release-readiness.seed.json milestone 'v0.44.0-source' stacked PR evidence URL must be unique"
        in result.stdout + result.stderr
    )


def test_validate_seed_blocks_decreasing_stacked_pr_source_readiness_evidence() -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.44.0-source":
                milestone["evidence"] = "https://github.com/Kiwunaka/Pokrov-client/pull/62"
                break
        _write_json(readiness_path, readiness)

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
    assert (
        "source-release-readiness.seed.json milestone 'v0.44.0-source' stacked PR evidence PR number must increase"
        in result.stdout + result.stderr
    )


def test_validate_seed_blocks_source_readiness_merge_order_evidence_mismatch() -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.90.0-source":
                milestone["evidence"] = "https://github.com/Kiwunaka/Pokrov-client/pull/110"
                break
        _write_json(readiness_path, readiness)

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
    assert (
        "source-release-readiness.seed.json milestone 'v0.90.0-source' evidence must match release merge-order PR #111"
        in result.stdout + result.stderr
    )


def test_validate_seed_blocks_source_readiness_missing_merge_order_coverage() -> None:
    merge_order_path = ROOT / "config" / "release-merge-order.seed.json"
    snapshots = _snapshot_files([merge_order_path])

    try:
        merge_order = json.loads(merge_order_path.read_text(encoding="utf-8"))
        stack = merge_order["stack"]
        removed_index = next(
            index
            for index, entry in enumerate(stack)
            if entry["candidate"] == "v0.90.0-source"
        )
        if removed_index + 1 < len(stack):
            stack[removed_index + 1]["base"] = stack[removed_index]["base"]
        stack.pop(removed_index)
        _write_json(merge_order_path, merge_order)

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
    assert (
        "source-release-readiness.seed.json milestone 'v0.90.0-source' stacked PR must be covered by release merge-order stack"
        in result.stdout + result.stderr
    )


def test_validate_seed_knows_latest_source_readiness_consistency() -> None:
    validator = (ROOT / "scripts" / "validate-seed.ps1").read_text(encoding="utf-8")

    assert "latest_candidate from release blocker inventory" in validator
    assert "latest_candidate evidence must match latest stacked PR URL" in validator
    assert "https://github.com/Kiwunaka/Pokrov-client/pull/$latestStackedPr" in validator
    assert "milestone_tags_must_be_unique" in validator
    assert "tag must be unique" in validator
    assert "stacked_pr_milestone_evidence_must_be_canonical_pr_url" in validator
    assert "stacked PR evidence must use canonical repository PR URL" in validator
    assert "stacked_pr_milestone_evidence_urls_must_be_unique" in validator
    assert "stacked PR evidence URL must be unique" in validator
    assert "stacked_pr_milestone_evidence_pr_numbers_must_increase" in validator
    assert "stacked PR evidence PR number must increase" in validator
    assert "stacked_pr_milestones_must_match_merge_order_stack" in validator
    assert "evidence must match release merge-order PR" in validator
    assert "stacked_pr_milestones_must_be_covered_by_merge_order_stack" in validator
    assert "stacked PR must be covered by release merge-order stack" in validator
