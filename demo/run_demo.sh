#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The ZCU106 PYNQ/XRT device is reliably visible from a root login environment.
# Re-exec once through sudo when the user launches this from the normal xilinx shell.
if [[ "${EUID}" -ne 0 ]]; then
    exec sudo -E bash "${SCRIPT_DIR}/run_demo.sh" "$@"
fi

# Recreate the same environment proven during Gate 1 bring-up.
if [[ -f /etc/profile.d/pynq_venv.sh ]]; then
    # shellcheck disable=SC1091
    source /etc/profile.d/pynq_venv.sh
fi

if [[ -f /etc/profile.d/xrt_setup.sh ]]; then
    # shellcheck disable=SC1091
    source /etc/profile.d/xrt_setup.sh
fi

export XILINX_XRT="${XILINX_XRT:-/usr}"

cd "${SCRIPT_DIR}"

PORT="${PORT:-8080}"
ARGS=(
    --host 0.0.0.0
    --port "${PORT}"
    --bitstream "overlay/v4release.bit"
    --data "data/12302019.NASDAQ_ITCH50.gz"
    --oracle "oracle/demo_oracle.json"
)

# The normal path reads the exact replay limit from the oracle. MESSAGE_LIMIT is
# retained only as an explicit safety/debug override and must match the oracle.
if [[ -n "${MESSAGE_LIMIT:-}" ]]; then
    ARGS+=(--message-limit "${MESSAGE_LIMIT}")
fi

exec python3 app.py "${ARGS[@]}"
