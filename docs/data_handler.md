# Data Handler

The Data Handler parses the data taken in the form detailled in the [Nasdaq TotalView-ITCH 5.0 specification](https://www.nasdaqtrader.com/content/technicalsupport/specifications/dataproducts/NQTVITCHSpecification.pdf).

---

## Format

The Data Handler is composed of 3 files in system verilog (excluding the `hdl_header` file containing relevant parameter and struct definitions for this module). Their names, and purpose are detailed below:

| File name | Purpose |
| - | - |
| data_handler_top | Top file which controls the AXI module and key module labelled below |
| data_handler_AXI | This file allows for byte transfer between the AXI-DMA (which sends 32-bytes of ITCH data) and the data handler |
| data_handler | This file controls the parsing of the bytes of data, detemining the changes equired in the order book and price books in the next module |

---

## Logic

The data handler can be simplified into 2 parts in terms of RTL design.

1. Combinational State machine calculation
2. Sequential data parsing logic

However, there are some details within these two parts which are speciifed for this design due to specification, and the limitations of the board.

### Combinational State Machine Calculation

Our state machine uses 4 states to parse data, keeping the machine logic simple.

1. `IDLE`: This is the default state of the machine, until we recieve valid data from the AXI-DMA, we stay in this state. Once we receive this valid data, we look at the most significant top two bytes. According to the specification, in all cases, this will give us the message type, determining what the next state, and consequent calculations to the order book will be.

2. `ADD_CAP`: This state is entered when we recieve an "add" instruction, whether that me with, or without the MPID. This state allows us to parse data from these types of instructions correctly according to the specification

3. `MOD_CAP`: This state is entered when we recieve any instruction that isn't an "add" instruction (which is in chapters 1.4 in the specification), This state allows us to parse data from these types of instructions correctly according to the specification.

4. `SEND`: We enter this state after parsing is complete in either the `ADD_CAP` or `MOD_CAP` state. The output data is held in this state until the `ready_i` signal from the upstream block (i.e. the order_book) is ready to recieve this data, ensuring we don't have issues with backpressure (in using a valid-ready handshake).

### Sequential Data Parsing Logic

Our sequential logic allows us to parse 4-bytes of data per clock cycle, allowing us to obtain the entire message from the TotalView-ITCH packets.

In this block, we have determined how the data will arrive in each cycle looking at the specification. Then, given that the data is given in Big-Endian format, we have sliced each packet to ensure that we obtain the corrext data in each cycle.

This is done through a `word_count` which increments at each clock cycle (giving a worst case latency of 8 cycles).


---

## Testing

In testing, we used a SystemVerilog testbench, `data_handler_tb.sv`, to test every single type of message we allow through the data handler. The testbenches follow a `task` (function) call which each test a seperate type of call.

In testing, we achieved 100% accuracy, passing all tests and ensuring that relevant packets sent to the data handler will be parsed correctly.

---

## Updates

We are planning to have the following updates to this module:

- Update the packet width to 64, allowing for a higher data input per clock cycle.
- Add more messages noted in the spec, such as "start message" and "end of day" etc.
