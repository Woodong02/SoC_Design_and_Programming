`timescale 1ns / 1ps

module slave21_fault_fsm (
    input  wire       i_CLK,
    input  wire       i_RESETN,
    input  wire       i_FRAME_DONE,
    input  wire       i_GOOD_BROADCAST,
    input  wire       i_HALT_FOR_ME,
    input  wire       i_RATE_ERR,
    output wire       o_TX_ALLOWED,
    output wire       o_GOOD_BROADCAST_COMMIT,
    output wire [2:0] o_FAULT_STATE
);

    localparam [2:0] FLT21_RESET     = 3'd0;
    localparam [2:0] FLT21_ACQUIRE   = 3'd1;
    localparam [2:0] FLT21_SEEN_ONCE = 3'd2;
    localparam [2:0] FLT21_TRACKING  = 3'd3;
    localparam [2:0] FLT21_RECOVERY  = 3'd4;

    wire       clk;
    wire       resetn;
    wire       frame_done;
    wire       good_broadcast;
    wire       halt_for_me;
    wire       rate_err;

    wire       bad_frame_done;
    wire       good_frame_done;
    wire       tx_allowed;
    wire       good_broadcast_commit;
    wire [2:0] fault_state;

    reg [2:0] state_ff;
    reg [2:0] state_next;

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign frame_done = i_FRAME_DONE;
    assign good_broadcast = i_GOOD_BROADCAST;
    assign halt_for_me = i_HALT_FOR_ME;
    assign rate_err = i_RATE_ERR;

    assign good_frame_done = frame_done & good_broadcast;
    assign bad_frame_done = frame_done & ~good_broadcast;
    assign tx_allowed = (state_ff == FLT21_TRACKING) & ~halt_for_me;
    assign good_broadcast_commit = good_frame_done;
    assign fault_state = state_ff;

    always @(*) begin
        state_next = state_ff;

        case (state_ff)
            FLT21_RESET: begin
                state_next = FLT21_ACQUIRE;
            end

            FLT21_ACQUIRE: begin
                if (good_frame_done == 1'b1) begin
                    state_next = FLT21_SEEN_ONCE;
                end else begin
                    state_next = FLT21_ACQUIRE;
                end
            end

            FLT21_SEEN_ONCE: begin
                if (good_frame_done == 1'b1) begin
                    state_next = FLT21_TRACKING;
                end else if (bad_frame_done == 1'b1) begin
                    state_next = FLT21_ACQUIRE;
                end else begin
                    state_next = FLT21_SEEN_ONCE;
                end
            end

            FLT21_TRACKING: begin
                if (rate_err == 1'b1) begin
                    state_next = FLT21_RECOVERY;
                end else if (bad_frame_done == 1'b1) begin
                    state_next = FLT21_RECOVERY;
                end else begin
                    state_next = FLT21_TRACKING;
                end
            end

            FLT21_RECOVERY: begin
                if (good_frame_done == 1'b1) begin
                    state_next = FLT21_SEEN_ONCE;
                end else begin
                    state_next = FLT21_RECOVERY;
                end
            end

            default: begin
                state_next = FLT21_ACQUIRE;
            end
        endcase
    end

    always @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            state_ff <= FLT21_RESET;
        end else begin
            state_ff <= state_next;
        end
    end

    assign o_TX_ALLOWED = tx_allowed;
    assign o_GOOD_BROADCAST_COMMIT = good_broadcast_commit;
    assign o_FAULT_STATE = fault_state;

endmodule
