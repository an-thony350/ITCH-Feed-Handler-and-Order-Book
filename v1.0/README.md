# v1.0 Release Instructions

By following the instructions below, you should have the ability to download our hardware design (along with all relevant RTL), as well as generate your own bitstream with this design.

If you want to just run the processing system, the `v1release.bit` and `v1release.hwh` files are available for download and you can skip to the [Processing System Instructions](#processing-system-instructions)

## Pre-requisites

To run this design, there are a couple pre-requisites that must be noted before running the design.

- The software used for this design is **Vivado 2023.2**
- The board used for this design is **PYNQ-Z1**, or part **xc7z020clg400-1**

## Hardware Instructions

1. Clone the repository using the following commands below, noting your repository path.

```
git clone --no-checkout --single-branch --branch release-v1.0 https://github.com/an-thony350/ITCH-Feed-Handler-and-Order-Book
cd ITCH-Feed-Handler-and-Order-Book
git sparse-checkout init --cone
git sparse-checkout set v1.0
git checkout release-v1.0
```

2. Open Vivado 2023.2
3. In the Tcl Console, enter the following command: `cd <repository path>/v1.0`
4. Enter the command `source build_project.tcl`

## Bitsream Generation

If you would like to generate your own bitstream, once completing the Hardware Instructions, enter the following command:

`source bitstream.tcl`

> Note that this command takes a prolonged amount of time due to OOC synthesis on all the IP modules, it is heavily recommended to use the given bit and hwh files in the repository, however this is left as an option if desired.

## Processing System Instructions

The notebook used to run this can be found in `v1.0/processing_system`. The following instructions should provide detail on how to use this system.

> This current system requires you to download the historical data, and also requires a jupyter notebook connection to the board's IP address we are looking into updating these issues in future releases

1. Upload all the files given in this directory to a jupyter directory (keep note of this directory) - If you are using your own bit and hwh files, then these specific files can be ignored
2. Download and upload historical Nasdaq ITCH data from this [website](https://emi.nasdaq.com/ITCH/Nasdaq%20ITCH/), this data should have the form `<date>.NASDAQ_ITCH50.gz`
3. Using the notebook `v1_notebook.ipynb`, proceed to test the hardware and software designs, changing constants in the second cell where necessary
