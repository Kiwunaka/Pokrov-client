from __future__ import annotations

import argparse
import json
import os
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_FIXTURE_PATH = REPO_ROOT / "config" / "operator-api.fixture.json"
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8765
DEFAULT_CONTRACT_VERSION = "2026-06-operator-v1"
DEMO_TICKET = {
    "id": "demo-ticket-1",
    "subject": "Demo ticket",
    "status": "open",
    "updated_at": "2026-06-13T00:00:00Z",
}


def load_fixture(path: Path = DEFAULT_FIXTURE_PATH) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as fixture_file:
        return json.load(fixture_file)


def _endpoint_response(
    fixture: dict[str, Any],
    endpoint_key: str,
    fallback: dict[str, Any],
) -> dict[str, Any]:
    endpoint = fixture.get("endpoints", {}).get(endpoint_key, {})
    response = endpoint.get("response")
    return response if isinstance(response, dict) else fallback


class OperatorFixtureHandler(BaseHTTPRequestHandler):
    fixture: dict[str, Any] = {}
    default_mode = "success"
    server_version = "PokrovOperatorFixture/0.1"

    def log_message(self, format: str, *args: Any) -> None:
        if os.environ.get("OPERATOR_FIXTURE_VERBOSE") == "1":
            super().log_message(format, *args)

    def do_GET(self) -> None:
        self._handle("GET")

    def do_POST(self) -> None:
        self._handle("POST")

    def _handle(self, method: str) -> None:
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/") or "/"
        query = parse_qs(parsed.query)
        mode = self._mode(query)

        if mode == "timeout":
            time.sleep(2.0)

        if mode == "401" and path != "/health":
            self._send_error(
                HTTPStatus.UNAUTHORIZED,
                "unauthorized",
                "Session is missing, expired, or rejected.",
                retryable=False,
            )
            return

        if mode == "429" and path != "/health":
            self._send_error(
                HTTPStatus.TOO_MANY_REQUESTS,
                "rate_limited",
                "Too many requests. Retry after the advertised delay.",
                retryable=True,
                retry_after_seconds=60,
            )
            return

        if mode == "500" and path != "/health":
            self._send_error(
                HTTPStatus.INTERNAL_SERVER_ERROR,
                "server_error",
                "Operator fixture server error mode.",
                retryable=True,
            )
            return

        if method == "GET" and path == "/health":
            self._send_json(
                HTTPStatus.OK,
                {
                    "ok": True,
                    "service": "operator-api-fixture",
                    "mode": mode,
                },
            )
            return

        if method == "POST" and path == "/api/client/session/start-trial":
            self._read_json_body()
            self._send_json(
                HTTPStatus.OK,
                _endpoint_response(self.fixture, "start_trial", {}),
            )
            return

        if method == "POST" and path == "/api/client/route-policy":
            self._read_json_body()
            self._send_json(
                HTTPStatus.OK,
                _endpoint_response(self.fixture, "route_policy", {"ok": True}),
            )
            return

        if method == "GET" and path == "/api/client/profile/managed":
            if mode == "malformed-profile":
                self._send_json(
                    HTTPStatus.OK,
                    {
                        "profile_name": "",
                        "materialized_for_runtime": False,
                        "config": "not-a-runtime-config",
                    },
                )
                return
            self._send_json(
                HTTPStatus.OK,
                _endpoint_response(self.fixture, "managed_profile", {}),
            )
            return

        if method == "POST" and path in ("/api/redeem", "/api/client/redeem"):
            self._read_json_body()
            self._send_json(
                HTTPStatus.OK,
                _endpoint_response(self.fixture, "redeem", {"ok": True}),
            )
            return

        if method == "GET" and path == "/api/client/apps":
            self._send_json(
                HTTPStatus.OK,
                _endpoint_response(self.fixture, "apps", {}),
            )
            return

        if method == "POST" and path == "/api/client/cabinet-token":
            self._read_json_body()
            self._send_json(
                HTTPStatus.OK,
                _endpoint_response(self.fixture, "cabinet_token", {}),
            )
            return

        if method == "POST" and path == "/api/client/telegram/link":
            self._read_json_body()
            self._send_json(HTTPStatus.OK, {"ok": True, "linked": True})
            return

        if method == "GET" and path == "/api/client/bonus/summary":
            self._send_json(HTTPStatus.OK, {"ok": True, "bonuses": []})
            return

        if method == "POST" and path in (
            "/api/client/warp/consent",
            "/api/client/warp/revoke",
        ):
            self._read_json_body()
            consented = path.endswith("/consent")
            self._send_json(
                HTTPStatus.OK,
                {
                    "consented": consented,
                    "state": "ready" if consented else "revoked",
                    "public_label": "Extended protection",
                },
            )
            return

        if method == "POST" and path == "/api/client/nodes/preference":
            self._read_json_body()
            self._send_json(HTTPStatus.OK, {"ok": True, "applied": True})
            return

        if path == "/api/tickets":
            if method == "GET":
                self._send_json(
                    HTTPStatus.OK,
                    _endpoint_response(
                        self.fixture,
                        "support_tickets",
                        {"tickets": [DEMO_TICKET]},
                    ),
                )
                return
            if method == "POST":
                body = self._read_json_body()
                subject = str(body.get("subject") or "Demo ticket").strip()
                ticket = {
                    **DEMO_TICKET,
                    "id": "demo-ticket-created",
                    "subject": subject or "Demo ticket",
                }
                self._send_json(HTTPStatus.CREATED, {"ticket": ticket})
                return

        support_prefix = "/api/tickets/"
        if path.startswith(support_prefix):
            parts = path[len(support_prefix) :].split("/")
            ticket_id = parts[0] if parts else ""
            if method == "GET" and len(parts) == 1:
                self._send_json(
                    HTTPStatus.OK,
                    {"ticket": {**DEMO_TICKET, "id": ticket_id}},
                )
                return
            if method == "POST" and len(parts) == 2 and parts[1] == "messages":
                body = self._read_json_body()
                self._send_json(
                    HTTPStatus.CREATED,
                    {
                        "message": {
                            "id": "demo-message-1",
                            "ticket_id": ticket_id,
                            "body": str(body.get("message") or ""),
                            "created_at": "2026-06-13T00:00:00Z",
                        }
                    },
                )
                return

        self._send_json(
            HTTPStatus.NOT_FOUND,
            {
                "ok": False,
                "error": {
                    "code": "not_found",
                    "message": f"No fixture route for {method} {path}",
                    "request_id": self._request_id(),
                    "retryable": False,
                },
            },
        )

    def _mode(self, query: dict[str, list[str]]) -> str:
        query_mode = query.get("mode", [""])[0].strip()
        header_mode = self.headers.get("X-Fixture-Mode", "").strip()
        return query_mode or header_mode or self.default_mode

    def _read_json_body(self) -> dict[str, Any]:
        raw_length = self.headers.get("Content-Length", "0")
        try:
            length = int(raw_length)
        except ValueError:
            length = 0
        if length <= 0:
            return {}
        body = self.rfile.read(length).decode("utf-8")
        try:
            decoded = json.loads(body)
        except json.JSONDecodeError:
            return {}
        return decoded if isinstance(decoded, dict) else {}

    def _request_id(self) -> str:
        request_id = self.headers.get("X-Request-ID", "").strip()
        return request_id or "fixture-request"

    def _contract_version(self) -> str:
        contract = self.fixture.get("contract", {})
        version = contract.get("version")
        return version if isinstance(version, str) and version else DEFAULT_CONTRACT_VERSION

    def _send_error(
        self,
        status: HTTPStatus,
        code: str,
        message: str,
        *,
        retryable: bool,
        retry_after_seconds: int | None = None,
    ) -> None:
        error: dict[str, Any] = {
            "code": code,
            "message": message,
            "request_id": self._request_id(),
            "retryable": retryable,
        }
        headers: dict[str, str] = {}
        if retry_after_seconds is not None:
            error["retry_after_seconds"] = retry_after_seconds
            headers["Retry-After"] = str(retry_after_seconds)

        self._send_json(
            status,
            {
                "ok": False,
                "error": error,
            },
            extra_headers=headers,
        )

    def _send_json(
        self,
        status: HTTPStatus,
        payload: dict[str, Any],
        *,
        extra_headers: dict[str, str] | None = None,
    ) -> None:
        encoded = json.dumps(payload, ensure_ascii=False, sort_keys=True).encode(
            "utf-8"
        )
        self.send_response(status.value)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("X-Request-ID", self._request_id())
        self.send_header("X-API-Version", self._contract_version())
        if extra_headers:
            for key, value in extra_headers.items():
                self.send_header(key, value)
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)


def build_server(
    host: str = DEFAULT_HOST,
    port: int = DEFAULT_PORT,
    fixture_path: Path = DEFAULT_FIXTURE_PATH,
    mode: str = "success",
) -> ThreadingHTTPServer:
    fixture = load_fixture(fixture_path)

    class BoundOperatorFixtureHandler(OperatorFixtureHandler):
        pass

    BoundOperatorFixtureHandler.fixture = fixture
    BoundOperatorFixtureHandler.default_mode = mode
    return ThreadingHTTPServer((host, port), BoundOperatorFixtureHandler)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run the operator API fixture.")
    parser.add_argument("--host", default=DEFAULT_HOST)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--fixture", type=Path, default=DEFAULT_FIXTURE_PATH)
    parser.add_argument(
        "--mode",
        default="success",
        choices=["success", "401", "429", "500", "malformed-profile", "timeout"],
    )
    args = parser.parse_args(argv)

    server = build_server(
        host=args.host,
        port=args.port,
        fixture_path=args.fixture,
        mode=args.mode,
    )
    print(f"Operator fixture listening on http://{args.host}:{args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("Stopping operator fixture")
    finally:
        server.server_close()
    return 0
