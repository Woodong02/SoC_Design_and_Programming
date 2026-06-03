`timescale 1ns / 1ps

module slave_top (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_MASTER_SERIAL,
    input  wire [31:0] i_PAYLOAD,
    output wire        o_SLAVE_SERIAL,
    output wire        o_SYNCED,
    output wire        o_HALTED,
    output wire [9:0]  o_LATCHED_GUARD_TICKS
);

    parameter [2:0] NODE_ID = 3'd0;
    parameter [2:0] NODE_CNT = 3'd4;
    parameter [9:0] BIT_DIV = 10'd1024;
    parameter [9:0] GUARD_TICKS_DEFAULT = 10'd256;

    wire        clk;
    wire        resetn;
    wire        master_serial;
    wire [31:0] payload_in;

    wire [41:0] rx_codeword;
    wire        rx_codeword_valid;
    wire        rx_sync_pulse;
    wire [15:0] rx_sync_clk_cnt;
    wire        rx_preamble_err;

    wire [34:0] decoded_broadcast_data;
    wire        hamming_1bit_err;
    wire        hamming_2bit_err;

    wire        control_tx_enable;
    wire [9:0]  control_latched_guard_ticks;
    wire [31:0] control_payload;
    wire        control_halted;

    wire        timer_synced;
    wire [2:0]  timer_slot;
    wire [15:0] timer_clk_cnt;
    wire        timer_tx_trigger;

    wire        tx_serial_out;
    wire        tx_active;
    wire        tx_done;

    assign clk           = i_CLK;
    assign resetn        = i_RESETN;
    assign master_serial = i_MASTER_SERIAL;
    assign payload_in    = i_PAYLOAD;

    slave_rx u_slave_rx (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_BIT_DIV(BIT_DIV),
        .i_SERIAL_IN(master_serial),
        .o_CODEWORD(rx_codeword),
        .o_CODEWORD_VALID(rx_codeword_valid),
        .o_SYNC_PULSE(rx_sync_pulse),
        .o_SYNC_CLK_CNT(rx_sync_clk_cnt),
        .o_PREAMBLE_ERR(rx_preamble_err)
    );

    slave_hamming_dec u_slave_hamming_dec (
        .i_CODEWORD(rx_codeword),
        .o_DATA(decoded_broadcast_data),
        .o_HAM_1BIT_ERR(hamming_1bit_err),
        .o_HAM_2BIT_ERR(hamming_2bit_err)
    );

    slave_control u_slave_control (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_NODE_ID(NODE_ID),
        .i_BROADCAST_DATA(decoded_broadcast_data),
        .i_BROADCAST_VALID(rx_codeword_valid),
        .i_BROADCAST_2BIT_ERR(hamming_2bit_err),
        .i_PAYLOAD_IN(payload_in),
        .o_TX_ENABLE(control_tx_enable),
        .o_LATCHED_GUARD_TICKS(control_latched_guard_ticks),
        .o_PAYLOAD(control_payload),
        .o_HALTED(control_halted)
    );

    slave_slot_timer u_slave_slot_timer (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_NODE_ID(NODE_ID),
        .i_NODE_CNT(NODE_CNT),
        .i_BIT_DIV(BIT_DIV),
        .i_GUARD_TICKS(GUARD_TICKS_DEFAULT),
        .i_SYNC_PULSE(rx_sync_pulse),
        .i_SYNC_CLK_CNT(rx_sync_clk_cnt),
        .o_SYNCED(timer_synced),
        .o_SLOT(timer_slot),
        .o_CLK_CNT(timer_clk_cnt),
        .o_TX_TRIGGER(timer_tx_trigger)
    );

    slave_tx u_slave_tx (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_BIT_DIV(BIT_DIV),
        .i_NODE_ID(NODE_ID),
        .i_PAYLOAD(control_payload),
        .i_TX_TRIGGER(timer_tx_trigger),
        .i_TX_ENABLE(control_tx_enable),
        .o_SERIAL_OUT(tx_serial_out),
        .o_TX_ACTIVE(tx_active),
        .o_TX_DONE(tx_done)
    );

    assign o_SLAVE_SERIAL = tx_serial_out;
    assign o_SYNCED = timer_synced;
    assign o_HALTED = control_halted;
    assign o_LATCHED_GUARD_TICKS = control_latched_guard_ticks;

endmodule
