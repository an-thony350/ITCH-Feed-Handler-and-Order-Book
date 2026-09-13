# ITCH board-side visual demo

This folder is the user-facing ZCU106 demonstration application.

```text
local Nasdaq .gz
    |
board-side Python
    |
64-bit AXI DMA
    |
current FPGA ingress -> order books
    |
existing BBO AXI GPIOs
    |
cached Python state + oracle comparison
    |
HTTP
    |
laptop browser
```

The browser never reads or controls the FPGA directly.

## Fixed showcase configuration

Dataset:

```text
12302019.NASDAQ_ITCH50.gz
```

Source-message range:

```text
shortest deterministic BinaryFILE prefix that produces at least
400 hardware-comparable BBO updates for each showcase stock
```

The generator records the **exact** resulting source-message limit and SHA-256
in the oracle. The dashboard then replays that frozen prefix; it does not choose
a new range at run time.

Stocks and hardware base prices:

```text
AAPL    21000 cents
MSFT    12000 cents
NFLX    32000 cents
```

The demo is a correctness/visualisation path, not a throughput benchmark.

For graph presentation, the backend retains only the latest **320** BBO changes
per stock. Oracle verification still covers every hardware BBO change in the
full frozen replay. This keeps the three charts visually comparable and prevents
early-book warm-up values from permanently dominating the y-axis.

## 1. Copy the demo to the ZCU106

The complete demo directory can be copied from the development machine to the
ZCU106 over SSH.

The instructions below assume:

```text
Board IP:       192.168.2.99
Board user:     xilinx
Board location: /home/xilinx/jupyter_notebooks/ITCH_demo
```

From a terminal on the development machine, navigate to the root of the
repository:

```bash
cd <path-to-repository>/ITCH-Feed-Handler-and-Order-Book
```

First create the destination directory on the board:

```bash
ssh xilinx@192.168.2.99 "mkdir -p /home/xilinx/jupyter_notebooks/ITCH_demo"
```

Then copy the complete contents of the local `demo/` directory:

```bash
scp -r demo/. xilinx@192.168.2.99:/home/xilinx/jupyter_notebooks/ITCH_demo/
```

Enter the `xilinx` account password when prompted.

Once the transfer has completed, connect to the board:

```bash
ssh xilinx@192.168.2.99
```

and verify the demo files:

```bash
cd /home/xilinx/jupyter_notebooks/ITCH_demo
ls
```

The directory should contain the demo scripts, FPGA bitstream/HWH files,
golden-model files, static web assets and `data/` directory.

### Nasdaq dataset

The historical Nasdaq dataset is not stored in the repository. The following
file must additionally be present:

```text
/home/xilinx/jupyter_notebooks/ITCH_demo/data/12302019.NASDAQ_ITCH50.gz
```

Download instructions are provided in:

```text
data/DOWNLOAD_DATA.txt
```

If the dataset has already been downloaded onto the development machine, it can
instead be copied directly to the board with:

```bash
scp 12302019.NASDAQ_ITCH50.gz \
  xilinx@192.168.2.99:/home/xilinx/jupyter_notebooks/ITCH_demo/data/
```

Do not extract the `.gz` file. The demo reads the compressed dataset directly.

Finally, make the launch scripts executable:

```bash
cd /home/xilinx/jupyter_notebooks/ITCH_demo
chmod +x generate_oracle.sh run_demo.sh
```

## 2. Generate the oracle once

The oracle is generated from the same local Nasdaq gzip file using the trusted
Python golden parser/order book.

From the board:

```bash
cd /home/xilinx/jupyter_notebooks/ITCH_demo
chmod +x generate_oracle.sh run_demo.sh
./generate_oracle.sh
```

This creates:

```text
oracle/demo_oracle.json
```

By default, the generator keeps scanning the historical feed until AAPL, MSFT
and NFLX have each produced at least 400 comparable BBO changes. With the
current 1,000,000-message baseline producing roughly 238 / 128 / 1,191 changes
for AAPL / MSFT / NFLX, this deliberately extends the range far enough that the
least-active stock no longer produces a sparse chart.

The oracle metadata records:

- exact source-message limit selected by the generator;
- AAPL/MSFT/NFLX locate codes;
- fixed base prices;
- SHA-256 of the exact selected BinaryFILE record prefix;
- SHA-256 hashes of the exact bundled golden-model source files;
- expected per-stock hardware-visible BBO sequences.

The workload hash means a different dataset or source-message range cannot
silently receive a PASS.

If a shorter fixed prefix is needed for a quick debug run, explicit
mode is available:

```bash
MESSAGE_LIMIT=1000000 ./generate_oracle.sh
MESSAGE_LIMIT=1000000 ./run_demo.sh
```

## 3. Run the demo

From either the normal `xilinx` PuTTY shell or an existing root/PYNQ shell:

```bash
cd /home/xilinx/jupyter_notebooks/ITCH_demo
./run_demo.sh
```

`run_demo.sh` automatically recreates the root PYNQ/XRT environment proven
during Gate 1 bring-up. If launched as `xilinx`, sudo may ask for the board
password once.

Then open:

```text
http://192.168.2.99:8080
```

and press `Run`.
