# v2.0 Release Instructions

By following the instructions below, you should have the ability to download our hardware design (along with all relevant RTL), as well as generate your own bitstream with this design.

If you want to just run the processing system, the `v2release.bit` and `v2release.hwh` files are available for download and you can skip to the [Processing System Instructions](#processing-system-instructions)

---

## Pre-requisites

To run this design, there are a couple pre-requisites that must be noted before running the design.

- The software used for this design is **Vivado 2023.2**
- The board used for this design is **PYNQ-Z1**, or part **xc7z020clg400-1**

---

## Hardware Instructions

1. Clone the repository using the following commands below, noting your repository path.

```bash
git clone --no-checkout --single-branch --branch release-v2 https://github.com/an-thony350/ITCH-Feed-Handler-and-Order-Book
cd ITCH-Feed-Handler-and-Order-Book
git sparse-checkout init --cone
git sparse-checkout set v2.0
git checkout release-v2
```

2. Open Vivado 2023.2
3. In the Tcl Console, enter the following command: `cd <repository path>/v2.0`
4. Enter the command `source build_project.tcl`

---

## Bitsream Generation

If you would like to generate your own bitstream, you must ensure that the correct implementation stratergy is used:

1. When in the project screen in Vivado, look for the `settings`
2. When selecting the `settings`, a panel should open. Select `Implementation` on the left of that panel
3. When selecting `Implementation`, look to the right for `Settings` as a subheader, and then `Stratergy` as a sliding window
4. Select `Performance_ExtraTimingOpt`
5. Select `Apply` at the bottom of the panel and `OK`

Once completing the Hardware & implementation instructions, enter the following command:

`source bitstream.tcl`

> Note that this command takes a prolonged amount of time due to OOC synthesis on all the IP modules, it is heavily recommended to use the given bit and hwh files in the repository, however this is left as an option if desired.

---

## Processing System Instructions

The notebook used to run this can be found in [`v2.0/processing_system`](v2.0/processing_system). The following instructions should provide detail on how to use this system.


1. Upload all the files given in this directory to a jupyter directory (keep note of this directory) - If you are using your own bit and hwh files, then these specific files can be ignored

2. Before trying to run the system, you must set up a remote SSH tunnel. This can be done by going to your terminal and pasting the following instruction (noting the IP of your board)
    ```bash
    ssh -R 8443:emi.nasdaq.com:443 xilinx@<BOARD_IP>
    ```
    > Note that the value `8843` can be changes, but it is reccommended to keep this value.

3. To check this has worked, open another terminal window and paste the following code:
    ```bash
    nc -zv 127.0.0.1 8443
    ```
    You should see something like this: `Connection to 127.0.0.1 8443 port [tcp/*] succeeded!`

4. Historical Nasdaq ITCH data can be found from this [website](https://emi.nasdaq.com/ITCH/Nasdaq%20ITCH/), this data should have the form `<date>.NASDAQ_ITCH50.gz`. If you are unable to stream the data, you can download from here
5. Using the notebook `v2_notebook.ipynb`, proceed to test the hardware and software designs, changing constants in the second cell where necessary
