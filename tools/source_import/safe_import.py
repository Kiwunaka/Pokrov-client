from __future__ import annotations

import argparse
import json
import re
import shutil
from dataclasses import dataclass, field
from fnmatch import fnmatchcase
from pathlib import Path
from typing import Iterable


@dataclass(frozen=True)
class SecretFinding:
    kind: str
    line: int


@dataclass(frozen=True)
class ImportPolicy:
    allow: list[str]
    deny: list[str] = field(default_factory=list)


@dataclass(frozen=True)
class ImportItem:
    relative_path: str
    reason: str
    findings: tuple[SecretFinding, ...] = ()


@dataclass(frozen=True)
class ImportResult:
    source: str
    staging: str
    applied: bool
    included: list[ImportItem]
    blocked: list[ImportItem]

    def to_manifest(self) -> dict:
        return {
            "source": self.source,
            "staging": self.staging,
            "applied": self.applied,
            "included": [item.__dict__ for item in self.included],
            "blocked": [
                {
                    "relative_path": item.relative_path,
                    "reason": item.reason,
                    "findings": [finding.__dict__ for finding in item.findings],
                }
                for item in self.blocked
            ],
            "summary": {
                "included": len(self.included),
                "blocked": len(self.blocked),
            },
        }


SECRET_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("private-key", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |)PRIVATE KEY-----")),
    ("database-url", re.compile(r"\bDATABASE_URL\s*=\s*postgres://", re.IGNORECASE)),
    ("github-token", re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b")),
    ("telegram-token", re.compile(r"\b\d{6,12}:[A-Za-z0-9_-]{30,}\b")),
    (
        "api-secret",
        re.compile(
            r"\b(?:API_KEY|SECRET|PASSWORD|TOKEN|ACCESS_TOKEN|BOT_TOKEN|CLIENT_SECRET)\b"
            r"\s*[:=]\s*['\"]?[A-Za-z0-9_./+=-]{16,}"
        ),
    ),
)


def load_policy(path: Path) -> ImportPolicy:
    data = json.loads(path.read_text(encoding="utf-8"))
    allow = list(data.get("allow", []))
    deny = list(data.get("deny", []))
    if not allow:
        raise ValueError("source import policy must define at least one allow pattern")
    return ImportPolicy(allow=allow, deny=deny)


def scan_text(text: str) -> list[SecretFinding]:
    findings: list[SecretFinding] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        for kind, pattern in SECRET_PATTERNS:
            if pattern.search(line):
                findings.append(SecretFinding(kind, line_number))
    return findings


def plan_import(source: Path, staging: Path, policy: ImportPolicy, apply: bool = False) -> ImportResult:
    source = source.resolve()
    staging = staging.resolve()
    if source == staging:
        raise ValueError("source and staging paths must be different")

    included: list[ImportItem] = []
    blocked: list[ImportItem] = []

    for file_path in sorted(path for path in source.rglob("*") if path.is_file()):
        relative_path = _relative_posix(source, file_path)
        if not _matches_any(relative_path, policy.allow):
            continue

        deny_pattern = _first_match(relative_path, policy.deny)
        if deny_pattern:
            blocked.append(ImportItem(relative_path, f"deny:{deny_pattern}"))
            continue

        findings = _scan_file(file_path)
        if findings:
            blocked.append(ImportItem(relative_path, "secret-scan", tuple(findings)))
            continue

        included.append(ImportItem(relative_path, "allow"))
        if apply:
            destination = staging / Path(relative_path)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(file_path, destination)

    return ImportResult(
        source=str(source),
        staging=str(staging),
        applied=apply,
        included=included,
        blocked=blocked,
    )


def write_manifest(result: ImportResult, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(result.to_manifest(), indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Plan or stage a sanitized POKROV client source import.")
    parser.add_argument("--source", required=True, type=Path, help="Private/snapshot source directory.")
    parser.add_argument("--staging", required=True, type=Path, help="Temporary staging directory.")
    parser.add_argument(
        "--policy",
        type=Path,
        default=Path(__file__).with_name("policy.pokrov_client.json"),
        help="JSON allowlist/denylist policy.",
    )
    parser.add_argument("--manifest", type=Path, help="Optional manifest output path.")
    parser.add_argument("--apply", action="store_true", help="Copy included files to staging. Omit for dry-run.")
    args = parser.parse_args(list(argv) if argv is not None else None)

    result = plan_import(args.source, args.staging, load_policy(args.policy), apply=args.apply)
    if args.manifest:
        write_manifest(result, args.manifest)

    print(f"included={len(result.included)} blocked={len(result.blocked)} applied={result.applied}")
    if result.blocked:
        print("blocked files:")
        for item in result.blocked[:50]:
            print(f"- {item.relative_path}: {item.reason}")
        if len(result.blocked) > 50:
            print(f"... {len(result.blocked) - 50} more")
    return 1 if result.blocked else 0


def _relative_posix(root: Path, path: Path) -> str:
    return path.relative_to(root).as_posix()


def _first_match(path: str, patterns: list[str]) -> str | None:
    for pattern in patterns:
        if _matches(path, pattern):
            return pattern
    return None


def _matches_any(path: str, patterns: list[str]) -> bool:
    return any(_matches(path, pattern) for pattern in patterns)


def _matches(path: str, pattern: str) -> bool:
    return _match_segments(path.split("/"), pattern.split("/"))


def _match_segments(path_parts: list[str], pattern_parts: list[str]) -> bool:
    if not pattern_parts:
        return not path_parts

    current_pattern = pattern_parts[0]
    if current_pattern == "**":
        return _match_segments(path_parts, pattern_parts[1:]) or (
            bool(path_parts) and _match_segments(path_parts[1:], pattern_parts)
        )

    return bool(path_parts) and fnmatchcase(path_parts[0], current_pattern) and _match_segments(
        path_parts[1:],
        pattern_parts[1:],
    )


def _scan_file(path: Path) -> list[SecretFinding]:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return []
    return scan_text(text)


if __name__ == "__main__":
    raise SystemExit(main())
