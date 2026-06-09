import json
from pathlib import Path


def test_free_vpn_catalog_candidate_is_gated_and_attributed() -> None:
    catalog = json.loads(Path("config/free-vpn-catalog.seed.json").read_text())

    assert catalog["enabled_by_default"] is False
    assert catalog["requires_user_opt_in"] is True
    assert catalog["official_pokrov_nodes"] is False

    source = catalog["sources"][0]
    assert source["id"] == "avencores-goida-vpn-configs"
    assert source["license"] == "GPL-3.0"
    assert source["attribution"]
    assert source["label"] == "Third-party public configs"
    assert source["review_status"] == "reviewed_candidate_disabled"
    assert source["feeds"]


def test_free_vpn_catalog_copy_keeps_third_party_boundary() -> None:
    catalog = json.loads(Path("config/free-vpn-catalog.seed.json").read_text())
    copy = " ".join(catalog["ui_copy"])

    assert "not official POKROV nodes" in copy
    forbidden_claims = ["fastest", "safest", "private", "uptime", "legal"]
    assert not any(claim in copy.lower() for claim in forbidden_claims)
