`timescale 1ns / 1ps

module slave21_top #(
    parameter [2:0]  NODE_ID = 3'd0,
    parameter [2:0]  NODE_CNT = 3'd4,
    parameter [15:0] BIT_PERIOD_DEFAULT = 16'd1024,
    parameter [9:0]  GUARD_TICKS_DEFAULT = 10'd256
) (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_MASTER_SERIAL,
    input  wire [31:0] i_PAYLOAD,
    output wire        o_SLAVE_SERIAL,
    output wire        o_LINK_TRACKING,
    output wire        o_HALTED,
    output wire        o_RATE_ERR,
    output wire [2:0]  o_FAULT_STATE,
    output wire [9:0]  o_LATCHED_GUARD_TICKS
);

    localparam [2:0] FLT21_TRACKING = 3'd3;

    wire        clk;
    wire        resetn;
    wire        master_serial;
    wire [31:0] payload_in;

    wire        master_serial_sync;
    wire [41:0] rx_codeword;
    wire        rx_codeword_valid;
    wire        rx_frame_done;
    wire        rx_preamble_ok;
    wire        rx_preamble_err;
    wire        rx_active;

    wire [34:0] decoded_broadcast_data;
    wire        ham_1bit_err;
    wire        ham_2bit_err;
    wire        good_broadcast;
    wire [7:0]  halt_cmd;
    wire        halt_for_me;

    wire        control_tx_enable;
    wire [9:0]  latched_guard_ticks;
    wire [31:0] control_payload;
    wire        control_halted;
    wire [9:0]  timebase_guard_ticks;

    wire        fault_tx_allowed;
    wire        good_broadcast_commit;
    wire [2:0]  fault_state;

    wire [15:0] timebase_bit_period;
    wire        timebase_period_valid;
    wire [2:0]  timebase_slot;
    wire [15:0] timebase_slot_clk_cnt;
    wire        timebase_tx_trigger;
    wire        timebase_rate_err;

    wire        final_tx_enable;
    wire        slave_serial;
    wire        tx_active;
    wire        tx_done;
    wire        link_tracking;

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign master_serial = i_MASTER_SERIAL;
    assign payload_in = i_PAYLOAD;

    slave2_line_sync u_line_sync (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_SERIAL_ASYNC(master_serial),
        .o_SERIAL_SYNC(master_serial_sync)
    );

    slave21_rx u_rx (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_SERIAL_IN(master_serial_sync),
        .i_BIT_PERIOD(timebase_bit_period),
        .o_CODEWORD(rx_codeword),
        .o_CODEWORD_VALID(rx_codeword_valid),
        .o_FRAME_DONE(rx_frame_done),
        .o_PREAMBLE_OK(rx_preamble_ok),
        .o_PREAMBLE_ERR(rx_preamble_err),
        .o_RX_ACTIVE(rx_active)
    );

    slave_hamming_dec u_hamming_dec (
        .i_CODEWORD(rx_codeword),
        .o_DATA(decoded_broadcast_data),
        .o_HAM_1BIT_ERR(ham_1bit_err),
        .o_HAM_2BIT_ERR(ham_2bit_err)
    );

    assign good_broadcast = rx_codeword_valid & ~ham_2bit_err;
    assign halt_cmd = decoded_broadcast_data[34:27];
    assign halt_for_me = halt_cmd[NODE_ID];

    slave_control u_control (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_NODE_ID(NODE_ID),
        .i_BROADCAST_DATA(decoded_broadcast_data),
        .i_BROADCAST_VALID(rx_codeword_valid),
        .i_BROADCAST_2BIT_ERR(ham_2bit_err),
        .i_PAYLOAD_IN(payload_in),
        .o_TX_ENABLE(control_tx_enable),
        .o_LATCHED_GUARD_TICKS(latched_guard_ticks),
        .o_PAYLOAD(control_payload),
        .o_HALTED(control_halted)
    );

    slave21_fault_fsm u_fault_fsm (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_FRAME_DONE(rx_frame_done),
        .i_GOOD_BROADCAST(good_broadcast),
        .i_HALT_FOR_ME(halt_for_me),
        .i_RATE_ERR(timebase_rate_err),
        .o_TX_ALLOWED(fault_tx_allowed),
        .o_GOOD_BROADCAST_COMMIT(good_broadcast_commit),
        .o_FAULT_STATE(fault_state)
    );

    assign timebase_guard_ticks = (latched_guard_ticks == 10'd0) ? GUARD_TICKS_DEFAULT : latched_guard_ticks;
    assign final_tx_enable = control_tx_enable & fault_tx_allowed;

    slave21_timebase u_timebase (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_NODE_ID(NODE_ID),
        .i_NODE_CNT(NODE_CNT),
        .i_BIT_PERIOD_DEFAULT(BIT_PERIOD_DEFAULT),
        .i_GUARD_TICKS(timebase_guard_ticks),
        .i_GOOD_BROADCAST_COMMIT(good_broadcast_commit),
        .i_TX_ACTIVE(tx_active),
        .i_TX_ALLOWED(final_tx_enable),
        .o_BIT_PERIOD(timebase_bit_period),
        .o_PERIOD_VALID(timebase_period_valid),
        .o_SLOT(timebase_slot),
        .o_SLOT_CLK_CNT(timebase_slot_clk_cnt),
        .o_TX_TRIGGER(timebase_tx_trigger),
        .o_RATE_ERR(timebase_rate_err)
    );

    slave21_tx u_tx (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_NODE_ID(NODE_ID),
        .i_PAYLOAD(control_payload),
        .i_BIT_PERIOD(timebase_bit_period),
        .i_TX_TRIGGER(timebase_tx_trigger),
        .i_TX_ENABLE(final_tx_enable),
        .o_SERIAL_OUT(slave_serial),
        .o_TX_ACTIVE(tx_active),
        .o_TX_DONE(tx_done)
    );

    assign link_tracking = (fault_state == FLT21_TRACKING);

    assign o_SLAVE_SERIAL = slave_serial;
    assign o_LINK_TRACKING = link_tracking;
    assign o_HALTED = control_halted;
    assign o_RATE_ERR = timebase_rate_err;
    assign o_FAULT_STATE = fault_state;
    assign o_LATCHED_GUARD_TICKS = latched_guard_ticks;

endmodule
