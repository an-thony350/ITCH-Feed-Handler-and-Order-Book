#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if ! command -v pre-commit >/dev/null 2>&1; then
  echo "pre-commit not found. Activate your venv and run:"
  echo "  python -m pip install pre-commit"
  exit 1
fi

pre-commit run --all-files
