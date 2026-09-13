#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

ARGS=(
    --data "data/12302019.NASDAQ_ITCH50.gz"
    --output "oracle/demo_oracle.json"
)

# Normal showcase flow: find the shortest deterministic prefix that gives every
# stock enough BBO activity to produce a useful graph. The exact source-message
# limit is then frozen into the generated oracle metadata.
if [[ -n "${MESSAGE_LIMIT:-}" ]]; then
    ARGS+=(--message-limit "${MESSAGE_LIMIT}")
else
    MIN_BBO_UPDATES="${MIN_BBO_UPDATES:-400}"
    MAX_MESSAGES="${MAX_MESSAGES:-10000000}"
    ARGS+=(
        --min-bbo-updates "${MIN_BBO_UPDATES}"
        --max-messages "${MAX_MESSAGES}"
    )
fi

exec python3 generate_oracle.py "${ARGS[@]}"
