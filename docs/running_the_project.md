# Running the Project

This document contains the repository's executable workflows. Complete toolchain installation is documented in [`environment.md`](environment.md); golden-model and verification contracts are documented in [`golden_model.md`](golden_model.md).

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

The current default target runs:

1. golden Python compilation, unit tests, and oracle generation;
2. MoldUDP64 sequence-guard tests;
3. merged `data_realign` decoder tests;
4. legacy `data_handler` regression tests;
5. direct order-book tests;
6. router/book wrapper tests;
7. legacy `ingress_top` regression tests;
8. current native-64-bit `ingress_data_realign_top` tests;
9. legacy `feed_handler_top` network-to-book regression tests.

The legacy paths are intentionally retained as regression/reference implementations. The active Vivado ingress uses the native-64-bit `ingress_data_realign_top` architecture.

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
| `make test-data-realign` | Current packed-message decoder |
| `make test-ingress-data-realign` | Current 64-bit Ethernet/MoldUDP64-to-event ingress |
| `make test-ingress-data-realign-probe` | Current ingress through the performance-probe wrapper |
| `make test-ingress-data-realign-perf` | Current ingress/decode latency test |
| `make test-order-book` | Direct order-book lifecycle and oracle BBO tests |
| `make test-order-book-top` | Symbol-router and three-book wrapper tests |
| `make test-data-handler` | Legacy standalone decoder regression |
| `make test-ingress` | Legacy `ingress_top` regression |
| `make test-feed-handler-top` | Legacy complete network-to-book regression |
| `make test-rtl` | Current default RTL correctness set without regenerating the golden oracle |
| `make test-all` | Golden generation followed by `test-rtl` |

For example, to run the current merged ingress:

```bash
cd tb
make test-ingress-data-realign
```

Direct cocotb invocation is also available:

```bash
make TOPLEVEL=ingress_data_realign_top MODULE=test_ingress_data_realign CLOCK_MHZ=156.25
```

The Makefile selects the required RTL sources, adds the repository and test harness to `PYTHONPATH`, and enables SystemVerilog, timing, and trace support.

### DMA/Taxi source-boundary tests

The source-boundary blocks can be tested directly:

```bash
make TOPLEVEL=lane_rewire MODULE=test_lane_rewire
make TOPLEVEL=axis_source_mux MODULE=test_axis_source_mux
make TOPLEVEL=source_boundary_equiv_top MODULE=test_source_boundary_equiv
```

---

## 3. Native 64-bit line-rate regression

The preferred current ingress performance target is in `Makefile.line_rate`.

From `tb/`:

```bash
make -f Makefile.line_rate ingress-smoke
```

runs the short smoke campaign.

```bash
make -f Makefile.line_rate ingress-measure
```

runs the full measurement campaign without enforcing the pass/fail threshold.

```bash
make -f Makefile.line_rate ingress-gate
```

runs the native-64-bit ingress campaign with the calculated physical 10GbE wire-rate requirement enforced.

The current test uses a modelled ingress clock of:

```text
156.25 MHz
```

and writes results beneath:

```text
build/perf/data_realign_ingress_line_rate/
```

The older aligned-ITCH ingress measurement is retained for A/B comparison through the `legacy-ingress-*` targets, but it is not the preferred measurement for the current architecture.

---

## 4. Generate golden-model oracle files

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

## 5. Generate network test vectors

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

## 6. ZCU106 deterministic hardware regression

The current board regression is:

```text
notebooks/v3_1_notebook.ipynb
```

It loads the matching `.bit`/`.hwh` overlay and runs historical ITCH data through:

```text
PS DDR -> AXI DMA -> native 64-bit PL ingress -> order books -> BBO GPIO
```

The notebook then runs the same source range through the Python golden model and compares the resulting BBO-change sequences.

This is a **correctness regression**, not a throughput benchmark: the notebook waits for each DMA transfer to complete before issuing the next one.

Configuration, price conversion, symbol mapping, and comparison behaviour are documented in [`processing_system.md`](processing_system.md).

---

## 7. Directed SystemVerilog / xsim tests

Directed SystemVerilog testbenches are under `tb/xsim/`, including:

```text
tb/xsim/data_handler_tb.sv
tb/xsim/feed_handler_top_tb.sv
tb/xsim/frame_crack_tb.sv
tb/xsim/ingress_top_tb.sv
tb/xsim/mold_deframe_tb.sv
tb/xsim/mold_seq_guard_tb.sv
tb/xsim/order_book_tb.sv
tb/xsim/order_book_top_tb.sv
tb/xsim/realign_tb.sv
tb/xsim/symbol_router_tb.sv
```

These testbenches are intended for Vivado 2023.2 / xsim. The repository does not currently provide one automated xsim Make target, so run them through the Vivado project:

1. add the required RTL package/modules to **Design Sources**;
2. add the chosen testbench to **Simulation Sources**;
3. set that testbench as the simulation top;
4. select **Run Simulation -> Run Behavioral Simulation**;
5. rerun after changing the top or source set.

The cocotb/Verilator tests are the primary automated golden-model scoreboards. The directed xsim tests provide focused Vivado-native checks and waveform debugging.

---

## 8. Formatting

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

## 9. Generated files and cleanup

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
uv pip install -r requirements-dev.txt

python -VV
python -c "import cocotb; print(cocotb.__version__)"
verilator --version

cd tb
make
```

---

## 10. Common startup failures

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
