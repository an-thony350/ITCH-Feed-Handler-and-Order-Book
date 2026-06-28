#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/run_golden.sh [options]

Default synthetic run:
  scripts/run_golden.sh

Synthetic run with chosen seed/count:
  scripts/run_golden.sh --seed 7 --random-message-count 25

Real ITCH run, resolving symbol through Stock Directory messages:
  scripts/run_golden.sh --input path/to/real_itch.bin --symbol AAPL

Real ITCH run, filtering by known locate:
  scripts/run_golden.sh --input path/to/real_itch.bin --locate 24

Options:
  --input PATH                  Existing ITCH BinaryFILE input. If omitted, synthetic input is generated.
  --out-dir DIR                 Output directory. Default: build/golden
  --seed N                      Synthetic stimulus seed. Default: 7
  --random-message-count N      Synthetic random message count. Default: 25
  --locate N                    Stock locate filter.
  --symbol SYMBOL               Symbol filter, resolved from Stock Directory messages.
  --start-index N               msg_index for first source record. Default: 0
  --max-messages N              Maximum source records to scan.
  --max-events N                Maximum accepted book events to emit.
  --allow-unfiltered            Allow real input without --symbol or --locate.
  --skip-tests                  Skip py_compile and unit tests.
  -h, --help                    Show this help.

Environment:
  PYTHON                        Python executable to use. Default: python
EOF
}

die() {
    echo "error: $*" >&2
    exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

python_bin="${PYTHON:-python}"
input_path=""
out_dir="build/golden"
seed="7"
random_message_count="25"
locate=""
symbol=""
start_index="0"
max_messages=""
max_events=""
allow_unfiltered=0
skip_tests=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --input)
            [[ $# -ge 2 ]] || die "--input requires a path"
            input_path="$2"
            shift 2
            ;;
        --out-dir)
            [[ $# -ge 2 ]] || die "--out-dir requires a directory"
            out_dir="$2"
            shift 2
            ;;
        --seed)
            [[ $# -ge 2 ]] || die "--seed requires a value"
            seed="$2"
            shift 2
            ;;
        --random-message-count)
            [[ $# -ge 2 ]] || die "--random-message-count requires a value"
            random_message_count="$2"
            shift 2
            ;;
        --locate)
            [[ $# -ge 2 ]] || die "--locate requires a value"
            locate="$2"
            shift 2
            ;;
        --symbol)
            [[ $# -ge 2 ]] || die "--symbol requires a value"
            symbol="$2"
            shift 2
            ;;
        --start-index)
            [[ $# -ge 2 ]] || die "--start-index requires a value"
            start_index="$2"
            shift 2
            ;;
        --max-messages)
            [[ $# -ge 2 ]] || die "--max-messages requires a value"
            max_messages="$2"
            shift 2
            ;;
        --max-events)
            [[ $# -ge 2 ]] || die "--max-events requires a value"
            max_events="$2"
            shift 2
            ;;
        --allow-unfiltered)
            allow_unfiltered=1
            shift
            ;;
        --skip-tests)
            skip_tests=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown option: $1"
            ;;
    esac
done

[[ -z "$locate" || -z "$symbol" ]] || die "use either --locate or --symbol, not both"

if [[ -d golden/tests ]]; then
    test_dir="golden/tests"
elif [[ -d tests ]]; then
    test_dir="tests"
else
    die "could not find golden/tests or tests directory"
fi

mkdir -p "$out_dir"

events_out="${out_dir}/events.jsonl"
states_out="${out_dir}/states.jsonl"
synthetic_input="${out_dir}/itch_synthetic.bin"

echo "clearing stale golden outputs"
rm -f "$events_out" "$states_out"

if [[ "$skip_tests" -eq 0 ]]; then
    echo "[1/4] compiling golden Python files"
    mapfile -t py_files < <(find golden "$test_dir" -name '*.py' -type f | sort)
    "${python_bin}" -m py_compile "${py_files[@]}"

    echo "[2/4] running golden unit tests"
    "${python_bin}" -m unittest discover -s "$test_dir" -v
else
    echo "[1/4] skipping compile/tests"
    echo "[2/4] skipping compile/tests"
fi

if [[ -z "$input_path" ]]; then
    input_path="$synthetic_input"
    if [[ -z "$locate" && -z "$symbol" ]]; then
        locate="1"
    fi

    echo "[3/4] generating synthetic ITCH BinaryFILE"
    rm -f "$input_path"
    "${python_bin}" -m golden.stimulus "$input_path" \
        --seed "$seed" \
        --random-message-count "$random_message_count"
else
    [[ -f "$input_path" ]] || die "input file does not exist: $input_path"
    if [[ -z "$locate" && -z "$symbol" && "$allow_unfiltered" -eq 0 ]]; then
        die "real input requires --symbol or --locate, unless --allow-unfiltered is set"
    fi
    echo "[3/4] using existing ITCH BinaryFILE: $input_path"
fi

runner_args=(
    "$input_path"
    --events-out "$events_out"
    --states-out "$states_out"
    --start-index "$start_index"
)

if [[ -n "$locate" ]]; then
    runner_args+=(--locate "$locate")
fi
if [[ -n "$symbol" ]]; then
    runner_args+=(--symbol "$symbol")
fi
if [[ -n "$max_messages" ]]; then
    runner_args+=(--max-messages "$max_messages")
fi
if [[ -n "$max_events" ]]; then
    runner_args+=(--max-events "$max_events")
fi

echo "[4/4] generating golden JSONL oracles"
"${python_bin}" -m golden.runner "${runner_args[@]}"

echo
echo "outputs:"
echo "  input:  $input_path"
echo "  events: $events_out"
echo "  states: $states_out"
echo
wc -l "$events_out" "$states_out"
