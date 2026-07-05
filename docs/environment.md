# Environment Setup

This document describes the development environment for the ITCH 5.0 feed handler project.

The project currently uses three distinct tool flows:

1. **Python golden model** — parser, synthetic stimulus, reference order book, and JSONL oracle generation.
2. **cocotb + Verilator** — host-side RTL verification and scoreboard integration.
3. **Vivado 2023.2 / xsim** — directed SystemVerilog simulation, synthesis, implementation, timing closure, and eventual PYNQ-Z1 bring-up.

The golden model and cocotb flow are intended to run from WSL/Linux. Vivado may be run from Windows or Linux, depending on how it is installed locally.

---

## 1. Assumed host setup

Recommended host environment:

- WSL Ubuntu 22.04 or similar Linux environment
- `bash`
- `git`
- `make`
- Python 3.13 inside a project-local virtual environment
- `uv` for Python installation and package management
- Verilator 5.x for cocotb simulations
- Vivado 2023.2 for xsim and FPGA implementation

From a fresh shell, start from the repository root:

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book
```

If your checkout is somewhere else, replace that path in the commands below.

---

## 2. System packages

Install the basic Linux build tools first:

```bash
sudo apt update
sudo apt install -y \
    curl \
    ca-certificates \
    git \
    build-essential \
    make
```

These are enough for the Python/golden-model side. Verilator may need more dependencies if it is built from source; see the Verilator section below.

---

## 3. Install `uv`

`uv` is used so the project can use Python 3.13 even when the system Python is different.

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
```

Make the PATH update permanent:

```bash
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Check it works:

```bash
uv --version
```

---

## 4. Create the Python virtual environment

Use Python 3.13 for this project. Do **not** use Python 3.14 for the cocotb flow unless the dependency pin is changed and re-tested.

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book

deactivate 2>/dev/null || true
rm -rf .venv

uv python install 3.13
uv venv --python 3.13 --seed .venv
source .venv/bin/activate
```

Check the active Python:

```bash
python -VV
which python
```

Expected shape:

```text
Python 3.13.x ...
/home/<user>/Documents/ITCH-Feed-Handler-and-Order-Book/.venv/bin/python
```

---

## 5. Install Python dependencies

The minimum working dependencies are:

```bash
uv pip install pip setuptools wheel
uv pip install "cocotb==2.0.1" pytest pre-commit
```

If a `requirements.txt` is added to the repo later, prefer:

```bash
uv pip install -r requirements.txt
```

Verify the Python packages:

```bash
python -m pip --version
python -c "import sys, cocotb; print(sys.version); print(cocotb.__version__)"
```

Expected shape:

```text
pip ... from .../.venv/lib/python3.13/site-packages/pip
3.13.x ...
2.0.1
```

Avoid these workarounds:

```bash
sudo pip install ...
python -m pip install --break-system-packages ...
COCOTB_IGNORE_PYTHON_REQUIRES=1
```

If the environment is broken, delete `.venv` and rebuild it rather than mixing system packages into the project.

---

## 6. Verilator setup

The cocotb flow uses Verilator. First check whether a suitable version is already installed:

```bash
verilator --version
```

The project has been using a Verilator 5.x flow. A version such as `Verilator 5.032 ...` is the expected shape.

### Option A — package manager install

Try this first if your package repository provides a recent Verilator 5.x:

```bash
sudo apt update
sudo apt install -y verilator
verilator --version
```

On some Ubuntu/WSL installations, `apt` may install an older Verilator. If the version is too old for the cocotb flow, use Option B.

### Option B — build Verilator from source

Install build dependencies:

```bash
sudo apt update
sudo apt install -y \
    git \
    help2man \
    perl \
    python3 \
    make \
    autoconf \
    g++ \
    flex \
    bison \
    ccache \
    libfl2 \
    libfl-dev \
    zlib1g \
    zlib1g-dev
```

Build and install a known 5.x release into `$HOME/.local`:

```bash
mkdir -p ~/tools
cd ~/tools

git clone https://github.com/verilator/verilator.git
cd verilator
git checkout v5.032

autoconf
./configure --prefix="$HOME/.local"
make -j"$(nproc)"
make install
```

Ensure your shell finds the new binary first:

```bash
export PATH="$HOME/.local/bin:$PATH"
hash -r
verilator --version
```

If you already had an older `/usr/bin/verilator`, confirm that the shell is using the new one:

```bash
which verilator
```

Expected shape:

```text
/home/<user>/.local/bin/verilator
```

---

## 7. Run the golden-model tests

From the repository root:

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book
source .venv/bin/activate

python -m py_compile golden/*.py golden/tests/*.py
python -m unittest discover -s golden/tests -v
```

The `scripts/run_golden.sh` wrapper runs these checks by default before generating the oracle files.

---

## 8. Generate golden-model oracle files

The golden flow emits two JSONL files:

- `events.jsonl` — normalised events for decoder-level checking.
- `states.jsonl` — order-book snapshots after each accepted event for book/full-chain checking.

Default synthetic run:

```bash
scripts/run_golden.sh
```

Synthetic run with explicit seed/count:

```bash
scripts/run_golden.sh --seed 7 --random-message-count 25
```

Real ITCH BinaryFILE run, resolving a symbol through Stock Directory messages:

```bash
scripts/run_golden.sh \
    --input path/to/real_itch.bin \
    --symbol AAPL \
    --max-messages 100000 \
    --max-events 10000
```

Real ITCH BinaryFILE run, filtering by a known locate:

```bash
scripts/run_golden.sh \
    --input path/to/real_itch.bin \
    --locate 24 \
    --max-messages 100000 \
    --max-events 10000
```

Outputs default to:

```text
build/golden/itch_synthetic.bin
build/golden/events.jsonl
build/golden/states.jsonl
```

The wrapper removes stale `events.jsonl` and `states.jsonl` before each run, then regenerates them.

---

## 9. Run cocotb / Verilator simulations

The cocotb Makefile is currently in `tb/`.

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book/tb
source ../.venv/bin/activate
make
```

Equivalent explicit command:

```bash
make SIM=verilator TOPLEVEL=order_book MODULE=test_order_book
```

The `tb/Makefile` sets the Python path to include both `tb/` and the repository root, so imports such as `golden.*` and `tb/itch_harness/*` should work when running from `tb/`.

To clean generated simulation output:

```bash
make clean
rm -rf sim_build results.xml dump.vcd *.vcd *.fst
```

Useful checks if cocotb cannot start:

```bash
which python
python -c "import cocotb; print(cocotb.__version__)"
which cocotb-config
which verilator
verilator --version
```

Common causes:

- `.venv` is not activated.
- `cocotb` was installed into the wrong Python.
- The shell is finding an old Verilator before the source-built one.
- The simulation is being run from the wrong directory.

---

## 10. Run the formatter

Install the pre-commit hook once:

```bash
source .venv/bin/activate
pre-commit install
```

Run formatting/checks over the whole repo:

```bash
./scripts/format.sh
```

or directly:

```bash
pre-commit run --all-files
```

If the formatter changes files, review the diff and stage those changes manually.

---

## 11. Vivado / xsim setup

Vivado 2023.2 is the project toolchain for:

- SystemVerilog directed testbenches in xsim.
- Elaboration.
- Synthesis.
- Implementation.
- STA/timing closure.
- PYNQ-Z1 build/bring-up.

If Vivado is installed on Windows, run Vivado/xsim from the Windows environment where `settings64.bat` has been applied, or launch through the Vivado GUI.

If Vivado is installed on Linux, source the settings script before running Vivado commands:

```bash
source /tools/Xilinx/Vivado/2023.2/settings64.sh
vivado -version
xvlog -version
xelab -version
xsim -version
```

The current directed SystemVerilog testbenches live under `tb/`, including the decoder and order-book testbenches. The cocotb/Verilator flow is for host-side scoreboard verification; it is not the FPGA implementation flow.

---

## 12. Generated files and cleanup

Generated files should normally stay out of source control.

Common generated paths/files:

```text
.venv/
build/
tb/sim_build/
tb/results.xml
tb/*.vcd
tb/*.fst
__pycache__/
.pytest_cache/
```

Useful cleanup commands:

```bash
# Python caches
find . -type d -name __pycache__ -prune -exec rm -rf {} +
find . -type d -name .pytest_cache -prune -exec rm -rf {} +

# Golden outputs
rm -rf build/golden

# cocotb outputs
cd tb
make clean || true
rm -rf sim_build results.xml dump.vcd *.vcd *.fst
```

---

## 13. Full clean rebuild sequence

Use this when the Python/cocotb environment is confused:

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book

deactivate 2>/dev/null || true
rm -rf .venv

sudo apt update
sudo apt install -y curl ca-certificates git build-essential make

export PATH="$HOME/.local/bin:$PATH"

uv python install 3.13
uv venv --python 3.13 --seed .venv
source .venv/bin/activate

uv pip install pip setuptools wheel
uv pip install "cocotb==2.0.1" pytest pre-commit

python -VV
python -c "import cocotb; print(cocotb.__version__)"
verilator --version

python -m unittest discover -s golden/tests -v
scripts/run_golden.sh --seed 7 --random-message-count 25

cd tb
make clean || true
make
```

---

## 14. Sanity checklist

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book
source .venv/bin/activate

python -VV
which python
python -c "import cocotb; print(cocotb.__version__)"
verilator --version
python -m unittest discover -s golden/tests -v
scripts/run_golden.sh --seed 7 --random-message-count 25
cd tb && make
```

If all of those pass, the host environment is good enough for golden-model and cocotb work.
