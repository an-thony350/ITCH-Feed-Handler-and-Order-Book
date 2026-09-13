# V4.0 Hardware Design Licensing

The V4.0 FPGA hardware design integrates the
[Taxi transport library](https://github.com/fpganinja/taxi) by
FPGA Ninja, LLC.

Taxi core RTL used by this design is provided under the
**CERN Open Hardware Licence Version 2 - Strongly Reciprocal
(CERN-OHL-S-2.0)** unless an individual Taxi source file states
otherwise.

The complete CERN-OHL-S-2.0 licence text is retained with the Taxi
source at:

`lib/taxi/LICENSE`

Some Taxi components and example-design files are distributed under
other licences, including the MIT licence. Their original SPDX,
copyright, author and licence notices are retained in the corresponding
source files.

## V4.0 integration

The V4.0 design integrates Taxi Ethernet, AXI Stream, synchronisation
and APB components with the project's Nasdaq ITCH feed-handler and
hardware order-book datapath.

The Taxi ZCU106 Ethernet example was used as a reference when
developing the V4.0 10GbE frontend. The project-specific frontend
adapts this structure for the receive-oriented ITCH datapath and
exposes the required link and error status signals.

The complete source required to rebuild the V4.0 FPGA design is
provided in this repository, including:

- project RTL;
- Taxi source used by the design;
- Vivado block-design reconstruction scripts;
- constraints;
- custom IP sources; and
- bitstream-generation scripts.

The upstream Taxi project is available at:

https://github.com/fpganinja/taxi

## Repository licence scope

Project-specific software, documentation and independently authored
components outside the scope of the Taxi-integrated V4.0 hardware
design remain subject to the repository's root MIT licence unless
otherwise stated.

Original third-party licence notices take precedence for the files to
which they apply.
