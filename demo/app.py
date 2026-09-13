"""Board-hosted HTTP dashboard for the deterministic ITCH showcase demo."""

from __future__ import annotations

import argparse
import asyncio
import copy
import json
import mimetypes
import threading
import traceback
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse

from hardware import HardwareReplay
from oracle import OracleVerifier


ROOT = Path(__file__).resolve().parent
STATIC_DIR = ROOT / "static"
GRAPH_HISTORY_LIMIT = 320
GRAPH_WARMUP_BBO_UPDATES = 50


class DemoState:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._state = self._new_state()

    @staticmethod
    def _new_state() -> dict:
        return {
            "status": "IDLE",
            "detail": "Ready for deterministic oracle-verified board replay.",
            "error": None,
            "progress": {
                "source_messages": 0,
                "message_limit": 0,
                "dma_packets": 0,
                "bbo_updates": 0,
            },
            "mappings": {},
            "stocks": {
                symbol: {
                    "bid_price": None,
                    "bid_size": None,
                    "ask_price": None,
                    "ask_size": None,
                    "spread": None,
                    "history": [],
                    "history_total": 0,
                    "history_limit": GRAPH_HISTORY_LIMIT,
                }
                for symbol in ("AAPL", "MSFT", "NFLX")
            },
            "verification": {
                "enabled": True,
                "expected_total": 0,
                "expected_by_stock": {},
                "observed_by_stock": {},
                "comparisons": 0,
                "mismatches": 0,
                "latched_fail": False,
                "first_mismatch": None,
            },
        }

    def begin(self, message_limit: int, verification: dict) -> None:
        with self._lock:
            self._state = self._new_state()
            self._state["status"] = "INITIALISING"
            self._state["detail"] = "Programming FPGA and opening local Nasdaq data."
            self._state["progress"]["message_limit"] = int(message_limit)
            self._state["verification"].update(copy.deepcopy(verification))

    def running(self) -> None:
        with self._lock:
            self._state["status"] = "RUNNING"
            self._state["detail"] = "Deterministic DMA replay in progress."

    def progress(
        self,
        source_messages: int,
        message_limit: int,
        dma_packets: int,
    ) -> None:
        with self._lock:
            self._state["progress"]["source_messages"] = int(source_messages)
            self._state["progress"]["message_limit"] = int(message_limit)
            self._state["progress"]["dma_packets"] = int(dma_packets)

    def mapping(self, symbol: str, stock_id: int, locate: int) -> None:
        with self._lock:
            self._state["mappings"][symbol] = {
                "stock_id": int(stock_id),
                "locate": int(locate),
            }

    def bbo(
        self,
        symbol: str,
        bid_price: int,
        bid_size: int,
        ask_price: int,
        ask_size: int,
        comparison: dict,
    ) -> None:
        with self._lock:
            stock = self._state["stocks"][symbol]

            # Hardware uses zero for an empty side. The dashboard shows it as —.
            bid_valid = int(bid_price) if int(bid_size) != 0 else None
            ask_valid = int(ask_price) if int(ask_size) != 0 else None

            stock["bid_price"] = bid_valid
            stock["bid_size"] = int(bid_size) if bid_valid is not None else None
            stock["ask_price"] = ask_valid
            stock["ask_size"] = int(ask_size) if ask_valid is not None else None

            if bid_valid is not None and ask_valid is not None:
                stock["spread"] = ask_valid - bid_valid
            else:
                stock["spread"] = None

            history_index = int(stock["history_total"])
            stock["history_total"] = history_index + 1

            # Keep the first BBO updates available to the verifier and counters,
            # but never expose them to the graph. Early book-population states can
            # otherwise dominate the y-axis until they age out of the display
            # history window.
            if history_index >= GRAPH_WARMUP_BBO_UPDATES:
                stock["history"].append(
                    {
                        "index": history_index,
                        "bid": bid_valid,
                        "ask": ask_valid,
                    }
                )
                if len(stock["history"]) > GRAPH_HISTORY_LIMIT:
                    del stock["history"][:-GRAPH_HISTORY_LIMIT]

            self._state["progress"]["bbo_updates"] += 1
            self._state["verification"]["comparisons"] = comparison["comparisons"]
            self._state["verification"]["mismatches"] = comparison["mismatches"]
            self._state["verification"]["latched_fail"] = comparison["latched_fail"]

            observed = self._state["verification"].setdefault(
                "observed_by_stock",
                {},
            )
            observed[symbol] = int(comparison["bbo_index"]) + 1

            if (
                comparison["latched_fail"]
                and self._state["verification"]["first_mismatch"] is None
            ):
                self._state["verification"]["first_mismatch"] = {
                    "symbol": comparison["symbol"],
                    "bbo_index": comparison["bbo_index"],
                    "expected": comparison["expected"],
                    "actual": comparison["actual"],
                }

    def complete(self, summary: dict, verification: dict) -> None:
        with self._lock:
            self._state["progress"]["source_messages"] = summary["source_messages"]
            self._state["progress"]["dma_packets"] = summary["dma_packets"]
            self._state["progress"]["bbo_updates"] = summary["bbo_updates"]
            self._state["verification"] = copy.deepcopy(verification)

            if verification["latched_fail"]:
                self._state["status"] = "FAIL"
                self._state["detail"] = (
                    "Replay completed, but hardware output did not match the oracle."
                )
            else:
                self._state["status"] = "PASS"
                self._state["detail"] = (
                    "Replay completed. All three hardware BBO streams match the "
                    "pre-generated Python oracle."
                )

    def fail(self, message: str) -> None:
        with self._lock:
            self._state["status"] = "FAIL"
            self._state["detail"] = "Demo execution failed before a valid verdict."
            self._state["error"] = message
            self._state["verification"]["latched_fail"] = True

    def snapshot(self) -> dict:
        with self._lock:
            return copy.deepcopy(self._state)


class DemoApplication:
    def __init__(
        self,
        bitstream: Path,
        data: Path,
        oracle: Path,
        message_limit: int | None,
    ) -> None:
        self.bitstream = bitstream
        self.data = data
        self.oracle = oracle
        self.message_limit = None if message_limit is None else int(message_limit)
        self.state = DemoState()
        self._worker_lock = threading.Lock()
        self._worker: threading.Thread | None = None

    def start_run(self) -> bool:
        with self._worker_lock:
            if self._worker is not None and self._worker.is_alive():
                return False

            # Validate the oracle before spawning any hardware work.
            verifier = OracleVerifier(
                self.oracle,
                message_limit=self.message_limit,
            )
            run_message_limit = verifier.message_limit
            initial_verification = verifier.snapshot()
            self.state.begin(run_message_limit, initial_verification)

            self._worker = threading.Thread(
                target=self._run_worker,
                args=(verifier, run_message_limit),
                name="fpga-demo-replay",
                daemon=True,
            )
            self._worker.start()
            return True

    def _run_worker(
        self,
        verifier: OracleVerifier,
        message_limit: int,
    ) -> None:
        # PYNQ's embedded XRT backend asks asyncio for the current event loop
        # during device discovery. Python 3.10 does not create one
        # automatically for a non-main thread.
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        try:
            def on_bbo(
                symbol: str,
                bid_price: int,
                bid_size: int,
                ask_price: int,
                ask_size: int,
            ) -> None:
                comparison = verifier.observe(
                    symbol,
                    bid_price,
                    bid_size,
                    ask_price,
                    ask_size,
                )
                self.state.bbo(
                    symbol,
                    bid_price,
                    bid_size,
                    ask_price,
                    ask_size,
                    comparison,
                )

            replay = HardwareReplay(
                bitstream_path=self.bitstream,
                data_path=self.data,
                message_limit=message_limit,
                on_ready=self.state.running,
                on_progress=self.state.progress,
                on_mapping=self.state.mapping,
                on_bbo=on_bbo,
            )

            summary = replay.run()
            verification = verifier.finalise(
                source_messages=summary["source_messages"],
                workload_sha256=summary["workload_sha256"],
            )
            self.state.complete(summary, verification)

        except Exception as exc:
            traceback.print_exc()
            self.state.fail(f"{type(exc).__name__}: {exc}")

        finally:
            loop.close()


def make_handler(application: DemoApplication):
    class DemoHandler(BaseHTTPRequestHandler):
        server_version = "ITCHDemo/2.0"

        def _send_json(self, payload: dict, status: int = HTTPStatus.OK) -> None:
            raw = json.dumps(payload, separators=(",", ":")).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(raw)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(raw)

        def _serve_static(self, request_path: str) -> None:
            if request_path in {"", "/"}:
                relative = Path("index.html")
            else:
                relative = Path(unquote(request_path.lstrip("/")))

            candidate = (STATIC_DIR / relative).resolve()
            try:
                candidate.relative_to(STATIC_DIR.resolve())
            except ValueError:
                self.send_error(HTTPStatus.FORBIDDEN)
                return

            if not candidate.is_file():
                self.send_error(HTTPStatus.NOT_FOUND)
                return

            content = candidate.read_bytes()
            content_type, _ = mimetypes.guess_type(str(candidate))
            self.send_response(HTTPStatus.OK)
            self.send_header(
                "Content-Type",
                content_type or "application/octet-stream",
            )
            self.send_header("Content-Length", str(len(content)))
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
            self.send_header("Pragma", "no-cache")
            self.send_header("Expires", "0")
            self.end_headers()
            self.wfile.write(content)

        def do_GET(self) -> None:
            parsed = urlparse(self.path)
            if parsed.path == "/api/state":
                self._send_json(application.state.snapshot())
                return
            self._serve_static(parsed.path)

        def do_POST(self) -> None:
            parsed = urlparse(self.path)
            if parsed.path != "/api/run":
                self.send_error(HTTPStatus.NOT_FOUND)
                return

            try:
                started = application.start_run()
            except Exception as exc:
                self._send_json(
                    {"ok": False, "error": f"{type(exc).__name__}: {exc}"},
                    status=HTTPStatus.BAD_REQUEST,
                )
                return

            if not started:
                self._send_json(
                    {"ok": False, "error": "A replay is already running."},
                    status=HTTPStatus.CONFLICT,
                )
                return

            self._send_json({"ok": True}, status=HTTPStatus.ACCEPTED)

        def log_message(self, fmt: str, *args) -> None:
            message = fmt % args
            # Polling is intentionally frequent; suppress only that repetitive
            # success line so the PuTTY terminal remains useful for real errors.
            if '"GET /api/state HTTP/' in message and " 200 " in message:
                return
            print(f"[http] {self.address_string()} - {message}")

    return DemoHandler


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Board-side ITCH visual demo")
    parser.add_argument(
        "--bitstream",
        type=Path,
        default=ROOT / "overlay" / "v4release.bit",
    )
    parser.add_argument(
        "--data",
        type=Path,
        default=ROOT / "data" / "12302019.NASDAQ_ITCH50.gz",
    )
    parser.add_argument(
        "--oracle",
        type=Path,
        default=ROOT / "oracle" / "demo_oracle.json",
    )
    parser.add_argument(
        "--message-limit",
        type=int,
        default=None,
        help=(
            "Optional safety override. By default the exact source-message "
            "limit is read from the generated oracle metadata."
        ),
    )
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8080)
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    application = DemoApplication(
        bitstream=args.bitstream.resolve(),
        data=args.data.resolve(),
        oracle=args.oracle.resolve(),
        message_limit=args.message_limit,
    )

    server = ThreadingHTTPServer(
        (args.host, args.port),
        make_handler(application),
    )

    print("ITCH visual demo")
    print(f"  bitstream:     {application.bitstream}")
    print(f"  data:          {application.data}")
    print(f"  oracle:        {application.oracle}")
    if application.message_limit is None:
        print("  message limit: from oracle metadata")
    else:
        print(f"  message limit: {application.message_limit:,} (override)")
    print(f"  listen:        http://{args.host}:{args.port}")
    print()
    print("Open the board IP in your laptop browser, e.g.")
    print(f"  http://192.168.2.99:{args.port}")
    print("Press Ctrl+C to stop the server.")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping demo server.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
