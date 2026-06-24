from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _read_json(relative_path: str) -> dict:
    return json.loads(_read(relative_path))


def _dependabot_entries() -> list[dict[str, str]]:
    text = _read(".github/dependabot.yml")
    entries: list[dict[str, str]] = []
    current: dict[str, str] | None = None

    for line in text.splitlines():
        ecosystem = re.match(r'\s*-\s+package-ecosystem:\s+"([^"]+)"', line)
        if ecosystem:
            current = {"package-ecosystem": ecosystem.group(1)}
            entries.append(current)
            continue
        if current is None:
            continue
        directory = re.match(r'\s+directory:\s+"([^"]+)"', line)
        if directory:
            current["directory"] = directory.group(1)
        limit = re.match(r"\s+open-pull-requests-limit:\s+(\d+)", line)
        if limit:
            current["open-pull-requests-limit"] = limit.group(1)

    return entries


def test_dependabot_policy_seed_defines_source_update_boundaries() -> None:
    seed = _read_json("config/dependabot-policy.seed.json")

    assert seed["dependabot_path"] == ".github/dependabot.yml"
    assert seed["policy"]["github_actions_updates_required"] is True
    assert seed["policy"]["pub_workspace_updates_required"] is True
    assert seed["policy"]["weekly_schedule_required"] is True
    assert seed["policy"]["bounded_open_prs_required"] is True
    assert seed["policy"]["dependency_label_required"] is True
    assert seed["policy"]["human_review_required_before_merge"] is True
    assert seed["policy"]["source_only_release_boundaries_apply"] is True
    assert seed["policy"]["runtime_binary_review_remains_separate"] is True
    assert seed["required_ecosystems"] == ["github-actions", "pub"]
    assert seed["required_labels"] == ["dependencies"]


def test_dependabot_covers_github_actions_and_all_pub_workspaces() -> None:
    seed = _read_json("config/dependabot-policy.seed.json")
    entries = _dependabot_entries()

    ecosystems = {entry["package-ecosystem"] for entry in entries}
    assert {"github-actions", "pub"}.issubset(ecosystems)

    pub_directories = {
        entry["directory"]
        for entry in entries
        if entry["package-ecosystem"] == "pub"
    }
    assert pub_directories == set(seed["required_pub_directories"])

    for entry in entries:
        assert int(entry["open-pull-requests-limit"]) <= 5


def test_dependabot_uses_weekly_schedule_labels_and_scoped_commits() -> None:
    text = _read(".github/dependabot.yml")

    for phrase in (
        'interval: "weekly"',
        'labels:',
        '- "dependencies"',
        'commit-message:',
        'include: "scope"',
    ):
        assert phrase in text

    for label in ("android", "windows", "runtime", "source-boundary"):
        assert f'- "{label}"' in text


def test_dependency_update_docs_keep_human_review_and_release_boundaries() -> None:
    docs = "\n".join(
        [
            _read("docs/DEPENDENCY_UPDATE_POLICY.md"),
            _read("docs/DEPENDENCY_LICENSE_AUDIT.md"),
            _read("docs/GITHUB_TRIAGE.md"),
        ]
    )

    for phrase in (
        "Dependabot",
        "review request, not an automatic approval",
        "config/dependency-license-inventory.seed.json",
        "Python contract tests",
        "Flutter workspace tests",
        "source-only release wording",
        "runtime binaries separate",
        "dependencies",
        "SECURITY.md",
    ):
        assert phrase in docs


def test_validate_seed_knows_dependabot_policy() -> None:
    validator = _read("scripts/validate-seed.ps1")

    assert "config\\\\dependabot-policy.seed.json" in validator
    assert ".github\\\\dependabot.yml" in validator
    assert "required_pub_directories" in validator
    assert "runtime_binary_review_remains_separate" in validator
