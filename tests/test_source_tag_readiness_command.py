from __future__ import annotations

import json
import hashlib
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def _write_json(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload), encoding="utf-8")


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


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
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)


def test_source_tag_readiness_seed_defines_read_only_command() -> None:
    seed = _read_json("config/source-tag-readiness.seed.json")

    assert seed["script"] == "scripts/check-source-tag-readiness.ps1"
    assert seed["default_output_dir"] == "build/source-tag-readiness"
    assert seed["policy"]["read_only"] is True
    assert seed["policy"]["no_tag_creation"] is True
    assert seed["policy"]["no_git_push"] is True
    assert seed["policy"]["no_github_release_publish"] is True
    assert seed["policy"]["nonzero_when_blocked"] is True
    assert seed["policy"]["requires_read_only_summary"] is True
    assert seed["policy"]["requires_input_fingerprints"] is True
    assert seed["policy"]["requires_latest_candidate_tag_match"] is True
    assert seed["policy"]["requires_latest_stacked_pr_evidence_match"] is True
    assert (
        seed["policy"]["requires_blocker_inventory_source_only_flags"] is True
    )
    assert (
        seed["policy"]["requires_source_readiness_milestone_source_only_flags"]
        is True
    )
    assert seed["policy"]["requires_error_summary"] is True
    assert seed["policy"]["requires_source_readiness_milestone_evidence"] is True
    assert (
        seed["policy"]["requires_source_readiness_milestone_evidence_repo_boundary"]
        is True
    )
    assert seed["policy"]["requires_source_readiness_milestone_scope"] is True
    assert seed["policy"]["requires_source_readiness_milestone_status"] is True
    assert seed["policy"]["requires_blocker_required_before_tag_flags"] is True
    assert seed["policy"]["requires_open_blocker_evidence_fields"] is True
    assert (
        seed["policy"]["requires_ready_status_open_blocker_consistency"]
        is True
    )
    assert (
        seed["policy"]["requires_tag_creation_allowed_blocker_consistency"]
        is True
    )
    assert (
        seed["policy"]["requires_tag_creation_allowed_status_consistency"]
        is True
    )
    assert (
        seed["policy"]["requires_source_readiness_milestone_ready_status_allowlist"]
        is True
    )
    assert (
        seed["policy"]["requires_tag_creation_allowed_milestone_status_consistency"]
        is True
    )
    assert seed["inputs"]["blocker_inventory"] == (
        "config/release-blocker-inventory.seed.json"
    )
    assert seed["inputs"]["source_readiness"] == (
        "config/source-release-readiness.seed.json"
    )


def test_source_tag_readiness_script_is_local_only() -> None:
    script = _read("scripts/check-source-tag-readiness.ps1")

    for phrase in (
        "release-blocker-inventory.seed.json",
        "source-release-readiness.seed.json",
        "ready_for_tag = $false",
        "read_only = $true",
        "input_fingerprints",
        "ComputeHash",
        "open_blocker_count",
        "error_count",
        "milestone_scope",
        "expected_milestone_evidence",
        "requested tag does not match latest blocker inventory candidate",
        "source readiness milestone evidence does not match latest stacked PR",
        "source readiness milestone evidence does not match expected repository PR URL",
        "source readiness milestone is missing evidence",
        "source readiness milestone is missing status",
        "source readiness milestone is missing scope",
        "release blocker inventory has unsafe source-only release flags",
        "source readiness milestone has unsafe source-only release flags",
        "release blocker inventory status is ready while required blockers remain open",
        "tag creation is allowed while required blockers remain open",
        "tag creation is allowed while release blocker inventory status is not ready",
        "tag creation is allowed while source readiness milestone is not tagged",
        "tag creation is allowed while source readiness milestone status is not ready",
        "open blocker is missing id",
        "blocker $blockerId is missing required_before_tag=true",
        "open blocker $blockerId is missing status",
        "open blocker $blockerId is missing evidence",
        "build\\source-tag-readiness",
        "exit 2",
    ):
        assert phrase in script

    for forbidden in (
        "git tag",
        "git push",
        "gh release create",
        "gh release upload",
        "-X POST",
        "-X PATCH",
        "-X PUT",
        "-X DELETE",
    ):
        assert forbidden not in script


def test_source_tag_readiness_reports_current_blockers(tmp_path: Path) -> None:
    out_dir = tmp_path / "tag-readiness"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
            "-Tag",
            "v0.170.0-source",
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 2
    assert "Source tag readiness: NOT READY" in result.stdout
    assert "merge_stacked_pr_sequence" in result.stdout

    summary = json.loads(
        (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
            encoding="utf-8-sig"
        )
    )
    assert summary["tag"] == "v0.170.0-source"
    assert summary["read_only"] is True
    assert summary["ready_for_tag"] is False
    assert summary["source_only"] is True
    assert summary["ships_apk"] is False
    assert summary["ships_exe"] is False
    assert summary["store_release"] is False
    assert summary["trusted_signing_claim"] is False
    assert summary["tag_creation_allowed"] is False
    assert summary["latest_candidate"] == "v0.170.0-source"
    assert summary["milestone_scope"]
    assert summary["input_fingerprints"]["blocker_inventory"]["sha256"] == _sha256(
        ROOT / "config" / "release-blocker-inventory.seed.json"
    )
    assert summary["input_fingerprints"]["source_readiness"]["sha256"] == _sha256(
        ROOT / "config" / "source-release-readiness.seed.json"
    )
    assert summary["error_count"] == 0
    assert summary["errors"] == []
    assert summary["open_blocker_count"] >= 7
    assert "merge_stacked_pr_sequence" in {
        blocker["id"] for blocker in summary["open_blockers"]
    }
    for blocker in summary["open_blockers"]:
        assert blocker["required_before_tag"] is True
        assert blocker["evidence"]


def test_source_tag_readiness_blocks_stale_requested_tag(tmp_path: Path) -> None:
    out_dir = tmp_path / "stale-tag-readiness"

    result = subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
            "-Tag",
            "v0.71.0-source",
            "-OutDir",
            str(out_dir),
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 2
    assert "requested tag does not match latest blocker inventory candidate" in (
        result.stdout + result.stderr
    )
    summary = json.loads(
        (out_dir / "v0.71.0-source-tag-readiness.json").read_text(
            encoding="utf-8-sig"
        )
    )
    assert summary["tag"] == "v0.71.0-source"
    assert summary["latest_candidate"] == "v0.170.0-source"
    assert summary["ready_for_tag"] is False
    assert "requested tag does not match latest blocker inventory candidate" in summary[
        "errors"
    ]


def test_source_tag_readiness_blocks_milestone_evidence_pr_mismatch(
    tmp_path: Path,
) -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])
    out_dir = tmp_path / "bad-evidence-readiness"

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.170.0-source":
                milestone["evidence"] = "https://github.com/Kiwunaka/Pokrov-client/pull/92"
                break
        _write_json(readiness_path, readiness)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert "source readiness milestone evidence does not match latest stacked PR" in (
        result.stdout + result.stderr
    )
    assert summary["latest_stacked_pr"] == 191
    assert summary["milestone_evidence"].endswith("/pull/92")
    assert "source readiness milestone evidence does not match latest stacked PR" in summary[
        "errors"
    ]


def test_source_tag_readiness_blocks_milestone_evidence_repo_mismatch(
    tmp_path: Path,
) -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])
    out_dir = tmp_path / "bad-evidence-repo-readiness"

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.170.0-source":
                milestone["evidence"] = "https://github.com/example/fork/pull/191"
                break
        _write_json(readiness_path, readiness)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert (
        "source readiness milestone evidence does not match expected repository PR URL"
        in result.stdout + result.stderr
    )
    assert summary["latest_stacked_pr"] == 191
    assert (
        summary["expected_milestone_evidence"]
        == "https://github.com/Kiwunaka/Pokrov-client/pull/191"
    )
    assert summary["milestone_evidence"].endswith("/pull/191")
    assert (
        "source readiness milestone evidence does not match expected repository PR URL"
        in summary["errors"]
    )


def test_source_tag_readiness_blocks_milestone_without_evidence(
    tmp_path: Path,
) -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])
    out_dir = tmp_path / "missing-milestone-evidence-readiness"

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.170.0-source":
                milestone["evidence"] = ""
                break
        _write_json(readiness_path, readiness)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert "source readiness milestone is missing evidence" in (
        result.stdout + result.stderr
    )
    assert "source readiness milestone is missing evidence" in summary["errors"]


def test_source_tag_readiness_blocks_unsafe_milestone_release_flags(
    tmp_path: Path,
) -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])
    out_dir = tmp_path / "unsafe-milestone-readiness"

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.170.0-source":
                milestone["source_only"] = False
                milestone["ships_apk"] = True
                break
        _write_json(readiness_path, readiness)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert "source readiness milestone has unsafe source-only release flags" in (
        result.stdout + result.stderr
    )
    assert "source readiness milestone has unsafe source-only release flags" in summary[
        "errors"
    ]


def test_source_tag_readiness_blocks_milestone_without_status(
    tmp_path: Path,
) -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])
    out_dir = tmp_path / "missing-milestone-status-readiness"

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.170.0-source":
                milestone["status"] = ""
                break
        _write_json(readiness_path, readiness)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert "source readiness milestone is missing status" in (
        result.stdout + result.stderr
    )
    assert "source readiness milestone is missing status" in summary["errors"]


def test_source_tag_readiness_blocks_milestone_without_scope(
    tmp_path: Path,
) -> None:
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([readiness_path])
    out_dir = tmp_path / "missing-milestone-scope-readiness"

    try:
        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.170.0-source":
                milestone["scope"] = ""
                break
        _write_json(readiness_path, readiness)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert "source readiness milestone is missing scope" in (
        result.stdout + result.stderr
    )
    assert "source readiness milestone is missing scope" in summary["errors"]


def test_source_tag_readiness_blocks_unsafe_inventory_release_flags(
    tmp_path: Path,
) -> None:
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    snapshots = _snapshot_files([inventory_path])
    out_dir = tmp_path / "unsafe-inventory-readiness"

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["source_only"] = False
        inventory["ships_exe"] = True
        _write_json(inventory_path, inventory)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert "release blocker inventory has unsafe source-only release flags" in (
        result.stdout + result.stderr
    )
    assert "release blocker inventory has unsafe source-only release flags" in summary[
        "errors"
    ]


def test_source_tag_readiness_blocks_open_blockers_without_evidence(
    tmp_path: Path,
) -> None:
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    snapshots = _snapshot_files([inventory_path])
    out_dir = tmp_path / "missing-blocker-evidence-readiness"

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["blockers"][0]["evidence"] = ""
        _write_json(inventory_path, inventory)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert "open blocker merge_stacked_pr_sequence is missing evidence" in (
        result.stdout + result.stderr
    )
    assert "open blocker merge_stacked_pr_sequence is missing evidence" in summary[
        "errors"
    ]


def test_source_tag_readiness_blocks_tag_creation_allowed_with_open_blockers(
    tmp_path: Path,
) -> None:
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    snapshots = _snapshot_files([inventory_path])
    out_dir = tmp_path / "tag-creation-open-blockers-readiness"

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["tracked_candidates"]["tag_creation_allowed"] = True
        _write_json(inventory_path, inventory)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert "tag creation is allowed while required blockers remain open" in (
        result.stdout + result.stderr
    )
    assert "tag creation is allowed while required blockers remain open" in summary[
        "errors"
    ]
    assert summary["ready_for_tag"] is False


def test_source_tag_readiness_blocks_ready_status_with_open_blockers(
    tmp_path: Path,
) -> None:
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    snapshots = _snapshot_files([inventory_path])
    out_dir = tmp_path / "ready-status-open-blockers-readiness"

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["status"] = "ready"
        _write_json(inventory_path, inventory)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert (
        "release blocker inventory status is ready while required blockers remain open"
        in result.stdout + result.stderr
    )
    assert (
        "release blocker inventory status is ready while required blockers remain open"
        in summary["errors"]
    )
    assert summary["open_blocker_count"] > 0
    assert summary["ready_for_tag"] is False


def test_source_tag_readiness_blocks_tag_creation_allowed_with_unready_status(
    tmp_path: Path,
) -> None:
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([inventory_path, readiness_path])
    out_dir = tmp_path / "tag-creation-unready-status-readiness"

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["tracked_candidates"]["tag_creation_allowed"] = True
        for blocker in inventory["blockers"]:
            blocker["status"] = "complete"
        _write_json(inventory_path, inventory)

        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.170.0-source":
                milestone["status"] = "tagged"
                break
        _write_json(readiness_path, readiness)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert (
        "tag creation is allowed while release blocker inventory status is not ready"
        in result.stdout + result.stderr
    )
    assert (
        "tag creation is allowed while release blocker inventory status is not ready"
        in summary["errors"]
    )
    assert summary["open_blocker_count"] == 0
    assert summary["ready_for_tag"] is False


def test_source_tag_readiness_blocks_tag_creation_allowed_with_pending_milestone(
    tmp_path: Path,
) -> None:
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    snapshots = _snapshot_files([inventory_path])
    out_dir = tmp_path / "tag-creation-pending-milestone-readiness"

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["status"] = "ready"
        inventory["tracked_candidates"]["tag_creation_allowed"] = True
        for blocker in inventory["blockers"]:
            blocker["status"] = "complete"
        _write_json(inventory_path, inventory)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert "tag creation is allowed while source readiness milestone is not tagged" in (
        result.stdout + result.stderr
    )
    assert "tag creation is allowed while source readiness milestone is not tagged" in (
        summary["errors"]
    )
    assert summary["open_blocker_count"] == 0
    assert summary["ready_for_tag"] is False


def test_source_tag_readiness_blocks_tag_creation_allowed_with_unready_milestone_status(
    tmp_path: Path,
) -> None:
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    readiness_path = ROOT / "config" / "source-release-readiness.seed.json"
    snapshots = _snapshot_files([inventory_path, readiness_path])
    out_dir = tmp_path / "tag-creation-unready-milestone-status-readiness"

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["status"] = "ready"
        inventory["tracked_candidates"]["tag_creation_allowed"] = True
        for blocker in inventory["blockers"]:
            blocker["status"] = "complete"
        _write_json(inventory_path, inventory)

        readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
        for milestone in readiness["milestones"]:
            if milestone["tag"] == "v0.170.0-source":
                milestone["status"] = "pending_review"
                break
        _write_json(readiness_path, readiness)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert (
        "tag creation is allowed while source readiness milestone status is not ready"
        in result.stdout + result.stderr
    )
    assert (
        "tag creation is allowed while source readiness milestone status is not ready"
        in summary["errors"]
    )
    assert summary["open_blocker_count"] == 0
    assert summary["ready_for_tag"] is False


def test_source_tag_readiness_blocks_open_blockers_without_id(
    tmp_path: Path,
) -> None:
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    snapshots = _snapshot_files([inventory_path])
    out_dir = tmp_path / "missing-blocker-id-readiness"

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["blockers"][0]["id"] = ""
        _write_json(inventory_path, inventory)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert "open blocker is missing id" in result.stdout + result.stderr
    assert "open blocker is missing id" in summary["errors"]


def test_source_tag_readiness_blocks_open_blockers_without_status(
    tmp_path: Path,
) -> None:
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    snapshots = _snapshot_files([inventory_path])
    out_dir = tmp_path / "missing-blocker-status-readiness"

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["blockers"][0]["status"] = ""
        _write_json(inventory_path, inventory)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert "open blocker merge_stacked_pr_sequence is missing status" in (
        result.stdout + result.stderr
    )
    assert "open blocker merge_stacked_pr_sequence is missing status" in summary[
        "errors"
    ]


def test_source_tag_readiness_blocks_blockers_without_required_before_tag(
    tmp_path: Path,
) -> None:
    inventory_path = ROOT / "config" / "release-blocker-inventory.seed.json"
    snapshots = _snapshot_files([inventory_path])
    out_dir = tmp_path / "missing-required-before-tag-readiness"

    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        inventory["blockers"][0]["required_before_tag"] = False
        _write_json(inventory_path, inventory)

        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check-source-tag-readiness.ps1"),
                "-Tag",
                "v0.170.0-source",
                "-OutDir",
                str(out_dir),
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        summary = json.loads(
            (out_dir / "v0.170.0-source-tag-readiness.json").read_text(
                encoding="utf-8-sig"
            )
        )
    finally:
        _restore_files(snapshots)

    assert result.returncode == 2
    assert (
        "blocker merge_stacked_pr_sequence is missing required_before_tag=true"
        in result.stdout + result.stderr
    )
    assert (
        "blocker merge_stacked_pr_sequence is missing required_before_tag=true"
        in summary["errors"]
    )


def test_source_tag_readiness_is_documented_and_validated() -> None:
    docs = "\n".join(
        [
            _read("docs/RELEASE_BLOCKERS.md"),
            _read("docs/RELEASE_CHECKLIST.md"),
            _read("scripts/README.md"),
        ]
    )
    validator = _read("scripts/validate-seed.ps1")
    changelog = _read("CHANGELOG.md")

    assert "check-source-tag-readiness.ps1" in docs
    assert "source tag readiness" in docs
    assert "config\\\\source-tag-readiness.seed.json" in validator
    assert "scripts\\\\check-source-tag-readiness.ps1" in validator
    assert "requires_source_readiness_milestone_evidence" in validator
    assert "requires_source_readiness_milestone_evidence_repo_boundary" in validator
    assert "requires_source_readiness_milestone_status" in validator
    assert "expected_milestone_evidence" in validator
    assert (
        "source readiness milestone evidence does not match expected repository PR URL"
        in validator
    )
    assert "source tag readiness command" in changelog.lower()
