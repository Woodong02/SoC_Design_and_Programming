`timescale 1ns / 1ps

module slave2_top (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_MASTER_SERIAL,
    input  wire [31:0] i_PAYLOAD,
    output wire        o_SLAVE_SERIAL,
    output wire        o_SYNCED,
    output wire        o_HALTED,
    output wire        o_RATE_LOCKED,
    output wire        o_RATE_ERR,
    output wire [9:0]  o_LATCHED_GUARD_TICKS
);

    parameter [2:0] NODE_ID = 3'd0;
    parameter [2:0] NODE_CNT = 3'd4;
    parameter [9:0] BIT_DIV_DEFAULT = 10'd1023;
    parameter [9:0] GUARD_TICKS_DEFAULT = 10'd256;

    wire        clk;
    wire        resetn;
    wire        master_serial;
    wire [31:0] payload_in;

    wire        synced_master_serial;

    wire [41:0] rx_codeword;
    wire        rx_codeword_valid;
    wire        rx_sync_pulse;
    wire        rx_active;
    wire        rx_preamble_err;

    wire [34:0] decoded_broadcast_data;
    wire        hamming_1bit_err;
    wire        hamming_2bit_err;

    wire        timebase_locked;
    wire [15:0] timebase_bit_period_est;
    wire [2:0]  timebase_slot;
    wire [15:0] timebase_slot_clk_cnt;
    wire        timebase_sample_tick;
    wire        timebase_sample_early_tick;
    wire        timebase_sample_late_tick;
    wire        timebase_tx_bit_tick;
    wire        timebase_tx_trigger;
    wire        timebase_rate_err;

    wire        control_tx_enable;
    wire [9:0]  control_latched_guard_ticks;
    wire [31:0] control_payload;
    wire        control_halted;

    wire        tx_serial_out;
    wire        tx_active;
    wire        tx_done;

    wire        output_slave_serial;
    wire        output_synced;
    wire        output_halted;
    wire        output_rate_locked;
    wire        output_rate_err;
    wire [9:0]  output_latched_guard_ticks;

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign master_serial = i_MASTER_SERIAL;
    assign payload_in = i_PAYLOAD;

    slave2_line_sync u_slave2_line_sync (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_SERIAL_ASYNC(master_serial),
        .o_SERIAL_SYNC(synced_master_serial)
    );

    slave2_rx u_slave2_rx (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_SERIAL_IN(synced_master_serial),
        .i_SAMPLE_TICK(timebase_sample_tick),
        .i_SAMPLE_EARLY_TICK(timebase_sample_early_tick),
        .i_SAMPLE_LATE_TICK(timebase_sample_late_tick),
        .o_CODEWORD(rx_codeword),
        .o_CODEWORD_VALID(rx_codeword_valid),
        .o_SYNC_PULSE(rx_sync_pulse),
        .o_RX_ACTIVE(rx_active),
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

    slave2_timebase u_slave2_timebase (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_NODE_ID(NODE_ID),
        .i_NODE_CNT(NODE_CNT),
        .i_BIT_DIV_DEFAULT(BIT_DIV_DEFAULT),
        .i_GUARD_TICKS(GUARD_TICKS_DEFAULT),
        .i_SYNC_PULSE(rx_sync_pulse),
        .i_RX_ACTIVE(rx_active),
        .i_TX_ACTIVE(tx_active),
        .o_LOCKED(timebase_locked),
        .o_BIT_PERIOD_EST(timebase_bit_period_est),
        .o_SLOT(timebase_slot),
        .o_SLOT_CLK_CNT(timebase_slot_clk_cnt),
        .o_SAMPLE_TICK(timebase_sample_tick),
        .o_SAMPLE_EARLY_TICK(timebase_sample_early_tick),
        .o_SAMPLE_LATE_TICK(timebase_sample_late_tick),
        .o_TX_BIT_TICK(timebase_tx_bit_tick),
        .o_TX_TRIGGER(timebase_tx_trigger),
        .o_RATE_ERR(timebase_rate_err)
    );

    slave2_tx u_slave2_tx (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_NODE_ID(NODE_ID),
        .i_PAYLOAD(control_payload),
        .i_TX_TRIGGER(timebase_tx_trigger),
        .i_TX_BIT_TICK(timebase_tx_bit_tick),
        .i_TX_ENABLE(control_tx_enable),
        .o_SERIAL_OUT(tx_serial_out),
        .o_TX_ACTIVE(tx_active),
        .o_TX_DONE(tx_done)
    );

    assign output_slave_serial = tx_serial_out;
    assign output_synced = rx_sync_pulse;
    assign output_halted = control_halted;
    assign output_rate_locked = timebase_locked;
    assign output_rate_err = timebase_rate_err;
    assign output_latched_guard_ticks = control_latched_guard_ticks;

    assign o_SLAVE_SERIAL = output_slave_serial;
    assign o_SYNCED = output_synced;
    assign o_HALTED = output_halted;
    assign o_RATE_LOCKED = output_rate_locked;
    assign o_RATE_ERR = output_rate_err;
    assign o_LATCHED_GUARD_TICKS = output_latched_guard_ticks;

endmodule
