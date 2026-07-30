#!/usr/bin/env python3
"""Compare two full-chain performance summaries without touching RTL."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


LATENCY_METRICS = (
    "frame_first_to_external_bbo_cycles",
    "frame_last_to_external_bbo_cycles",
    "decoded_to_internal_bbo_cycles",
    "internal_to_external_bbo_cycles",
    "decoded_to_external_bbo_cycles",
)

RATE_METRICS = (
    "input_gbps",
    "decoded_events_per_second",
    "internal_bbos_per_second",
    "external_bbos_per_second",
    "campaign_messages_per_second",
)


def _resolve_summary(path: Path) -> Path:
    resolved = path.expanduser().resolve()
    return resolved / "summary.json" if resolved.is_dir() else resolved


def _load_summary(path: Path) -> dict[str, Any]:
    summary_path = _resolve_summary(path)
    if not summary_path.exists():
        raise FileNotFoundError(f"performance summary not found: {summary_path}")
    return json.loads(summary_path.read_text(encoding="utf-8"))


def _percent_change(baseline: float, candidate: float) -> float:
    if baseline == 0:
        if candidate == 0:
            return 0.0
        raise ValueError("cannot calculate percentage change from zero baseline")
    return 100.0 * (candidate - baseline) / baseline


def compare(
    baseline: dict[str, Any],
    candidate: dict[str, Any],
    *,
    max_latency_regression_cycles: int,
    max_throughput_regression_percent: float,
) -> dict[str, Any]:
    latency_rows: list[dict[str, Any]] = []
    throughput_rows: list[dict[str, Any]] = []
    regressions: list[str] = []

    common_latency_cases = sorted(
        set(baseline["latency_cases"]) & set(candidate["latency_cases"])
    )
    for case_name in common_latency_cases:
        baseline_case = baseline["latency_cases"][case_name]
        candidate_case = candidate["latency_cases"][case_name]

        for metric in LATENCY_METRICS:
            baseline_value = int(baseline_case[metric])
            candidate_value = int(candidate_case[metric])
            delta = candidate_value - baseline_value
            passed = delta <= max_latency_regression_cycles

            latency_rows.append(
                {
                    "case": case_name,
                    "metric": metric,
                    "baseline": baseline_value,
                    "candidate": candidate_value,
                    "delta_cycles": delta,
                    "passed": passed,
                }
            )

            if not passed:
                regressions.append(
                    f"{case_name}/{metric} regressed by {delta} cycles"
                )

    common_packings = sorted(
        set(baseline["throughput_cases"])
        & set(candidate["throughput_cases"]),
        key=int,
    )
    for packing in common_packings:
        baseline_case = baseline["throughput_cases"][packing]
        candidate_case = candidate["throughput_cases"][packing]

        for metric in RATE_METRICS:
            baseline_value = float(baseline_case[metric])
            candidate_value = float(candidate_case[metric])
            delta_percent = _percent_change(baseline_value, candidate_value)
            passed = delta_percent >= -max_throughput_regression_percent

            throughput_rows.append(
                {
                    "packet_packing": int(packing),
                    "metric": metric,
                    "baseline": baseline_value,
                    "candidate": candidate_value,
                    "delta_percent": delta_percent,
                    "passed": passed,
                }
            )

            if not passed:
                regressions.append(
                    f"packing {packing}/{metric} regressed by "
                    f"{-delta_percent:.3f}%"
                )

        candidate_fifo_max = max(candidate_case["fifo_max_occupancy"])
        if candidate_fifo_max > 15:
            regressions.append(
                f"packing {packing} exceeded safe FIFO occupancy: "
                f"{candidate_fifo_max} > 15"
            )

    missing_latency = sorted(
        set(baseline["latency_cases"]) - set(candidate["latency_cases"])
    )
    missing_packings = sorted(
        set(baseline["throughput_cases"])
        - set(candidate["throughput_cases"]),
        key=int,
    )

    if missing_latency:
        regressions.append(
            f"candidate is missing latency cases: {missing_latency}"
        )
    if missing_packings:
        regressions.append(
            f"candidate is missing throughput packings: {missing_packings}"
        )

    return {
        "schema_version": 1,
        "baseline_clock_frequency_mhz": baseline["clock_frequency_mhz"],
        "candidate_clock_frequency_mhz": candidate["clock_frequency_mhz"],
        "max_latency_regression_cycles": max_latency_regression_cycles,
        "max_throughput_regression_percent": (
            max_throughput_regression_percent
        ),
        "latency_comparisons": latency_rows,
        "throughput_comparisons": throughput_rows,
        "missing_latency_cases": missing_latency,
        "missing_throughput_packings": [int(value) for value in missing_packings],
        "regressions": regressions,
        "passed": not regressions,
    }


def render_markdown(comparison: dict[str, Any]) -> str:
    status = "PASS" if comparison["passed"] else "FAIL"
    lines = [
        "# Full-chain performance comparison",
        "",
        f"**Status: {status}**",
        "",
        f"- Baseline clock: {comparison['baseline_clock_frequency_mhz']:.3f} MHz",
        f"- Candidate clock: {comparison['candidate_clock_frequency_mhz']:.3f} MHz",
        f"- Allowed latency regression: {comparison['max_latency_regression_cycles']} cycles",
        f"- Allowed throughput regression: {comparison['max_throughput_regression_percent']:.3f}%",
        "",
        "## Latency",
        "",
        "| Case | Metric | Baseline | Candidate | Delta | Status |",
        "|---|---|---:|---:|---:|---|",
    ]

    for row in comparison["latency_comparisons"]:
        lines.append(
            "| "
            f"`{row['case']}` | `{row['metric']}` | "
            f"{row['baseline']} | {row['candidate']} | "
            f"{row['delta_cycles']:+d} | "
            f"{'PASS' if row['passed'] else 'FAIL'} |"
        )

    lines.extend(
        [
            "",
            "## Throughput",
            "",
            "| Messages/packet | Metric | Baseline | Candidate | Change | Status |",
            "|---:|---|---:|---:|---:|---|",
        ]
    )

    for row in comparison["throughput_comparisons"]:
        lines.append(
            "| "
            f"{row['packet_packing']} | `{row['metric']}` | "
            f"{row['baseline']:.6g} | {row['candidate']:.6g} | "
            f"{row['delta_percent']:+.3f}% | "
            f"{'PASS' if row['passed'] else 'FAIL'} |"
        )

    if comparison["regressions"]:
        lines.extend(["", "## Regressions", ""])
        lines.extend(f"- {item}" for item in comparison["regressions"])

    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--max-latency-regression-cycles", type=int, default=0)
    parser.add_argument(
        "--max-throughput-regression-percent",
        type=float,
        default=0.0,
    )
    parser.add_argument("--fail-on-regression", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.max_latency_regression_cycles < 0:
        raise ValueError("max latency regression must be non-negative")
    if args.max_throughput_regression_percent < 0:
        raise ValueError("max throughput regression must be non-negative")

    baseline = _load_summary(args.baseline)
    candidate = _load_summary(args.candidate)
    comparison = compare(
        baseline,
        candidate,
        max_latency_regression_cycles=(
            args.max_latency_regression_cycles
        ),
        max_throughput_regression_percent=(
            args.max_throughput_regression_percent
        ),
    )

    output_dir = args.output_dir.expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    json_path = output_dir / "comparison.json"
    markdown_path = output_dir / "comparison.md"
    json_path.write_text(
        json.dumps(comparison, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    markdown_path.write_text(
        render_markdown(comparison),
        encoding="utf-8",
    )

    print(f"Wrote {json_path}")
    print(f"Wrote {markdown_path}")
    print("PASS" if comparison["passed"] else "FAIL")

    if args.fail_on_regression and not comparison["passed"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
