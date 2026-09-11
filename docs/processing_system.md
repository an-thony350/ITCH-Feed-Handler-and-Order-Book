# Processing System

The Processing System is used to run deterministic hardware tests on the ZCU106 and compare the resulting BBO state against the Python golden model using historical Nasdaq ITCH 5.0 data.

The current board regression is in `notebooks/v3_1_notebook.ipynb`. It uses the PS DDR -> AXI DMA -> PL path to exercise the native 64-bit ingress. This is a correctness regression rather than a throughput benchmark.

The notebook can stream the historical data through a reverse SSH tunnel or open a local gzip file.

## User Functions

The main user-configurable values are:

- `PATH`: path to the matching `.bit` and `.hwh` overlay files.
- `DATA_URL`: URL or local path for the historical Nasdaq ITCH gzip file.
- `SW_MESSAGES_TO_READ`: number of source messages used by the software golden-model run.
- `MSG_LIMIT`: when enabled, limits the hardware run to the same source-message range.
- `SW_TARGET_SYMBOL`: single stock compared against the golden model.
- `HW_SYMBOL_0`, `HW_SYMBOL_1`, `HW_SYMBOL_2`: the three stocks tracked in hardware.
- `BASE_PRICE_STOCK_0`, `BASE_PRICE_STOCK_1`, `BASE_PRICE_STOCK_2`: base prices for the three hardware order books.

Hardware symbols use the 8-byte ITCH stock field, for example:

```python
HW_SYMBOL_1 = b"MSFT    "
```

The base price must be chosen so that the relevant BBO prices remain inside the hardware price window. Prices below the configured base are not representable by the current order-book implementation.

## Network Header Generation

The historical BinaryFILE data does not contain Ethernet/IP/UDP/MoldUDP64 headers, so the notebook uses `generate_network_headers` to reconstruct the network framing required by the PL ingress.

Each replay packet contains:

```text
Ethernet II
IPv4
UDP
MoldUDP64
2-byte MoldUDP64 message length
ITCH message
```

The generated packets use the fixed IPv4/UDP format supported by the hardware ingress. The UDP checksum field is set to zero.

This allows the DMA replay to exercise the same `frame_crack`, MoldUDP64 and ITCH decode path as the Ethernet input.

## Gzip Data Streaming

The historical data is taken from the public Nasdaq ITCH archive.

The default notebook configuration accesses it through a reverse SSH tunnel using a localhost URL such as:

```text
https://localhost:8443/ITCH/Nasdaq%20ITCH/12302019.NASDAQ_ITCH50.gz
```

The stream is wrapped in a buffered reader to avoid loading the complete gzip file into memory.

A local gzip path can be supplied instead when remote streaming is not being used.

## Hardware Run

The hardware run first watches Stock Directory (`R`) messages to discover the real Nasdaq stock-locate values for the configured hardware symbols.

Those locate values are then remapped to the three IDs used by the hardware symbol router:

```text
1 -> stock 0
2 -> stock 1
3 -> stock 2
```

Price-bearing messages are converted from the original ITCH `Price(4)` representation to whole cents before they are sent to the FPGA:

```text
hardware_price = itch_price // 100
```

The configured hardware base prices use the same cent units.

The modified ITCH message is then wrapped with the synthetic network headers and sent through the 64-bit MM2S DMA.

Because the MM2S/ingress path is 64-bit:

- the backing buffer uses `np.uint64`;
- each packet is padded to an 8-byte storage boundary;
- each 64-bit word is byte-swapped so the first network byte appears in the MSB lane expected by the ingress;
- the final padded word is transmitted in full.

The extra zero bytes are harmless Ethernet padding because `frame_crack` uses the UDP length to determine the true MoldUDP64 payload boundary.

The notebook waits for each DMA transfer to complete before sending the next packet. This keeps the board test deterministic, but means this run must not be treated as an ingress-throughput benchmark.

### BBO capture

BBO data is read through the AXI GPIO interfaces.

The notebook records a new hardware state whenever any of the following changes:

```text
bid price
bid shares
ask price
ask shares
```

Readable text files are produced for inspection, while the JSONL output is used for the hardware/software comparison.

Hardware prices are multiplied by 100 when written to the comparison JSONL so they return to the golden model's original `Price(4)` units.

## Software Run

The software run reads the same source-message range and passes it through the Python golden model.

By default:

```text
SW_MESSAGES_TO_READ = 1,000,000
```

The main comparison file is:

```text
golden_states_<symbol>.jsonl
```

The 64-bit hardware migration does not change the golden-model semantics; it only changes the transport used to deliver the messages to the RTL.

## Hardware/Software Comparison

The comparison checks the hardware and software **BBO-change sequences** over the same source-message range.

Two representation differences are handled explicitly:

- an empty golden-model book side is represented as `None`, while the hardware GPIO value is `0`;
- golden states with a non-empty BBO price below the configured hardware base price are not representable and are reported separately rather than treated as semantic mismatches.

Any genuine semantic mismatches are written to:

```text
error_log.txt
```

Skipped out-of-range golden states are written to:

```text
comparison_skipped.jsonl
```

A successful regression reports zero semantic mismatches for the comparable states.
