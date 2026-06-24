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
    ) -> tuple[int, dict[str, str], dict[str, object]]:
        payload = b""
        request_headers = {
            "Authorization": "Bearer operator-session-token-placeholder",
            "X-Request-ID": "test-request-id",
            "X-Client-Version": "0.1.0-source",
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
            response_headers = {
                key.lower(): value for key, value in response.getheaders()
            }
            return response.status, response_headers, json.loads(raw)
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


def test_operator_fixture_returns_request_id_api_version_and_session_lifecycle() -> None:
    with run_fixture() as client:
        status, headers, session = client.request(
            "POST",
            "/api/client/session/start-trial",
            {
                "install_id": "test-install",
                "platform": "windows",
                "app_version": "0.1.0-source",
            },
        )

    assert status == 200
    assert headers["x-request-id"] == "test-request-id"
    assert headers["x-api-version"] == "2026-06-operator-v1"
    assert session["session"]["token_type"] == "Bearer"
    assert session["session"]["expires_in"] == 3600
    assert session["session"]["refresh_after"] == 3000
    assert session["provisioning"]["managed_manifest"]["version"] == "operator-v1"


def test_operator_fixture_uses_standard_error_shape_and_retry_headers() -> None:
    with run_fixture() as client:
        status, headers, unauthorized = client.request(
            "GET", "/api/client/profile/managed?mode=401"
        )
        assert status == 401
        assert headers["x-request-id"] == "test-request-id"
        assert unauthorized == {
            "ok": False,
            "error": {
                "code": "unauthorized",
                "message": "Session is missing, expired, or rejected.",
                "request_id": "test-request-id",
                "retryable": False,
            },
        }

        status, headers, rate_limited = client.request(
            "GET", "/api/client/profile/managed?mode=429"
        )

    assert status == 429
    assert headers["retry-after"] == "60"
    assert rate_limited["error"]["code"] == "rate_limited"
    assert rate_limited["error"]["retry_after_seconds"] == 60
    assert rate_limited["error"]["request_id"] == "test-request-id"


def test_operator_contract_docs_define_versioning_deprecation_and_errors() -> None:
    docs = "\n".join(
        [
            (ROOT / "docs" / "OPERATOR_INTEGRATION.md").read_text(encoding="utf-8"),
            (ROOT / "docs" / "operator" / "openapi.yaml").read_text(
                encoding="utf-8"
            ),
        ]
    )

    for phrase in (
        "X-Request-ID",
        "X-Client-Version",
        "X-API-Version",
        "Retry-After",
        "Deprecation",
        "Sunset",
        "error.code",
        "rate_limited",
        "session_token",
        "expires_in",
        "refresh_after",
        "operator-v1",
    ):
        assert phrase in docs


def test_operator_fixture_seed_records_contract_policy() -> None:
    fixture = json.loads(
        (ROOT / "config" / "operator-api.fixture.json").read_text(encoding="utf-8")
    )
    contract = fixture["contract"]

    assert contract["version"] == "2026-06-operator-v1"
    assert contract["request_id_header"] == "X-Request-ID"
    assert contract["client_version_header"] == "X-Client-Version"
    assert contract["response_version_header"] == "X-API-Version"
    assert contract["rate_limit_header"] == "Retry-After"
    assert contract["deprecation_headers"] == ["Deprecation", "Sunset"]
    assert contract["session"]["token_type"] == "Bearer"
    assert contract["session"]["expires_in_seconds"] == 3600
    assert contract["errors"]["shape"] == "ok_false_error_object_v1"
    assert {"unauthorized", "rate_limited", "server_error"}.issubset(
        set(contract["errors"]["codes"])
    )


def test_operator_support_contract_matches_app_adapter_paths() -> None:
    docs = "\n".join(
        [
            (ROOT / "docs" / "OPERATOR_INTEGRATION.md").read_text(encoding="utf-8"),
            (ROOT / "docs" / "operator" / "openapi.yaml").read_text(
                encoding="utf-8"
            ),
        ]
    )
    fixture = json.loads(
        (ROOT / "config" / "operator-api.fixture.json").read_text(encoding="utf-8")
    )
    variant = json.loads(
        (ROOT / "config" / "variants" / "operator-client.seed.json").read_text(
            encoding="utf-8"
        )
    )

    assert fixture["endpoints"]["support_tickets"]["path"] == "/api/tickets"
    assert "GET /api/tickets" in variant["required_api_contracts"]
    assert (
        "POST /api/tickets/{ticket_id}/messages"
        in variant["required_api_contracts"]
    )
    assert "/api/tickets" in docs
    assert "/api/client/support/tickets" not in docs
