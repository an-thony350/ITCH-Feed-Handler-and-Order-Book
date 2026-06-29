Repo for use in WSL

To install autoformatter
```bash
python3 -m venv .venv
source .venv/bin/activate
pre-commit install
deactivate
```

To run:
```bash
./scripts/format.sh
```
or
```bash
pre-commit run --all-files
```

If autoformatter finds formatting issues, it will fix, but you have to stage the commit again.



## Python, cocotb, and Verilator Setup

This project uses cocotb with Verilator for RTL simulation. `cocotb==2.0.1` does not support Python 3.14, so use Python 3.13 for the project virtual environment.

### 1. Install system dependencies

From the repository root:

```bash
cd ~/ITCH-Feed-Handler-and-Order-Book

sudo apt update
sudo apt install -y curl ca-certificates build-essential verilator
```

Check Verilator is available:

```bash
verilator --version
```

Expected output should include something like:

```text
Verilator 5.032 ...
```

### 2. Install `uv`

`uv` is used to install a Python version that may not be available through `apt`.

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
```

To make this permanent, add this line to your shell config:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

Then reload the shell config:

```bash
source ~/.bashrc
```

Check `uv` is available:

```bash
uv --version
```

### 3. Create the project virtual environment

Remove any stale virtual environment first:

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book

deactivate 2>/dev/null || true
rm -rf .venv
```

Install Python 3.13 and create a seeded virtual environment:

```bash
uv python install 3.13
uv venv --python 3.13 --seed .venv
source .venv/bin/activate
```

Check the Python version:

```bash
python -VV
which python
```

Expected:

```text
Python 3.13.x ...
/home/<user>/Documents/ITCH-Feed-Handler-and-Order-Book/.venv/bin/python
```

### 4. Install Python dependencies

Create or update `requirements.txt`:

```bash
cat > requirements.txt <<'EOF'
cocotb==2.0.1
pytest
EOF
```

Install the dependencies:

```bash
uv pip install -r requirements.txt
```

Alternatively, install directly:

```bash
uv pip install "cocotb==2.0.1" pytest
```

### 5. Verify the environment

Run:

```bash
python -m pip --version
python -c "import sys, cocotb; print(sys.version); print(cocotb.__version__)"
verilator --version
```

Expected:

```text
pip ... from .../.venv/lib/python3.13/site-packages/pip
3.13.x ...
2.0.1
Verilator 5.032 ...
```

### 6. Run Python tests

From the repository root:

```bash
source .venv/bin/activate
python -m pytest -q
```

### 7. Run cocotb / Verilator simulations

From the simulation directory:

```bash
cd sim
source ../.venv/bin/activate
make SIM=verilator
```

If the Makefile already sets `SIM`, run:

```bash
make
```

### 8. Important notes

Do not use system `pip` for this project.

Avoid:

```bash
sudo pip install ...
python -m pip install --break-system-packages ...
COCOTB_IGNORE_PYTHON_REQUIRES=1
```

The correct flow is always:

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book
source .venv/bin/activate
uv pip install -r requirements.txt
```

### 9. Full clean rebuild command sequence

Use this if the Python environment becomes broken:

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book

deactivate 2>/dev/null || true
rm -rf .venv

sudo apt update
sudo apt install -y curl ca-certificates build-essential verilator

export PATH="$HOME/.local/bin:$PATH"

uv python install 3.13
uv venv --python 3.13 --seed .venv
source .venv/bin/activate

uv pip install -r requirements.txt

python -VV
python -c "import cocotb; print(cocotb.__version__)"
verilator --version
```
