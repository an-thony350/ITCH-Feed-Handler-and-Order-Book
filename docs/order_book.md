# Order Book

The Order Book takes in data from the data handler, determining the stock which the data belongs to, passing the data to the correct order book, and updaing the order book and bid/ask price books.

---

## Format

The order book consits of 3 files in SystemVerilog (excluding the `hdl_header` file):

| File Name | Purpose |
| - | - |
| order_book_top | Top module which passes data from the symbol router to the correct order book |
| symbol_router | Collects the base price for the correct stock based of the stock locate value |
| order_book | updates the order and price books for the relevant stock, and sends the best bid/ask offer for the specific stock |

---

## Logic


### Order Book Top

The top module for the order book takes signals from the data handler. It then passes it to the symbol router and then to the correct order books. The data is sent to each order book, but is only passed in these modules if they have an asserted valid signal (to be explained in the symbol router).

Each order book held its own fifo in the top module, storing the output bbo data (i.e. `bbo_data_o` and `bbo_valid_o`), and a round-robin scheduler allowing for a fair output of bbo data from fifo to DMA.

### Symbol Router

The symbol router holds the data handler signals as they are passed directly from the top module. It also takes the base values of all the relevant stocks that we track (note that this base price is pre-determined in the PS, and delivered through AXI GPIO).

Through combinational logic, we pass the data from the data handler, ensuring it is passed and used in the correct order book.

Through sequential logic, we determine the correct order book that we are looking at based on the stock locate value. Once a stock comes in, we have its stock locate value changed in our processing system, and hard-code it to a specific value. If this value matches (after the valid-ready handshake), we pass the base price and the corresponding valid signal for the order book linked to that stock locate value.

### Order Book

The order book carries both combinational and sequential logic through a Mealy model state machne of 14 states allowing for both accurate data capture of orders for a specific stock, as well as two price books determining the best buy and sell prices

The function of the order book can be described through its following states:

1. `CLEAR`: In the sequential logic, the clear state is used to completely clear the BRAM blocks for the bid, ask, and order books, in addition to any other arrays or signals within the block, such as the `active_chunks` arrays, holding signals for sections of the bid/ask books which hold data. For combinational logic, the clear state clears address pointers and input data for True-Port RAM blocks (i.e. port a for all 3 books), while also enabling the write enable signal for this port. The next state is determined by whether the clear index has reached its maxed value (and thus clearing every index in the books).

2. `IDLE`: This is the default state the order book is in. In this state we take the order refernece number (ORN) of the input data and hash this data. The order book acts as a hash map, hence this hashing function gives a reference for these ORNs. This is key for changing/deleting inputs to the book. We also latch the input data which is required for future states, also allowing for the posibility of pipelined inputs increasing throughput. We also write the hash indexes to the address pointers for the True-Port RAM, only moving to the next state if given a valid signal

    > Note that for the True-Port RAM, the b-ports are used exclusively for replacement data which required more complex work to be accurate

3. `IDX_REQ`: This state is takes the hash ids from the idle state, and passes them to the address ports of the order book preparing it for the next state. This state acts as a pipeline state between `IDLE` and `IDX_SEARCH` where the price index of the input data is latched to reduce logic complexity in other stages.This index value is found via the `price_to_idx` function, a function which scales down the price value as a delta from the base price, this simplifies the index search for BBO outputs.

4. `IDX_SEARCH`: This state looks at the hash id and determines whether this id is valid to use when updating the order book. For add instructions, this means that there is no other data in this entry. For other instructions, this means that the data within this entry is actually the correct data, given that hash collisiions can occur with ORNs. If this data is not valid for the given instruction, the state machine will return to the `IDX_REQ` state, changing the hash id until the correct one is found. Otherwise, it will enter the next state.

    To deal with hash collisions, we have a `MAX_PROBES` value which allows data which may hash to the same index a fixed value of indexes to search for space to place an order/ the actual correct order to change. The limitation with this is given a high load factor, data may be lost due to high congestion of data around a block of indexes. We have tried to negate this with a larger value of `HASH_W` which increases the number of available indexes (given this approach heavily increased BRAM utilisation, we are looking into increasing the `MAX_PROBES` value - from 16 to 32/64 - and decreasing the `HASH_w` to optimise utilisation as much as possible).

    If we find a valid address to place the hashed_entry, we will move to the `UPDATE_READ_TBL` state, if still searching, we will go back to the previous state to try again, otherwise, we will re-evluate the best BBO values in the `FETCH_BBO` state.

5. `UPDATE_READ_TBL`: This state latches the hashed data (found via the hash index in the order book) and the index for the price books is determined. In combinational logic, this state inserts relevant address port values for the bid and ask books (also using the `price_to_idx` function).

6. `UPDATE_READ_BOOK`: This state latches signals relevant for the bid/ask books, more specifically in sequential logic, we determine whether the replacement price is the same as the price value we ae currently looking at. We also determine if we need to reset a specific entry in these books.

    In addition to this, we also latch other relevant values from our bid/ask true-ports, i.e. the number of shares of the order we are looking at.

7. `UPDATE_WRITE`: This state updates the input data for all three books, through the latched data, and updates arrays with chunks and valid signals. This book will change depending on the type of signal (through the latched message type), and will either move to BBO evaluation logic or the extended logic for replace instructions.

    > Note that the actual order/bid/ask books are sequentially updated every clock cycle (given they are synthesised as True-Port BRAM), but the input data to them (i.e. the address pointers, the enable signals, and the input data) is combinationally updated, hence when talking about the book being "updated", we refer to the combinational assignments occuring in the relevant states, which lead to changes on the rising-edge of the clock which occurs irregardless of state

8. `REPLACE_ADD`: This state is for replace instructions specifcally. Given that these instructions are effectively a delete-and-add instruction compacted into one, we have to use this state to do the "add" instruction whereas the previous state does the "delete" instruction. We do all of the true-port BRAM assignment logic in the b-port.

9. `EVALUATE_BBO`: This state changes the best bid and ask prices in sequential logic, they use combinational signals which determine whether we have the current best bid/ask value with an add/replace message, or have to look for a now best value as the previous one had been depleted. If the best value can be found in 1 cycle, we move to the `FETCH_BBO` state. Otherwise, we move to the `BBO_SEARCH_REQ` state, introducing a further 2 clock cycles to find the next best bid/ask output.

10. `BBO_SEARCH_REQ`: This state searches for the specific chunk which holds the best bid/ask output. This is done by the `enc_valid` registers which assert a high signal if there exists a valid in the 64-bit chunk of bid/ask book data. Using a priority encoder, we can obtain the best order by picking the highest/lowest chunk.

11. `BBO_SEARCH_EVAL`: This state searches for the specific bit within the chunk evaluated in the previous step. We effectively carry out the same process we did for the chunk to find the msb/lsb bit (priority encoder through the `active_chunks` registers). Finally we determine the best bid/ask price (as a delta value)

12. `FETCH_BBO`: This is a stalling state which allows us to send the new best bid/ask values to the bid/ask books.

13. `FETCH_BBO_WAIT`: This is the state that calculates the best bid and ask prices (and the shares for these prices). We do this via adding the delta values of the `current_best` signals to the latched base price (effectively doing the reverse of the `price_to_idx` function).

14. `EMIT`: This sends a valid signal to send data via DMA.

---

## Testing

In testing, we used cocotb to form multiple tests with the order book in the golden model. In situations where the tests would fail, we would write specific SystemVerilog testbenches to test specific issues and read waveforms.

---

## Updates

Note that all previous updates for the order book can be found in the revisions at the top of the relevant sv files in the `./rtl` directory

Future updates (for next versions) include increasing `MAX_PROBES` and reducing `HASH_W`, as well as allowing for pipelined stages within the order book. We also plan to increase the number of books held in the system making the symbol router logic more relevant.
