from __future__ import annotations

import base64
import json
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlparse


SUPPORTED_PROTOCOLS = {"vless", "trojan", "ss", "vmess"}


@dataclass(frozen=True)
class CatalogEntry:
    raw: str
    scheme: str
    normalized_uri: str


@dataclass(frozen=True)
class CatalogRejectedEntry:
    raw: str
    reason: str


@dataclass(frozen=True)
class CatalogParseResult:
    accepted: tuple[CatalogEntry, ...]
    rejected: tuple[CatalogRejectedEntry, ...]


def load_catalog(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def parse_subscription_text(value: str) -> CatalogParseResult:
    body = value.strip()
    if not body:
        return CatalogParseResult(accepted=(), rejected=())

    lines = _lines(body)
    if not any(_looks_like_proxy_uri(line) for line in lines):
        decoded = _decode_maybe_base64(body)
        if decoded != body:
            lines = _lines(decoded)

    accepted: list[CatalogEntry] = []
    rejected: list[CatalogRejectedEntry] = []
    seen: set[str] = set()
    for line in lines:
        if not line or line.startswith("#"):
            continue
        parsed = urlparse(line)
        scheme = parsed.scheme.lower()
        if scheme not in SUPPORTED_PROTOCOLS:
            rejected.append(
                CatalogRejectedEntry(raw=line, reason="unsupported_protocol")
            )
            continue
        if not parsed.netloc and scheme != "vmess":
            rejected.append(CatalogRejectedEntry(raw=line, reason="missing_host"))
            continue

        normalized = line.strip()
        if normalized in seen:
            rejected.append(CatalogRejectedEntry(raw=line, reason="duplicate"))
            continue
        seen.add(normalized)
        accepted.append(
            CatalogEntry(raw=line, scheme=scheme, normalized_uri=normalized)
        )

    return CatalogParseResult(
        accepted=tuple(accepted),
        rejected=tuple(rejected),
    )


def catalog_gate_summary(catalog: dict[str, object]) -> dict[str, object]:
    refresh_policy = _as_dict(catalog.get("refresh_policy"))
    parser_contract = _as_dict(catalog.get("parser_contract"))
    sources = catalog.get("sources")
    source_count = len(sources) if isinstance(sources, list) else 0
    return {
        "enabled_by_default": catalog.get("enabled_by_default"),
        "requires_user_opt_in": catalog.get("requires_user_opt_in"),
        "official_pokrov_nodes": catalog.get("official_pokrov_nodes"),
        "source_count": source_count,
        "parser_version": parser_contract.get("version"),
        "supported_protocols": parser_contract.get("supported_protocols"),
        "offline_behavior": refresh_policy.get("offline_behavior"),
        "raw_unavailable_behavior": refresh_policy.get("raw_unavailable_behavior"),
    }


def _lines(value: str) -> list[str]:
    return [
        line.strip()
        for line in value.replace("\r", "\n").split("\n")
        if line.strip()
    ]


def _looks_like_proxy_uri(value: str) -> bool:
    scheme = urlparse(value).scheme.lower()
    return scheme in SUPPORTED_PROTOCOLS


def _decode_maybe_base64(value: str) -> str:
    compact = "".join(value.split())
    if not compact:
        return value
    padding = "=" * (-len(compact) % 4)
    try:
        decoded = base64.urlsafe_b64decode((compact + padding).encode("ascii"))
        return decoded.decode("utf-8")
    except (UnicodeDecodeError, ValueError):
        return value


def _as_dict(value: object) -> dict[str, object]:
    return value if isinstance(value, dict) else {}
