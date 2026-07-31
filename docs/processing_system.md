# Processing system

The processing system, written in python allows users to actually test the hardwaare system and golden model with historical Nasdaq-ITCH 5.0 data.

The system uses a jupyter notebook where connection to the board (via reverse SSH) is required to run the system.

## User Functions

The cells have been arranged so that the user can alter some parts of the system without heavily impacting the performance of the system this includes the following:

- `PATH`: the path that the `.bit` and `.hwh` files generated in vivado are located in.
- `DATA_URL`: the url where the historical data is found
- `SW_MESSAGES_TO_READ`: the number of messages read by the golden model
- `MSG_LIMIT`: allows the user to set a limit to the number of hardware messages read
- `SW_TARGET_SYMBOL`: The stock tracked in the golden model
- `HW_SYMBOL`: The stocks tracked by the hardware design
- `BASE_PRICE`: The base price of the stocks being tracked in hardware

> Note that the base price must be determined by the user, and incorrect input to this could cause errors to hardware outputs

## Netowrk Header Generation

In the PS we use a function `generate_network_headers` to wrap our input data with netwrok headers. The sample data has stripped all of the headers, but for the purpose of our design, we re-add them in software.
Therefore, we can also guarantee that every single message will have an IPv4, and UDP protocol type (with checksum = to 0x0000 in all cases)

## Gzip Data Streaming

The histroical data used in our system is in the form of a gzip file from this [website](https://emi.nasdaq.com/ITCH/Nasdaq%20ITCH/).

In order to stream this data, rather than downloading it, the user is required to open a remote connection via a reverse SSH tunnel in their terminal. We then will stream the data remotely using a buffer to ensure that streaming doesn't cause extreme delay in the system.

If sreaming fails, the file will be downloaded locally.

## Hardware Run

With our hardware streaming cell, we first map the required symbols in a dictionary, assigning them hard-coded target locate values (i.e. the stock locate values used in the symbol router to choose a stock's order book). Once this is done, we can ensure that all the data which is of the stock we are looking for, will have its stock_locate value changed to pass through the entire system.

Before we send a message, we change the price given by the historical data. Because the data passes data with a `$0.00001` tick (i.e. going up 1 value in decimal translates to an increase in `$0.0001`), to save resources on the FPGA, we divide the price value by 100 (only if we get a price instruction)

Once we are ready to send a message, we package the modified message (due to price) with the network headers, pad the packet into 4-byte boundaries, and swap it into big endian form to send to the DMA.

In reading the BBO output data, we read through GPIO (when the `bbo_valid` signal is asserted). We compare the previous value to the new one (to ensure that there has been a BBO change), and if successful, we write the new data into a JSONL file and text file.

> Note that the test file is purely for readablility reasons for the user, the JSONL file is integral to our hw/sw comparison

## Software run

The software run works similarly to the hardware run by streaming data to the golden model. However, we set a hard limit (default 1,000,000) for the number of messages read given the golden model is much slower than the hardware alternative. We take the output of the model in two JSONL files, with `golden_states` being the one critical to our comparison.

## Hardware/Softare Comparison

In this cell, we compare the two aforementioned JSONL files, ensuring their data is precisely the same.
Given the golden model outputs data even if there is not a change, we only compare data if the software output has changes. This ensures that the comparison is fair.
The system will print any inconsistencies in an `error_log.txt` file which can be examined for further debugging
In our own testing we recieved the following output, confirming the system produces 100% accurate data.

```
Comparison Complete!
Number of errors: 0
```
