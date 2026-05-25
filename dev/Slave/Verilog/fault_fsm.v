// fault_fsm: TDMA slave fault state machine
// States: IDLE(0) NORMAL(1) DATA_RECOVERY(2) FAULT(3) DEAD(4)
// FAULT_CNT: +10 on bc_hamming_err/halt_cmd (sat at fault_th), -1 on bc_valid (floor 0)
// LINE_CNT:  +10 on no_broadcast/bc_preamble_err (sat at line_fault_th), -1 on bc_preamble_ok
module fault_fsm (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] fault_th,
    input  wire [7:0] line_fault_th,

    input  wire       active_edge,
    input  wire       bc_valid,
    input  wire       bc_preamble_ok,
    input  wire       bc_hamming_err,
    input  wire       bc_preamble_err,
    input  wire       no_broadcast,
    input  wire       halt_cmd,

    output reg        tx_enable,
    output reg        state_change,
    output reg [2:0]  fsm_state,
    output wire [7:0] fault_cnt_out,
    output wire [7:0] line_cnt_out
);
    localparam IDLE          = 3'd0;
    localparam NORMAL        = 3'd1;
    localparam DATA_RECOVERY = 3'd2;
    localparam FAULT_ST      = 3'd3;
    localparam DEAD          = 3'd4;

    reg [7:0] fault_cnt;
    reg [7:0] line_cnt;
    assign fault_cnt_out = fault_cnt;
    assign line_cnt_out  = line_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_state    <= IDLE;
            fault_cnt    <= 8'd0;
            line_cnt     <= 8'd0;
            tx_enable    <= 1'b0;
            state_change <= 1'b0;
        end else begin
            state_change <= 1'b0;

            // ---- counter updates (read old values, write new) ----
            // FAULT_CNT: halt_cmd saturates to fault_th ("ignore counter" = 즉시 FAULT)
            if (halt_cmd) begin
                fault_cnt <= fault_th;
            end else if (bc_hamming_err) begin
                fault_cnt <= ({1'b0, fault_cnt} + 9'd10 >= {1'b0, fault_th})
                             ? fault_th : fault_cnt + 8'd10;
            end else if (bc_valid && fault_cnt > 8'd0) begin
                fault_cnt <= fault_cnt - 8'd1;
            end

            // LINE_CNT
            if (no_broadcast || bc_preamble_err) begin
                line_cnt <= ({1'b0, line_cnt} + 9'd10 >= {1'b0, line_fault_th})
                            ? line_fault_th : line_cnt + 8'd10;
            end else if (bc_preamble_ok && line_cnt > 8'd0) begin
                line_cnt <= line_cnt - 8'd1;
            end

            // ---- state machine (reads old counter values) ----
            case (fsm_state)
                IDLE: begin
                    if (active_edge) begin
                        fsm_state    <= NORMAL;
                        state_change <= 1'b1;
                    end
                end

                NORMAL: begin
                    if (line_cnt >= line_fault_th) begin
                        fsm_state    <= DEAD;
                        state_change <= 1'b1;
                    end else if (halt_cmd || fault_cnt >= fault_th) begin
                        fsm_state    <= FAULT_ST;
                        state_change <= 1'b1;
                    end else if (fault_cnt > 8'd0) begin
                        fsm_state    <= DATA_RECOVERY;
                        state_change <= 1'b1;
                    end
                end

                DATA_RECOVERY: begin
                    if (line_cnt >= line_fault_th) begin
                        fsm_state    <= DEAD;
                        state_change <= 1'b1;
                    end else if (halt_cmd || fault_cnt >= fault_th) begin
                        fsm_state    <= FAULT_ST;
                        state_change <= 1'b1;
                    end else if (fault_cnt == 8'd0) begin
                        fsm_state    <= NORMAL;
                        state_change <= 1'b1;
                    end
                end

                FAULT_ST: begin
                    if (line_cnt >= line_fault_th) begin
                        fsm_state    <= DEAD;
                        state_change <= 1'b1;
                    end else if (fault_cnt < fault_th) begin
                        fsm_state    <= DATA_RECOVERY;
                        state_change <= 1'b1;
                    end
                end

                DEAD: begin
                    if (line_cnt == 8'd0) begin
                        fsm_state    <= IDLE;
                        state_change <= 1'b1;
                    end
                end

                default: fsm_state <= IDLE;
            endcase

            // tx_enable: 1 in NORMAL/DATA_RECOVERY, 0 otherwise
            // (updates same clock as state, effective next clock)
            tx_enable <= (fsm_state == NORMAL || fsm_state == DATA_RECOVERY);
        end
    end

endmodule
