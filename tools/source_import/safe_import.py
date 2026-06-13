from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
from urllib.parse import urlparse
from dataclasses import dataclass, field
from datetime import datetime, timezone
from fnmatch import fnmatchcase
from pathlib import Path
from typing import Iterable

TOOL_VERSION = "safe_import/0.2"
MANIFEST_VERSION = 1


@dataclass(frozen=True)
class SecretFinding:
    kind: str
    line: int


@dataclass(frozen=True)
class ImportPolicy:
    allow: list[str]
    deny: list[str] = field(default_factory=list)
    allowed_hosts: list[str] = field(default_factory=list)
    allow_binary: list[str] = field(default_factory=list)
    policy_sha256: str = ""


@dataclass(frozen=True)
class ImportItem:
    relative_path: str
    reason: str
    size: int = 0
    sha256: str = ""
    findings: tuple[SecretFinding, ...] = ()


@dataclass(frozen=True)
class ImportResult:
    source: str
    staging: str
    applied: bool
    policy_sha256: str
    included: list[ImportItem]
    blocked: list[ImportItem]

    def to_manifest(self) -> dict:
        blocked_files = [
            {
                "relative_path": item.relative_path,
                "reason": item.reason,
                "size": item.size,
                "sha256": item.sha256,
                "findings": [finding.__dict__ for finding in item.findings],
            }
            for item in self.blocked
        ]
        return {
            "manifest_version": MANIFEST_VERSION,
            "tool_version": TOOL_VERSION,
            "target_repo": "Pokrov-client",
            "source_repo": "POKROV-app",
            "source_ref": "manual-snapshot",
            "imported_at": datetime.now(timezone.utc).isoformat(),
            "policy_sha256": self.policy_sha256,
            "source": self.source,
            "staging": self.staging,
            "applied": self.applied,
            "allowed_files": [
                {
                    "relative_path": item.relative_path,
                    "reason": item.reason,
                    "size": item.size,
                    "sha256": item.sha256,
                }
                for item in self.included
            ],
            "blocked_files": blocked_files,
            "manual_review": [],
            "license_notes": [],
            "secret_scan": "fail" if blocked_files else "pass",
            "included": [item.__dict__ for item in self.included],
            "blocked": blocked_files,
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

URL_PATTERN = re.compile(r"\bhttps?://[^\s'\"<>)\]]+", re.IGNORECASE)
PROXY_URI_PATTERN = re.compile(r"\b(?:vless|vmess|trojan|ss)://[^\s'\"<>)\]]+", re.IGNORECASE)
PLACEHOLDER_HOSTS = (
    "example",
    "example.com",
    "example.org",
    "example.net",
    "example.invalid",
    "localhost",
    "127.0.0.1",
    "0.0.0.0",
)


def load_policy(path: Path) -> ImportPolicy:
    raw = path.read_bytes()
    data = json.loads(raw.decode("utf-8"))
    allow = list(data.get("allow", []))
    deny = list(data.get("deny", []))
    allowed_hosts = list(data.get("allowed_hosts", []))
    allow_binary = list(data.get("allow_binary", []))
    if not allow:
        raise ValueError("source import policy must define at least one allow pattern")
    return ImportPolicy(
        allow=allow,
        deny=deny,
        allowed_hosts=allowed_hosts,
        allow_binary=allow_binary,
        policy_sha256=hashlib.sha256(raw).hexdigest(),
    )


def scan_text(text: str, allowed_hosts: Iterable[str] = ()) -> list[SecretFinding]:
    findings: list[SecretFinding] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        for kind, pattern in SECRET_PATTERNS:
            if pattern.search(line):
                findings.append(SecretFinding(kind, line_number))
        for match in PROXY_URI_PATTERN.finditer(line):
            host = _host_from_proxy_uri(match.group(0))
            if not _is_allowed_host(host, allowed_hosts):
                findings.append(SecretFinding("proxy-uri", line_number))
        for match in URL_PATTERN.finditer(line):
            host = _host_from_url(match.group(0))
            if not _is_allowed_host(host, allowed_hosts):
                findings.append(SecretFinding("private-url", line_number))
    return findings


def plan_import(source: Path, staging: Path, policy: ImportPolicy, apply: bool = False) -> ImportResult:
    source = source.resolve()
    staging = staging.resolve()
    _validate_staging_path(source, staging, apply=apply)

    included: list[ImportItem] = []
    blocked: list[ImportItem] = []

    for file_path in sorted(path for path in source.rglob("*") if path.is_file()):
        relative_path = _relative_posix(source, file_path)
        if not _matches_any(relative_path, policy.allow):
            continue

        metadata = _file_metadata(file_path)
        deny_pattern = _first_match(relative_path, policy.deny)
        if deny_pattern:
            blocked.append(ImportItem(relative_path, f"deny:{deny_pattern}", **metadata))
            continue

        findings = _scan_file(file_path, relative_path, policy)
        if findings:
            blocked.append(ImportItem(relative_path, "secret-scan", findings=tuple(findings), **metadata))
            continue

        included.append(ImportItem(relative_path, "allow", **metadata))
        if apply:
            destination = staging / Path(relative_path)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(file_path, destination)

    return ImportResult(
        source=str(source),
        staging=str(staging),
        applied=apply,
        policy_sha256=policy.policy_sha256,
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


def _scan_file(path: Path, relative_path: str, policy: ImportPolicy) -> list[SecretFinding]:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        if _matches_any(relative_path, policy.allow_binary):
            return []
        return [SecretFinding("binary-unknown", 0)]
    return scan_text(text, policy.allowed_hosts)


def _file_metadata(path: Path) -> dict[str, int | str]:
    return {
        "size": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def _validate_staging_path(source: Path, staging: Path, apply: bool) -> None:
    if source == staging:
        raise ValueError("source and staging paths must be different")
    if _is_relative_to(staging, source):
        raise ValueError("staging path must not be inside the source tree")
    if _is_relative_to(source, staging):
        raise ValueError("source path must not be inside the staging tree")
    if (staging / ".git").exists():
        raise ValueError("staging path must not be a git repository root")
    if apply and staging.exists() and any(staging.iterdir()):
        raise ValueError("staging path must be empty before apply")


def _is_relative_to(child: Path, parent: Path) -> bool:
    try:
        child.relative_to(parent)
        return child != parent
    except ValueError:
        return False


def _host_from_url(value: str) -> str:
    try:
        return urlparse(re.sub(r"[.,;:]+$", "", value)).hostname or ""
    except Exception:
        return ""


def _host_from_proxy_uri(value: str) -> str:
    if "$" in value or "{" in value or "}" in value:
        return ""
    without_fragment = value.split("#", 1)[0]
    parsed = urlparse(without_fragment)
    if parsed.hostname:
        host = parsed.hostname.strip(".,;:")
        if not host or (not "." in host and not _is_private_ip_or_localhost(host) and host != "example"):
            return ""
        return host
    if parsed.scheme.lower() == "vmess":
        return ""
    return ""


def _is_allowed_host(host: str, allowed_hosts: Iterable[str]) -> bool:
    normalized = host.strip().lower().strip("[]")
    if not normalized:
        return True
    if (
        normalized in PLACEHOLDER_HOSTS
        or normalized.endswith(".example")
        or normalized.endswith(".example.com")
        or normalized.endswith(".example.org")
        or normalized.endswith(".example.net")
        or normalized.endswith(".invalid")
        or normalized.endswith(".test")
    ):
        return True
    if _is_private_ip_or_localhost(normalized):
        return False
    for pattern in allowed_hosts:
        candidate = pattern.strip().lower()
        if not candidate:
            continue
        if candidate.startswith("*.") and normalized.endswith(candidate[1:]):
            return True
        if normalized == candidate:
            return True
    return False


def _is_private_ip_or_localhost(host: str) -> bool:
    if host == "localhost":
        return True
    parts = host.split(".")
    if len(parts) != 4 or not all(part.isdigit() for part in parts):
        return False
    first, second = int(parts[0]), int(parts[1])
    return (
        first == 10
        or first == 127
        or (first == 172 and 16 <= second <= 31)
        or (first == 192 and second == 168)
    )


if __name__ == "__main__":
    raise SystemExit(main())
