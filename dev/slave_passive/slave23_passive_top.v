`timescale 1ns / 1ps

module slave23_passive_top #(
    parameter [2:0]  NODE_ID = 3'd0,
    parameter [3:0]  DIV = 4'd10,       // 비트 주기 = 2^DIV 클럭. 10 → 1024클럭/비트
    parameter [9:0]  GUARD_TICKS = 10'd256
) (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire        i_MASTER_SERIAL,
    input  wire [31:0] i_PAYLOAD,
    output wire        o_SLAVE_SERIAL,
    output wire        o_HALTED,
    output wire        o_TX_ACTIVE,
    output wire        o_SYNCED
);

    localparam [1:0]  P23_WAIT_START   = 2'd0;
    localparam [1:0]  P23_WAIT_TX     = 2'd1;
    localparam [1:0]  P23_TX          = 2'd2;
    localparam integer BIT_PERIOD_INT  = 1 << DIV;
    localparam [15:0]  BIT_PERIOD_CALC = BIT_PERIOD_INT[15:0];

    wire        clk;
    wire        resetn;
    wire        master_serial;
    wire [31:0] payload;

    wire [41:0] rx_codeword;
    wire        rx_codeword_valid;
    wire        rx_frame_done_unused;
    wire        rx_preamble_ok_unused;
    wire        rx_preamble_err_unused;
    wire        rx_active_unused;
    wire [34:0] decoded_broadcast_data;
    wire        ham_1bit_err_unused;
    wire        ham_2bit_err;
    wire        broadcast_valid;
    wire [7:0]  halt_cmd;
    wire        halted_now;

    wire [15:0] bit_period_sanitized;
    wire [31:0] frame_ticks;
    wire [31:0] slot_ticks;
    wire [31:0] node_slot_offset;
    wire [31:0] tx_start_ticks;
    wire        tx_start_match;
    wire        tx_trigger;
    wire        slave_serial;
    wire        tx_active;
    wire        tx_done;
    wire        synced;
    wire        top_master_rise;

    reg  [1:0]  state_ff;
    reg  [1:0]  state_next;
    reg         serial_prev_ff;
    reg         serial_prev_next;
    reg  [31:0] sync_timer_ff;
    reg  [31:0] sync_timer_next;
    reg         halted_ff;
    reg         halted_next;

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign master_serial = i_MASTER_SERIAL;
    assign payload = i_PAYLOAD;

    slave21_rx u_broadcast_rx (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_SERIAL_IN(master_serial),
        .i_BIT_PERIOD(bit_period_sanitized),
        .o_CODEWORD(rx_codeword),
        .o_CODEWORD_VALID(rx_codeword_valid),
        .o_FRAME_DONE(rx_frame_done_unused),
        .o_PREAMBLE_OK(rx_preamble_ok_unused),
        .o_PREAMBLE_ERR(rx_preamble_err_unused),
        .o_RX_ACTIVE(rx_active_unused)
    );

    slave_hamming_dec u_broadcast_hamming_dec (
        .i_CODEWORD(rx_codeword),
        .o_DATA(decoded_broadcast_data),
        .o_HAM_1BIT_ERR(ham_1bit_err_unused),
        .o_HAM_2BIT_ERR(ham_2bit_err)
    );

    assign bit_period_sanitized = BIT_PERIOD_CALC;
    assign frame_ticks = {16'd0, bit_period_sanitized} * 32'd50;
    assign slot_ticks = frame_ticks + {22'd0, GUARD_TICKS};
    assign node_slot_offset = {29'd0, NODE_ID} * slot_ticks;
    assign tx_start_ticks = frame_ticks + node_slot_offset;
    assign broadcast_valid = rx_codeword_valid & ~ham_2bit_err;
    assign halt_cmd = decoded_broadcast_data[34:27];
    assign halted_now = halt_cmd[NODE_ID];
    assign tx_start_match = (state_ff == P23_WAIT_TX) & (sync_timer_ff == tx_start_ticks);
    assign tx_trigger = tx_start_match & ~halted_ff;
    assign synced = (state_ff != P23_WAIT_START);
    assign top_master_rise = (state_ff == P23_WAIT_START) &
                             (serial_prev_ff == 1'b0) &
                             (master_serial == 1'b1) &
                             ~tx_active;

    slave21_tx u_slave21_tx (
        .i_CLK(clk),
        .i_RESETN(resetn),
        .i_NODE_ID(NODE_ID),
        .i_PAYLOAD(payload),
        .i_BIT_PERIOD(bit_period_sanitized),
        .i_TX_TRIGGER(tx_trigger),
        .i_TX_ENABLE(~halted_ff),
        .o_SERIAL_OUT(slave_serial),
        .o_TX_ACTIVE(tx_active),
        .o_TX_DONE(tx_done)
    );

    always @(*) begin
        state_next = state_ff;

        case (state_ff)
            P23_WAIT_START: begin
                if (top_master_rise == 1'b1) begin
                    state_next = P23_WAIT_TX;
                end
            end

            P23_WAIT_TX: begin
                if (tx_start_match == 1'b1) begin
                    if (halted_ff == 1'b1) begin
                        state_next = P23_WAIT_START;
                    end else begin
                        state_next = P23_TX;
                    end
                end
            end

            P23_TX: begin
                if (tx_done == 1'b1) begin
                    state_next = P23_WAIT_START;
                end
            end

            default: begin
                state_next = P23_WAIT_START;
            end
        endcase
    end

    always @(*) begin
        serial_prev_next = master_serial;
    end

    always @(*) begin
        sync_timer_next = sync_timer_ff;

        if (top_master_rise == 1'b1) begin
            // top이 직접 첫 1을 보자마자 timer를 시작한다.
            // 현재 posedge를 1tick째로 세어 tx_start 식과 cycle 관측을 맞춘다.
            sync_timer_next = 32'd1;
        end else if (state_ff == P23_WAIT_TX) begin
            sync_timer_next = sync_timer_ff + 32'd1;
        end else begin
            sync_timer_next = 32'd0;
        end
    end

    always @(*) begin
        halted_next = halted_ff;

        if (broadcast_valid == 1'b1) begin
            // halt bit는 broadcast가 정상 decode된 경우에만 갱신한다.
            halted_next = halted_now;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            state_ff <= P23_WAIT_START;
        end else begin
            state_ff <= state_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            serial_prev_ff <= 1'b0;
        end else begin
            serial_prev_ff <= serial_prev_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            sync_timer_ff <= 32'd0;
        end else begin
            sync_timer_ff <= sync_timer_next;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            halted_ff <= 1'b0;
        end else begin
            halted_ff <= halted_next;
        end
    end

    assign o_SLAVE_SERIAL = slave_serial;
    assign o_HALTED = halted_ff;
    assign o_TX_ACTIVE = tx_active;
    assign o_SYNCED = synced;

endmodule
