#!/usr/bin/env python3
"""Combine raw full-chain performance JSON into concise JSON and Markdown."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


LATENCY_METRICS = (
    "frame_first_to_external_bbo_cycles",
    "frame_last_to_external_bbo_cycles",
    "itch_first_to_external_bbo_cycles",
    "decoded_to_internal_bbo_cycles",
    "internal_to_external_bbo_cycles",
    "decoded_to_external_bbo_cycles",
)

THROUGHPUT_METRICS = (
    "input_gbps",
    "decoded_events_per_second",
    "internal_bbos_per_second",
    "external_bbos_per_second",
    "campaign_messages_per_second",
    "frame_stall_cycles",
    "itch_stall_cycles",
    "decoded_stall_cycles",
    "fifo_max_occupancy",
)


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"performance result not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def _format_rate(value: float) -> str:
    return f"{value / 1e6:.3f} M/s"


def build_summary(results_dir: Path) -> dict[str, Any]:
    latency_raw = _load_json(results_dir / "latency.json")
    throughput_raw = _load_json(results_dir / "throughput.json")

    latency_clock = float(latency_raw["clock_frequency_mhz"])
    throughput_clock = float(throughput_raw["clock_frequency_mhz"])
    if latency_clock != throughput_clock:
        raise ValueError(
            "latency and throughput results use different clocks: "
            f"{latency_clock} MHz vs {throughput_clock} MHz"
        )

    latency_cases: dict[str, dict[str, Any]] = {}
    for case in latency_raw["cases"]:
        latency_cases[str(case["case"])] = {
            "path": case["path"],
            "message_type": case["message_type"],
            "stock_locate": case["stock_locate"],
            "prime_event_count": case["prime_event_count"],
            "reset_to_ready_cycles": case["reset_to_ready_cycles"],
            "fifo_max_occupancy": case["fifo_max_occupancy"],
            **{metric: case[metric] for metric in LATENCY_METRICS},
        }

    throughput_cases: dict[str, dict[str, Any]] = {}
    for case in throughput_raw["cases"]:
        packing = str(case["packet_packing"])
        throughput_cases[packing] = {
            "case": case["case"],
            "frames": case["frames"],
            "events": case["events"],
            "campaign_window_cycles": case["campaign_window_cycles"],
            "latency_cycles": case["latency_cycles"],
            **{metric: case[metric] for metric in THROUGHPUT_METRICS},
        }

    worst_latency_case = max(
        latency_cases,
        key=lambda name: latency_cases[name][
            "frame_first_to_external_bbo_cycles"
        ],
    )
    best_campaign_packing = max(
        throughput_cases,
        key=lambda packing: throughput_cases[packing][
            "campaign_messages_per_second"
        ],
    )

    return {
        "schema_version": 1,
        "clock_frequency_mhz": latency_clock,
        "clock_period_ns": 1_000.0 / latency_clock,
        "mode": latency_raw["mode"],
        "latency_cases": latency_cases,
        "throughput_cases": throughput_cases,
        "highlights": {
            "worst_frame_to_bbo_case": worst_latency_case,
            "worst_frame_to_bbo_cycles": latency_cases[worst_latency_case][
                "frame_first_to_external_bbo_cycles"
            ],
            "best_campaign_packing": int(best_campaign_packing),
            "best_campaign_messages_per_second": throughput_cases[
                best_campaign_packing
            ]["campaign_messages_per_second"],
            "maximum_fifo_occupancy": max(
                max(case["fifo_max_occupancy"])
                for case in throughput_cases.values()
            ),
        },
    }


def render_markdown(summary: dict[str, Any]) -> str:
    lines = [
        "# Full-chain performance summary",
        "",
        f"- Mode: `{summary['mode']}`",
        f"- Clock: **{summary['clock_frequency_mhz']:.3f} MHz** "
        f"({summary['clock_period_ns']:.6f} ns)",
        "",
        "## Isolated latency",
        "",
        "| Case | Path | Frame first -> external BBO | Decoded -> internal BBO | Internal -> external BBO |",
        "|---|---|---:|---:|---:|",
    ]

    for case_name, case in summary["latency_cases"].items():
        lines.append(
            "| "
            f"`{case_name}` | {case['path']} | "
            f"{case['frame_first_to_external_bbo_cycles']} cycles | "
            f"{case['decoded_to_internal_bbo_cycles']} cycles | "
            f"{case['internal_to_external_bbo_cycles']} cycles |"
        )

    lines.extend(
        [
            "",
            "## Sustained throughput",
            "",
            "| Messages/packet | Frames | Events | Input | External BBO rate | Campaign rate | Frame stalls | Max FIFO occupancy |",
            "|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for packing, case in sorted(
        summary["throughput_cases"].items(),
        key=lambda item: int(item[0]),
    ):
        lines.append(
            "| "
            f"{packing} | {case['frames']} | {case['events']} | "
            f"{case['input_gbps']:.3f} Gbit/s | "
            f"{_format_rate(case['external_bbos_per_second'])} | "
            f"{_format_rate(case['campaign_messages_per_second'])} | "
            f"{case['frame_stall_cycles']} | "
            f"{max(case['fifo_max_occupancy'])} |"
        )

    highlights = summary["highlights"]
    lines.extend(
        [
            "",
            "## Highlights",
            "",
            f"- Worst isolated frame-to-BBO case: `{highlights['worst_frame_to_bbo_case']}` "
            f"at **{highlights['worst_frame_to_bbo_cycles']} cycles**.",
            f"- Best complete-campaign packing: **{highlights['best_campaign_packing']} messages/packet** "
            f"at **{_format_rate(highlights['best_campaign_messages_per_second'])}**.",
            f"- Maximum observed per-stock BBO FIFO occupancy: "
            f"**{highlights['maximum_fifo_occupancy']} / 15 safe entries**.",
            "",
        ]
    )

    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=_repo_root() / "build" / "perf" / "full_chain",
        help="Directory containing latency.json and throughput.json",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    results_dir = args.results_dir.expanduser().resolve()
    summary = build_summary(results_dir)

    summary_json_path = results_dir / "summary.json"
    summary_md_path = results_dir / "summary.md"

    summary_json_path.write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    summary_md_path.write_text(render_markdown(summary), encoding="utf-8")

    print(f"Wrote {summary_json_path}")
    print(f"Wrote {summary_md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
