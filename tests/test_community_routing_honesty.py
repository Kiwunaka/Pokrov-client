from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_public_warp_copy_does_not_claim_pokrov_service_operation() -> None:
    lifecycle = (
        ROOT
        / "packages"
        / "app_shell"
        / "lib"
        / "src"
        / "warp"
        / "pokrov_warp_lifecycle.dart"
    ).read_text(encoding="utf-8")
    app_shell = (
        ROOT / "packages" / "app_shell" / "lib" / "app_shell.dart"
    ).read_text(encoding="utf-8")

    forbidden_public_fragments = [
        "POKROV может временно",
        "POKROV временно вернулся",
        "POKROV не смог включить дополнительный режим",
        "POKROV покажет простой тумблер",
        "WARP-защита",
    ]

    for fragment in forbidden_public_fragments:
        assert fragment not in lifecycle
        assert fragment not in app_shell

    assert "Расширенная защита" in app_shell
    assert "Клиент не смог включить дополнительный режим" in lifecycle


def test_community_context_uses_local_profiles_not_service_free_node() -> None:
    app_shell = (
        ROOT / "packages" / "app_shell" / "lib" / "app_shell.dart"
    ).read_text(encoding="utf-8")

    assert "profile.isCommunity" in app_shell
    assert "AccessLane.localProfiles" in app_shell
    assert "nodePool: 'local-user-profiles'" in app_shell
    assert "profile.isCommunity ? AccessLane.freeMonthly" not in app_shell
