# Environment Setup

This document describes the toolchain required to build and verify the ITCH 5.0 feed handler project. It covers installation and environment configuration only. Commands for running tests, generating oracles, creating network vectors, formatting, and cleanup are in [`running_the_project.md`](running_the_project.md).

The project uses three distinct flows:

1. **Python golden model** — parser, stimulus generation, reference order book, and JSONL oracle generation.
2. **cocotb + Verilator** — host-side RTL verification and scoreboard integration.
3. **Vivado 2023.2 / xsim** — directed SystemVerilog simulation, synthesis, implementation, timing closure, and PYNQ-Z1 bring-up.

The golden-model and cocotb flows are intended to run from WSL/Linux. Vivado may run from Windows or Linux, depending on the local installation.

---

## 1. Assumed host setup

Recommended host environment:

- WSL Ubuntu 22.04 or a similar Linux environment;
- `bash`;
- `git`;
- GNU Make;
- Python 3.13 in a project-local virtual environment;
- `uv` for Python installation and package management;
- Verilator 5.x for cocotb simulation;
- Vivado 2023.2 for xsim and FPGA implementation.

From a fresh shell, start from the repository root:

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book
```

Replace that path when the checkout is stored elsewhere.

---

## 2. System packages

Install the basic Linux build tools:

```bash
sudo apt update
sudo apt install -y \
    curl \
    ca-certificates \
    git \
    build-essential \
    make
```

These packages are sufficient for the Python side. A source build of Verilator requires the additional dependencies listed below.

---

## 3. Install `uv`

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

Verify the installation:

```bash
uv --version
```

---

## 4. Create the Python virtual environment

Use Python 3.13 for the tested cocotb flow. Python 3.14 should not be used unless the dependency set is deliberately updated and re-tested.

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book

deactivate 2>/dev/null || true
rm -rf .venv

uv python install 3.13
uv venv --python 3.13 --seed .venv
source .venv/bin/activate
```

Verify the active interpreter:

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

Install the repository requirements and the formatting hook:

```bash
uv pip install pip setuptools wheel
uv pip install -r requirements.txt
uv pip install pre-commit
```

The tested core versions include:

```text
cocotb 2.0.1
Verilator 5.x
```

Verify the Python packages:

```bash
python -m pip --version
python -c "import sys, cocotb; print(sys.version); print(cocotb.__version__)"
```

Avoid mixing the project environment with the system Python:

```bash
sudo pip install ...
python -m pip install --break-system-packages ...
COCOTB_IGNORE_PYTHON_REQUIRES=1
```

When the environment is inconsistent, delete `.venv` and recreate it instead of applying those workarounds.

---

## 6. Verilator setup

First check whether a suitable version is already installed:

```bash
verilator --version
```

The project uses a Verilator 5.x flow. `Verilator 5.032 ...` is a known-good version.

### Option A — package manager

Try the distribution package first:

```bash
sudo apt update
sudo apt install -y verilator
verilator --version
```

Some Ubuntu/WSL package repositories provide an older version. Use the source build when the installed version is not compatible with the cocotb flow.

### Option B — build Verilator 5.032 from source

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

Build and install into the user-local prefix:

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

Ensure the local binary is found before an older system installation:

```bash
export PATH="$HOME/.local/bin:$PATH"
hash -r
which verilator
verilator --version
```

Expected path:

```text
/home/<user>/.local/bin/verilator
```

---

## 7. Vivado / xsim setup

Vivado 2023.2 is the project toolchain for:

- directed SystemVerilog tests in xsim;
- elaboration;
- synthesis;
- implementation;
- static timing analysis;
- PYNQ-Z1 bitstream generation and bring-up.

When Vivado is installed on Windows, launch it from the configured Xilinx environment or through the Vivado GUI.

When Vivado is installed on Linux, source its settings script:

```bash
source /tools/Xilinx/Vivado/2023.2/settings64.sh
vivado -version
xvlog -version
xelab -version
xsim -version
```

The cocotb/Verilator flow is a host-side verification flow. It is not part of the FPGA implementation path.

---

## 8. Environment sanity check

With the virtual environment active:

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book
source .venv/bin/activate

python -VV
which python
python -c "import cocotb; print(cocotb.__version__)"
which cocotb-config
which verilator
verilator --version
```

Once these checks succeed, continue with [`running_the_project.md`](running_the_project.md).
