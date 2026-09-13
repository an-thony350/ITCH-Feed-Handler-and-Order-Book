# Documentation

Technical documentation for the FPGA Nasdaq ITCH feed handler and order book.

## Architecture

- [RTL datapath](rtl_datapath.md) - complete PL datapath, clock domains, latency and throughput
- [Networking ingress](networking_ingress.md) - Ethernet, UDP, MoldUDP64 and ITCH decode pipeline
- [MoldUDP64 sequence handling](moldudp64_seq_handling.md) - sequence, duplicate and gap handling
- [Pipelined order book](pipelined_order_book.md) - current pipelined order-book architecture
- [Order book](order_book.md) - original order-book architecture and supporting context
- [Processing system](processing_system.md) - ZCU106 PS, DMA replay and hardware regression flow

## Verification and Usage

- [Golden model and verification](golden_model.md) - Python reference model and verification architecture
- [Running the project](running_the_project.md) - simulation, regression and hardware workflows
- [Environment](environment.md) - development environment and toolchain setup
