.. _intro:

============
Introduction
============

The goal of the Taxi transport library is to provide a set of performant, easy-to-use building blocks in modern System Verilog facilitating data transport and interfacing, both internally via :term:`AXI` and AXI stream, and externally via Ethernet, :term:`PCI` express, :term:`UART`, and :term:`I2C`.  The building blocks are accompanied by testbenches and simulation models utilizing `Cocotb <https://www.cocotb.org/>`_ and `Verilator <https://www.veripool.org/verilator/>`_.

This library is currently under development; more components will be added over time as they are developed.

The latest source code is available from the `Taxi GitHub repository <https://github.com/fpganinja/taxi>`_.

License
=======

Taxi is provided by FPGA Ninja, LLC under either the `CERN Open Hardware Licence <https://cern-ohl.web.cern.ch/>`_ Version 2 - Strongly Reciprocal (CERN-OHL-S 2.0), or a paid commercial license.  Contact info@fpga.ninja for commercial use.  Note that some components may be provided under less restrictive licenses (e.g. example designs).

Under the strongly-reciprocal CERN OHL, you must provide the source code of the entire digital design upon request, including all modifications, extensions, and customizations, such that the design can be rebuilt.  If this is not an acceptable restriction for your product, please contact info@fpga.ninja to inquire about a commercial license without this requirement.  License fees support the continued development and maintenance of this project and related projects.

To facilitate the dual-license model, contributions to the project can only be accepted under a contributor license agreement.

Example Designs
===============

Example designs are provided for several different FPGA boards, showcasing many of the capabilities of this library.  Building the example designs will require the appropriate vendor toolchain and may also require tool and IP licenses.

*  Alpha Data ADM-PCIE-9V3 (Xilinx Virtex UltraScale+ XCVU3P)
*  Dini Group DNPCIe_40G_KU_LL_2QSFP (Xilinx Kintex UltraScale XCKU040)
*  Cisco Nexus K35-S (Xilinx Kintex UltraScale XCKU035)
*  Cisco Nexus K3P-S (Xilinx Kintex UltraScale+ XCKU3P)
*  Cisco Nexus K3P-Q (Xilinx Kintex UltraScale+ XCKU3P)
*  Silicom fb2CG\@KU15P (Xilinx Kintex UltraScale+ XCKU15P)
*  NetFPGA SUME (Xilinx Virtex 7 XC7V690T)
*  BittWare 250-SoC (Xilinx Zynq UltraScale+ XCZU19EG)
*  BittWare XUSP3S (Xilinx Virtex UltraScale+ XCVU095)
*  BittWare XUP-P3R (Xilinx Virtex UltraScale+ XCVU9P)
*  BittWare IA-420F (Intel Agilex F 014)
*  Intel Stratix 10 MX dev kit (Intel Stratix 10 MX 2100)
*  Intel Stratix 10 DX dev kit (Intel Stratix 10 DX 2800)
*  Intel Agilex F dev kit (Intel Agilex F 014)
*  Terasic DE10-Agilex (Intel Agilex F 014)
*  Xilinx Alveo U50 (Xilinx Virtex UltraScale+ XCU50)
*  Xilinx Alveo U55N/Varium C1100 (Xilinx Virtex UltraScale+ XCU55N)
*  Xilinx Alveo U200 (Xilinx Virtex UltraScale+ XCU200)
*  Xilinx Alveo U250 (Xilinx Virtex UltraScale+ XCU250)
*  Xilinx Alveo U280 (Xilinx Virtex UltraScale+ XCU280)
*  Xilinx Kria KR260 (Xilinx Zynq UltraScale+ XCK26)
*  Xilinx VCU108 (Xilinx Virtex UltraScale XCVU095)
*  Xilinx VCU118 (Xilinx Virtex UltraScale+ XCVU9P)
*  Xilinx VCU1525 (Xilinx Virtex UltraScale+ XCVU9P)
*  Xilinx ZCU102 (Xilinx Zynq UltraScale+ XCZU9EG)
*  Xilinx ZCU106 (Xilinx Zynq UltraScale+ XCZU7EV)

.. only:: html

    Indices and tables
    ==================

    * :ref:`genindex`
    * :ref:`modindex`
    * :ref:`search`
