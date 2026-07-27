# Running the Project

This document contains the repository's executable workflows. Complete toolchain installation is documented in [`environment.md`](environment.md); the golden-model and verification contracts are documented in [`golden_model.md`](golden_model.md).

Unless a section states otherwise, commands begin at the repository root with the Python environment active:

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book
source .venv/bin/activate
```

---

## 1. Complete host-side regression

From `tb/`:

```bash
cd tb
make
```

The default target runs:

1. golden Python compilation and unit tests;
2. deterministic synthetic BinaryFILE and JSONL oracle generation;
3. MoldUDP64 sequence-guard tests;
4. ITCH decoder tests;
5. direct order-book tests;
6. router/book wrapper tests;
7. ingress correctness tests;
8. ingress performance-probe tests;
9. complete feed-handler network-to-book tests.

Return to the repository root with:

```bash
cd ..
```

---

## 2. Individual cocotb / Verilator targets

Run these from `tb/`:

| Make target | DUT / purpose |
|---|---|
| `make test-golden` | Compile/test the Python oracle and regenerate default oracle files |
| `make test-mold-seq-guard` | Sequence, duplicate, gap, heartbeat, EOS, and stale policy |
| `make test-data-handler` | Decoder replay against `events.jsonl` |
| `make test-order-book` | Direct order-book lifecycle and oracle BBO tests |
| `make test-order-book-top` | Symbol-router and book-wrapper tests |
| `make test-ingress` | Ethernet-to-aligned-ITCH correctness |
| `make test-ingress-probe` | Run ingress correctness through the performance-probe wrapper |
| `make test-ingress-perf` | Cycle-accurate ingress latency and throughput tests |
| `make test-feed-handler-top` | Complete network-to-book G3/G4 regression |
| `make test-rtl` | All RTL cocotb targets without regenerating the golden oracle |
| `make test-all` | Golden generation followed by all RTL targets |

Example:

```bash
cd tb
make test-feed-handler-top
```

The direct cocotb form remains available:

```bash
make SIM=verilator TOPLEVEL=feed_handler_top MODULE=test_feed_handler_top
```

Supported `TOPLEVEL` values in the current Makefile are:

```text
mold_seq_guard
data_handler
order_book
order_book_top
ingress_top
ingress_top_perf_probe
feed_handler_top
```

The Makefile adds the repository root and `tb/` to `PYTHONPATH`, selects the required RTL sources, and enables SystemVerilog, timing, and trace support.

---

## 3. Generate golden-model oracle files

### Default deterministic synthetic oracle

```bash
scripts/run_golden.sh
```

Default outputs:

```text
build/golden/itch_synthetic.bin
build/golden/events.jsonl
build/golden/states.jsonl
```

The wrapper clears stale `events.jsonl` and `states.jsonl` before generation. It then compiles the golden Python files, runs unit tests, generates synthetic input when required, and writes the matched event/state streams.

### Synthetic run with chosen seed and count

```bash
scripts/run_golden.sh \
    --seed 7 \
    --random-message-count 100
```

### Real ITCH BinaryFILE by symbol

```bash
scripts/run_golden.sh \
    --input path/to/real_itch.bin \
    --symbol AAPL \
    --max-messages 100000 \
    --max-events 10000
```

### Real ITCH BinaryFILE by known locate

```bash
scripts/run_golden.sh \
    --input path/to/real_itch.bin \
    --locate 24 \
    --max-messages 100000 \
    --max-events 10000
```

Real input requires `--symbol` or `--locate` unless `--allow-unfiltered` is explicitly supplied. Do not use unfiltered multi-symbol data as the oracle for a single routed book.

### Useful wrapper options

| Option | Meaning |
|---|---|
| `--input PATH` | Use an existing BinaryFILE instead of generating synthetic input |
| `--out-dir DIR` | Change the oracle output directory; default `build/golden` |
| `--seed N` | Synthetic random seed; default 7 |
| `--random-message-count N` | Number of seeded-random synthetic messages; default 25 |
| `--locate N` | Filter to one stock-locate code |
| `--symbol SYMBOL` | Resolve and filter a symbol through Stock Directory messages |
| `--start-index N` | Source `msg_index` assigned to the first record |
| `--max-messages N` | Maximum BinaryFILE records to scan |
| `--max-events N` | Maximum accepted book events to emit |
| `--allow-unfiltered` | Permit real input without symbol/locate filtering |
| `--skip-tests` | Skip Python compilation and unit tests for local iteration |
| `--help` | Print the complete usage text |

`--symbol` and `--locate` are mutually exclusive.

### Direct Python commands

Compile the golden files:

```bash
python -m py_compile golden/*.py golden/tests/*.py
```

Run golden unit tests:

```bash
python -m unittest discover -s golden/tests -v
```

Generate synthetic input directly:

```bash
python -m golden.stimulus build/golden/itch_synthetic.bin \
    --seed 7 \
    --random-message-count 25
```

Generate matched JSONL directly:

```bash
python -m golden.runner build/golden/itch_synthetic.bin \
    --events-out build/golden/events.jsonl \
    --states-out build/golden/states.jsonl \
    --locate 1
```

---

## 4. Generate network test vectors

The public ITCH BinaryFILE format contains length-prefixed ITCH messages, not Ethernet/IP/UDP/MoldUDP64 frames. `golden.network_encapsulator` creates the frame stream used by the network RTL tests.

### Baseline encapsulation with round-trip checking

```bash
python -m golden.network_encapsulator \
    build/golden/itch_synthetic.bin \
    --frames-out build/network/frames.bin \
    --meta-out build/network/frames.jsonl \
    --messages-per-packet 3 \
    --seq-start 1 \
    --session SESSION1 \
    --check-roundtrip
```

Outputs:

```text
build/network/frames.bin    raw concatenated Ethernet II frames
build/network/frames.jsonl  frame lengths, sequence/count metadata, and source indices
```

### Duplicate one source frame

```bash
python -m golden.network_encapsulator \
    build/golden/itch_synthetic.bin \
    --duplicate-frame 5
```

### Emit a logical A/B duplicate stream

```bash
python -m golden.network_encapsulator \
    build/golden/itch_synthetic.bin \
    --ab-duplicate
```

### Drop one frame to create a sequence gap

```bash
python -m golden.network_encapsulator \
    build/golden/itch_synthetic.bin \
    --drop-frame 5
```

### Append heartbeat and end-of-session packets

```bash
python -m golden.network_encapsulator \
    build/golden/itch_synthetic.bin \
    --emit-heartbeat \
    --emit-eos
```

Useful additional options include `--src-port`, `--dst-port`, `--start-index`, and `--max-messages`.

`--check-roundtrip` is intended for non-destructive baseline encapsulation. Do not combine it with duplicate or drop campaigns whose output is intentionally different from the source stream.

---

## 5. Directed SystemVerilog / xsim tests

Directed SystemVerilog testbenches include:

```text
tb/data_handler_tb.sv
tb/xsim/frame_crack_tb.sv
tb/xsim/mold_seq_guard_tb.sv
tb/xsim/mold_deframe_tb.sv
tb/xsim/realign_tb.sv
tb/xsim/ingress_top_tb.sv
tb/xsim/symbol_router_tb.sv
tb/xsim/order_book_tb.sv
tb/xsim/order_book_top_tb.sv
tb/xsim/feed_handler_top_tb.sv
```

These testbenches are intended for Vivado 2023.2 / xsim. The repository does not currently provide one automated xsim Make target, so run them through the Vivado project:

1. add the required RTL package/modules to **Design Sources**;
2. add the chosen testbench to **Simulation Sources**;
3. set that testbench as the simulation top;
4. select **Run Simulation -> Run Behavioral Simulation**;
5. rerun after changing the top or source set.

The cocotb/Verilator tests are the primary automated golden-model scoreboards. The directed xsim tests provide focused Vivado-native checks and waveform debugging; they are not the FPGA synthesis flow.

---

## 6. Formatting

Install the hook once:

```bash
source .venv/bin/activate
pre-commit install
```

Run repository formatting and checks:

```bash
./scripts/format.sh
```

Equivalent direct command:

```bash
pre-commit run --all-files
```

Review formatting changes before staging them.

---

## 7. Generated files and cleanup

Generated files should remain outside source control:

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

### Clean cocotb output

```bash
cd tb
make clean-all
rm -rf sim_build results.xml dump.vcd *.vcd *.fst
cd ..
```

### Clean Python caches and generated vectors

```bash
find . -type d -name __pycache__ -prune -exec rm -rf {} +
find . -type d -name .pytest_cache -prune -exec rm -rf {} +
rm -rf build/golden build/network
```

### Rebuild a broken Python environment

```bash
cd ~/Documents/ITCH-Feed-Handler-and-Order-Book

deactivate 2>/dev/null || true
rm -rf .venv

export PATH="$HOME/.local/bin:$PATH"
uv python install 3.13
uv venv --python 3.13 --seed .venv
source .venv/bin/activate

uv pip install pip setuptools wheel
uv pip install -r requirements.txt
uv pip install pre-commit

python -VV
python -c "import cocotb; print(cocotb.__version__)"
verilator --version

cd tb
make
```

---

## 8. Common startup failures

Check the active tools:

```bash
which python
python -c "import cocotb; print(cocotb.__version__)"
which cocotb-config
which verilator
verilator --version
```

Typical causes are:

- `.venv` is not active;
- cocotb was installed into a different Python interpreter;
- an older `/usr/bin/verilator` is found before `$HOME/.local/bin/verilator`;
- the cocotb command is being run from the wrong directory;
- stale `sim_build` output remains after changing sources or top-level parameters.
