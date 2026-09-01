# Pipelined Order Book

> Note that information for the top module, and symbol router also part of the entire order book system can be found in the [v2 varient](/docs/order_book.md) of the order book. The information about the v2 rder book may also provide good context for the changes made here. However, this document should provide a comprehensive description of what occurs in this block

The Pipelined Order Book is an updated version of the v2 order book. It is now a 10-stage pipeline which takes in data from the data handler, updates the order book and bid/ask price books, and outputs the BBO outputs.

---

## Format

The design of this module can be explained through this diagram below:

```mermaid
flowchart LR
    %% Data Stores
    subgraph Data_Stores ["Multi-pumped Memory Blocks holding order and price books"]
        K[(order_table)]
        L[(price_book)]
    end

    %% Pipeline States
    subgraph Pipeline ["Order Book Pipeline"]
        A([ob_idle]) --> B[ob_idx_req]
        B --> C[ob_idx_search]
        C --> D[ob_update_read_tbl]
        D --> E[issue_book_read]
        E --> F[update_read_book]
        F --> G[update_write]
        G --> H[bbo_evaluate]
        H --> I[bbo_resolve]
        I --> J([bbo_out])
    end

    %% Table Interactions
    A -.-> K
    B -.-> K
    K -.-> C
    G -.-> K
    G -.-> L
    L -.-> J

```
---

## Logic

Each block has a specific function which is similar to that of the v2 order book states. They will be referred to here, but a full description of the block will be given otherwise.

### ob_idle

The ob_idle block acts similar to the `IDLE` state. In this block
