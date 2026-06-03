`timescale 1ns / 1ps

// slave_tx: Master-compatible 50-bit NRZ response transmitter.
// Active-state retrigger is intentionally ignored to prevent frame overlap.
module slave_tx (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [9:0]  i_BIT_DIV,
    input  wire [2:0]  i_NODE_ID,
    input  wire [31:0] i_PAYLOAD,
    input  wire        i_TX_TRIGGER,
    input  wire        i_TX_ENABLE,
    output wire        o_SERIAL_OUT,
    output wire        o_TX_ACTIVE,
    output wire        o_TX_DONE
);

    parameter [1:0] TX_IDLE   = 2'd0;
    parameter [1:0] TX_ACTIVE = 2'd1;
    parameter [1:0] TX_DONE   = 2'd2;

    wire        clk;
    wire        resetn;
    wire [9:0]  bit_div;
    wire [2:0]  node_id;
    wire [31:0] payload;
    wire        tx_trigger;
    wire        tx_enable;

    wire [34:0] encoder_data;
    wire [41:0] encoder_codeword;
    wire [49:0] tx_frame;
    wire [9:0]  bit_div_effective;
    wire        start_request;
    wire        bit_tick_last;
    wire        frame_tick_last;
    wire [5:0]  next_bit_cnt;
    wire [5:0]  next_frame_index;

    reg [1:0]  state_ff;
    reg [49:0] frame_ff;
    reg [5:0]  bit_cnt_ff;
    reg [9:0]  tx_clk_cnt_ff;
    reg        serial_bit_ff;
    reg        tx_done_ff;

    wire        serial_out;
    wire        tx_active;
    wire        tx_done;

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign bit_div = i_BIT_DIV;
    assign node_id = i_NODE_ID;
    assign payload = i_PAYLOAD;
    assign tx_trigger = i_TX_TRIGGER;
    assign tx_enable = i_TX_ENABLE;

    assign encoder_data = {node_id, payload};

    slave_hamming_enc u_slave_hamming_enc (
        .i_DATA(encoder_data),
        .o_CODEWORD(encoder_codeword)
    );

    assign tx_frame = {8'hAA, encoder_codeword};
    assign bit_div_effective = (bit_div == 10'd0) ? 10'd1 : bit_div;
    assign start_request = (state_ff == TX_IDLE) && tx_trigger && tx_enable;
    assign bit_tick_last = (tx_clk_cnt_ff == (bit_div_effective - 10'd1));
    assign frame_tick_last = bit_tick_last && (bit_cnt_ff == 6'd49);
    assign next_bit_cnt = bit_cnt_ff + 6'd1;
    assign next_frame_index = 6'd49 - next_bit_cnt;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state_ff <= TX_IDLE;
        end else begin
            if (state_ff == TX_IDLE) begin
                if (start_request) begin
                    state_ff <= TX_ACTIVE;
                end else begin
                    state_ff <= TX_IDLE;
                end
            end else if (state_ff == TX_ACTIVE) begin
                if (frame_tick_last) begin
                    state_ff <= TX_DONE;
                end else begin
                    state_ff <= TX_ACTIVE;
                end
            end else if (state_ff == TX_DONE) begin
                state_ff <= TX_IDLE;
            end else begin
                state_ff <= TX_IDLE;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            frame_ff <= 50'd0;
        end else begin
            if (start_request) begin
                frame_ff <= tx_frame;
            end else begin
                frame_ff <= frame_ff;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            bit_cnt_ff <= 6'd0;
        end else begin
            if (state_ff == TX_IDLE) begin
                bit_cnt_ff <= 6'd0;
            end else if (state_ff == TX_ACTIVE) begin
                if (bit_tick_last) begin
                    if (bit_cnt_ff == 6'd49) begin
                        bit_cnt_ff <= 6'd0;
                    end else begin
                        bit_cnt_ff <= next_bit_cnt;
                    end
                end else begin
                    bit_cnt_ff <= bit_cnt_ff;
                end
            end else begin
                bit_cnt_ff <= 6'd0;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            tx_clk_cnt_ff <= 10'd0;
        end else begin
            if (state_ff == TX_ACTIVE) begin
                if (bit_tick_last) begin
                    tx_clk_cnt_ff <= 10'd0;
                end else begin
                    tx_clk_cnt_ff <= tx_clk_cnt_ff + 10'd1;
                end
            end else begin
                tx_clk_cnt_ff <= 10'd0;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            serial_bit_ff <= 1'b0;
        end else begin
            if (state_ff == TX_IDLE) begin
                if (start_request) begin
                    serial_bit_ff <= tx_frame[49];
                end else begin
                    serial_bit_ff <= 1'b0;
                end
            end else if (state_ff == TX_ACTIVE) begin
                if (bit_tick_last) begin
                    if (bit_cnt_ff == 6'd49) begin
                        serial_bit_ff <= 1'b0;
                    end else begin
                        serial_bit_ff <= frame_ff[next_frame_index];
                    end
                end else begin
                    serial_bit_ff <= serial_bit_ff;
                end
            end else begin
                serial_bit_ff <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            tx_done_ff <= 1'b0;
        end else begin
            if (state_ff == TX_ACTIVE) begin
                tx_done_ff <= frame_tick_last;
            end else begin
                tx_done_ff <= 1'b0;
            end
        end
    end

    assign serial_out = (state_ff == TX_ACTIVE) ? serial_bit_ff : 1'b0;
    assign tx_active = (state_ff == TX_ACTIVE);
    assign tx_done = tx_done_ff;

    assign o_SERIAL_OUT = serial_out;
    assign o_TX_ACTIVE = tx_active;
    assign o_TX_DONE = tx_done;

endmodule
