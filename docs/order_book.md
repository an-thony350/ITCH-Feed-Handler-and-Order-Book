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

The symbol router holds the data handler signals as they are passed directly from the top module. It also takes the base values of all the relevant stocks that we track (note that this base price is pre-determined). They are hold in an array acting as ROM.

Through combinational logic, we pass the data from the data handler, ensuring it is passed and used in the correct order book.

Through sequential logic, we determine the correct order book that we are looking at based on the stock locate value. Once a stock comes in, we have its stock locate value changed in our processing system, and hard-code it to a specific value. If this value matches (after the valid-ready handshake), we pass the base price and the corresponding valid signal for the order book linked to that stock locate value.

### Order Book

The order book holds a state machine which allows for sequential updating of the order and price books.

1. `CLEAR`: The clear state is used to completely clear the BRAM blocks for the bid, ask, and order books, in addition to any other arrays or signals within the block, such as the `active_chunks` arrays, holding signals for sections of the bid/ask books which hold data.

2. `IDLE`: This is the default state the order book is in. In this state we take the order refernece number (ORN) of the input data and hash this data. The order book acts as a hash map, hence this hashing function gives a reference for these ORNs. This is key for changing/deleting inputs to the book.

3. `IDX_REQ`: This state is takes the hash ids from the idle state, and passes them to the address ports of the order book preparing it for the next state.

4. `IDX_SEARCH`: This state looks at the hash id and determines whether this id is valid to use when updating the order book. For add instructions, this means that there is no other data in this entry. For other instructions, this means that the data within this entry is actually the correct data, given that hash collisiions can occur with ORNs. If this data is not valid for the given instruction, the state machine will return to the `IDX_REQ` state, changing the hash id until the correct one is found. Otherwise, it will enter the next state.

5. `UPDATE_READ_TBL`: This state latcheds the input data and inserts relevant address port values for the bid and ask books.

6. `UPDATE_READ_BOOK`: This state latches values from the output BRAM data depending on the type of signal (bid/ask).

7. `UPDATE_WRITE`: This state updates the order book, through the latched data, and updates arrays with chunks and valid signals. This book will change depending on the type of signal (through the message type), and will either move to the chunk logic or the extended logic for replace instructions

8. `REPLACE_ADD`: This state is for replace instructions specifcally. Given that these instructions are effectively a delete-and-add instruction compacted into one, we have to use this state to do the "add" instruction whereas the previous state does the "delete" instruction

9. `BBO_CHUNK_PRIORITY`: This state searches for the critical valid signal in the bid/ask books, this is to give us the highest bid price and lowest ask price.

10. `BBO_BIT_PRIORITY`: This state searches through the specific chunk determined in the previous state, finding the exact position of the critical valid signal.

11. `FETCH_BBO`: This is a stalling state which allows us to find the multiple used to determine the actual best bid and ask prices.

12. `FETCH_BBO_WAIT`: This is the state that calculates the best bid and ask prices (and the shares for these prices).

13. `EMIT`: This sends a valid signal to send data via DMA.
