from __future__ import annotations

import json
import threading
from contextlib import contextmanager
from http.client import HTTPConnection
from pathlib import Path

from tools.operator_fixture_server.server import build_server


ROOT = Path(__file__).resolve().parents[1]


class FixtureClient:
    def __init__(self, host: str, port: int):
        self.host = host
        self.port = port

    def request(
        self,
        method: str,
        path: str,
        body: dict[str, object] | None = None,
        headers: dict[str, str] | None = None,
    ) -> tuple[int, dict[str, object]]:
        payload = b""
        request_headers = {
            "Authorization": "Bearer operator-session-token-placeholder",
        }
        if headers:
            request_headers.update(headers)
        if body is not None:
            payload = json.dumps(body).encode("utf-8")
            request_headers["Content-Type"] = "application/json"
            request_headers["Content-Length"] = str(len(payload))

        connection = HTTPConnection(self.host, self.port, timeout=5)
        try:
            connection.request(method, path, body=payload, headers=request_headers)
            response = connection.getresponse()
            raw = response.read().decode("utf-8")
            return response.status, json.loads(raw)
        finally:
            connection.close()


@contextmanager
def run_fixture():
    server = build_server(port=0)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    host, port = server.server_address
    try:
        yield FixtureClient(host, port)
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


def test_fixture_serves_bootstrap_profile_apps_and_support():
    with run_fixture() as client:
        status, health = client.request("GET", "/health", headers={})
        assert status == 200
        assert health["ok"] is True

        status, session = client.request(
            "POST",
            "/api/client/session/start-trial",
            {
                "install_id": "test-install",
                "platform": "windows",
                "app_version": "0.1.0-source",
            },
        )
        assert status == 200
        assert session["session"]["session_token"]
        assert (
            session["provisioning"]["managed_manifest"]["url"]
            == "/api/client/profile/managed"
        )

        status, route = client.request(
            "POST",
            "/api/client/route-policy",
            {"route_mode": "all", "selected_apps": []},
        )
        assert status == 200
        assert route["ok"] is True

        status, profile = client.request("GET", "/api/client/profile/managed")
        assert status == 200
        assert profile["materialized_for_runtime"] is True
        assert isinstance(profile["config"], dict)

        status, apps = client.request(
            "GET",
            "/api/client/apps?platform=windows&current_version=0.1.0-source",
        )
        assert status == 200
        assert apps["update_check"]["silent_update"] is False

        status, tickets = client.request("GET", "/api/tickets")
        assert status == 200
        assert tickets["tickets"][0]["id"] == "demo-ticket-1"


def test_fixture_error_modes_are_available():
    with run_fixture() as client:
        status, unauthorized = client.request(
            "GET", "/api/client/profile/managed?mode=401"
        )
        assert status == 401
        assert unauthorized["ok"] is False

        status, server_error = client.request(
            "GET", "/api/client/profile/managed?mode=500"
        )
        assert status == 500
        assert server_error["ok"] is False

        status, malformed = client.request(
            "GET", "/api/client/profile/managed?mode=malformed-profile"
        )
        assert status == 200
        assert malformed["materialized_for_runtime"] is False
        assert not isinstance(malformed["config"], dict)


def test_operator_contract_files_do_not_point_at_official_pokrov_hosts():
    checked_paths = [
        ROOT / "config" / "operator-api.fixture.json",
        ROOT / "docs" / "operator" / "openapi.yaml",
    ]
    forbidden = [
        "api.pokrov.space",
        "app.pokrov.space",
        "pay.pokrov.space",
        "connect.pokrov.space",
        "kiwunaka.space",
    ]

    for path in checked_paths:
        text = path.read_text(encoding="utf-8")
        for value in forbidden:
            assert value not in text, f"{value} leaked into {path}"


def test_openapi_mentions_current_runtime_endpoints():
    text = (ROOT / "docs" / "operator" / "openapi.yaml").read_text(
        encoding="utf-8"
    )
    required_paths = [
        "/api/client/session/start-trial",
        "/api/client/route-policy",
        "/api/client/profile/managed",
        "/api/redeem",
        "/api/client/apps",
        "/api/tickets",
    ]
    for path in required_paths:
        assert path in text
