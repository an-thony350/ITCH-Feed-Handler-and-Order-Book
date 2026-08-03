#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/ci/install_verilator.sh PREFIX

Build and install the exact Verilator revision used by CI into PREFIX.

Environment:
  VERILATOR_BUILD_JOBS   Parallel make jobs. Default: 2
EOF
}

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 2
fi

version="5.032"
commit="8ff77e9d47351b0a59114929880687839a51840b"
prefix="$1"
build_jobs="${VERILATOR_BUILD_JOBS:-2}"

case "$prefix" in
    ""|/)
        echo "error: refusing unsafe install prefix: ${prefix@Q}" >&2
        exit 2
        ;;
esac

if ! [[ "$build_jobs" =~ ^[1-9][0-9]*$ ]]; then
    echo "error: VERILATOR_BUILD_JOBS must be a positive integer" >&2
    exit 2
fi

prefix_parent="$(dirname "$prefix")"
prefix_name="$(basename "$prefix")"
mkdir -p "$prefix_parent"
prefix_parent="$(cd "$prefix_parent" && pwd)"
prefix="${prefix_parent}/${prefix_name}"

if [[ -x "${prefix}/bin/verilator" ]]; then
    installed_version="$("${prefix}/bin/verilator" --version)"
    if [[ "$installed_version" == "Verilator ${version}"* ]]; then
        echo "using existing ${installed_version}"
        exit 0
    fi

    echo "removing incompatible existing installation at ${prefix}"
    rm -rf "$prefix"
fi

for tool in autoconf bison flex g++ git help2man make perl python3; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: required build tool not found: $tool" >&2
        exit 1
    fi
done

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
source_dir="${work_dir}/verilator"

echo "cloning Verilator v${version}"
git clone \
    --quiet \
    --depth 1 \
    --branch "v${version}" \
    https://github.com/verilator/verilator.git \
    "$source_dir"

actual_commit="$(git -C "$source_dir" rev-parse HEAD)"
if [[ "$actual_commit" != "$commit" ]]; then
    echo "error: Verilator tag resolved to an unexpected commit" >&2
    echo "expected: $commit" >&2
    echo "actual:   $actual_commit" >&2
    exit 1
fi

echo "building Verilator ${version} at ${actual_commit}"
(
    cd "$source_dir"
    unset VERILATOR_ROOT
    autoconf
    ./configure --prefix="$prefix"
    make -j"$build_jobs"
    make install
)

installed_version="$("${prefix}/bin/verilator" --version)"
if [[ "$installed_version" != "Verilator ${version}"* ]]; then
    echo "error: installed Verilator reported an unexpected version" >&2
    echo "actual: $installed_version" >&2
    exit 1
fi

echo "installed ${installed_version}"
echo "prefix: ${prefix}"
