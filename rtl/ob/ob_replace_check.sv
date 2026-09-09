import hdl_header::*;

module ob_replace_check(
    input logic                 clk,
    input logic                 rst_n,
    input logic                 stall,
    input logic                 stage_valid_i,
    input o_data_raw_t          input_rdata,

    output logic                stage_valid_o,
    output o_data_t             rdata_o,
    output logic                latched_rep_delete_o,
    output logic                latched_rep_add_o,
    output logic                ready_o
);

logic        call_replace;

o_data_raw_t held_rdata;
o_data_t     passed_data;
logic        rep_add_valid;
logic        rep_delete;
logic        rep_add;

assign ready_o = !call_replace;


// Combinational checking of replace instruction
always_comb begin
    passed_data     = '0;
    rep_delete      = 1'b0;
    rep_add         = 1'b0;
    rep_add_valid   = 1'b0;

    if(call_replace) begin
        passed_data.message_type = MSG_ADD_A;
        passed_data.orn          = held_rdata.updated_orn;
        passed_data.side         = held_rdata.side;
        passed_data.shares       = held_rdata.shares;
        passed_data.price        = held_rdata.price;
        rep_add_valid            = 1'b1;
        rep_add                  = 1'b1;
    end
    else if(stage_valid_i && input_rdata.message_type == MSG_REPLACE && !call_replace) begin
        passed_data.orn          = input_rdata.orn;
        passed_data.message_type = MSG_DELETE;
        passed_data.side         = input_rdata.side;
        passed_data.shares       = input_rdata.shares;
        passed_data.price        = input_rdata.price;
        rep_delete               = 1'b1;
        rep_add_valid            = 1'b1;
    end
    else if(!call_replace) begin
        passed_data.message_type = input_rdata.message_type;
        passed_data.orn          = input_rdata.orn;
        passed_data.side         = input_rdata.side;
        passed_data.shares       = input_rdata.shares;
        passed_data.price        = input_rdata.price;
        rep_add_valid            = stage_valid_i;
    end
end

// Sequential logic handling replace instructions
always_ff @(posedge clk) begin
    if(!rst_n) begin
        call_replace  <= '0;
        held_rdata    <= '0;
    end
    else if(!stall) begin
        call_replace    <=  1'b0;
        if(stage_valid_i && input_rdata.message_type == MSG_REPLACE && !call_replace) begin
            call_replace     <= 1'b1;
            held_rdata       <= input_rdata;
        end
    end
end

always_ff @(posedge clk) begin
    if(!rst_n) begin
        stage_valid_o           <=  1'b0;
    end
    else if(!stall) begin
        stage_valid_o           <=  rep_add_valid;
        rdata_o                 <=  passed_data;
        latched_rep_delete_o    <=  rep_delete;
        latched_rep_add_o       <=  rep_add;
    end
end
endmodule
