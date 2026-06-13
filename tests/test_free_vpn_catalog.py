import json
from pathlib import Path

from tools.free_vpn_catalog.catalog_gate import (
    catalog_gate_summary,
    parse_subscription_text,
)


ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "config" / "free-vpn-catalog.seed.json"
FIXTURE_ROOT = ROOT / "tests" / "fixtures" / "free_vpn_catalog"


def test_free_vpn_catalog_candidate_is_gated_and_attributed() -> None:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))

    assert catalog["enabled_by_default"] is False
    assert catalog["requires_user_opt_in"] is True
    assert catalog["official_pokrov_nodes"] is False
    assert catalog["refresh_policy"]["mode"] == "manual"
    assert catalog["refresh_policy"]["cache_locally"] is True
    assert (
        catalog["refresh_policy"]["cache_storage"]
        == "local_profile_records_with_source_kind_third_party_catalog"
    )
    assert catalog["refresh_policy"]["entry_source_kind"] == "third_party_catalog"
    assert catalog["refresh_policy"]["manual_import_action_required"] is True
    assert catalog["refresh_policy"]["clear_action_required"] is True
    assert (
        catalog["refresh_policy"]["clear_action_scope"]
        == "third_party_catalog_profiles_only"
    )
    assert catalog["refresh_policy"]["candidate_default_feed_id"] == "githubmirror-1"
    assert catalog["refresh_policy"]["offline_behavior"]
    assert catalog["refresh_policy"]["raw_unavailable_behavior"]

    source = catalog["sources"][0]
    assert source["id"] == "avencores-goida-vpn-configs"
    assert source["license"] == "GPL-3.0"
    assert source["attribution"]
    assert source["label"] == "Third-party public configs"
    assert source["review_status"] == "reviewed_candidate_disabled"
    assert source["update_cadence"]
    assert source["freshness_expectation"]
    assert source["feeds"]
    assert any(
        feed["id"] == catalog["refresh_policy"]["candidate_default_feed_id"]
        for feed in source["feeds"]
    )


def test_free_vpn_catalog_copy_keeps_third_party_boundary() -> None:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    copy = " ".join(catalog["ui_copy"])

    assert "not official POKROV nodes" in copy
    assert "stores imported entries locally" in copy
    assert "clear them" in copy
    forbidden_claims = ["fastest", "safest", "private", "uptime", "legal"]
    assert not any(claim in copy.lower() for claim in forbidden_claims)


def test_catalog_parser_contract_matches_seed_metadata() -> None:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    contract = catalog["parser_contract"]

    assert contract["version"] == "subscription-text-v1"
    assert contract["supported_formats"] == ["subscription_text"]
    assert contract["supported_protocols"] == ["vless", "trojan", "ss", "vmess"]
    assert contract["malformed_entry_policy"] == "isolate_and_continue"
    assert contract["unsupported_protocol_policy"] == "ignore_with_reason"
    assert contract["dedupe_key"] == "normalized_uri"


def test_subscription_text_fixture_isolates_unsupported_and_malformed_entries() -> None:
    fixture = (FIXTURE_ROOT / "avencores_subscription_text.txt").read_text(
        encoding="utf-8"
    )
    result = parse_subscription_text(fixture)

    assert [entry.scheme for entry in result.accepted] == [
        "vless",
        "trojan",
        "ss",
        "vmess",
    ]
    assert {entry.reason for entry in result.rejected} == {
        "unsupported_protocol",
        "duplicate",
    }
    assert all("pokrov.space" not in entry.raw for entry in result.accepted)


def test_base64_subscription_fixture_is_supported() -> None:
    fixture = (FIXTURE_ROOT / "subscription_text_base64.txt").read_text(
        encoding="utf-8"
    )
    result = parse_subscription_text(fixture)

    assert [entry.scheme for entry in result.accepted] == ["vless", "trojan"]
    assert result.rejected == ()


def test_catalog_gate_summary_keeps_catalog_disabled() -> None:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    summary = catalog_gate_summary(catalog)

    assert summary == {
        "enabled_by_default": False,
        "requires_user_opt_in": True,
        "official_pokrov_nodes": False,
        "source_count": 1,
        "parser_version": "subscription-text-v1",
        "supported_protocols": ["vless", "trojan", "ss", "vmess"],
        "offline_behavior": "show_cached_entries_if_present_otherwise_empty",
        "raw_unavailable_behavior": "preserve_previous_imported_entries",
    }
