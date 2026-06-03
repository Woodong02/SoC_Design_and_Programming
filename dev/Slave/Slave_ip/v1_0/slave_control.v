`timescale 1ns / 1ps

module slave_control (
    input  wire        i_CLK,
    input  wire        i_RESETN,
    input  wire [2:0]  i_NODE_ID,
    input  wire [34:0] i_BROADCAST_DATA,
    input  wire        i_BROADCAST_VALID,
    input  wire        i_BROADCAST_2BIT_ERR,
    input  wire [31:0] i_PAYLOAD_IN,
    output wire        o_TX_ENABLE,
    output wire [9:0]  o_LATCHED_GUARD_TICKS,
    output wire [31:0] o_PAYLOAD,
    output wire        o_HALTED
);

    localparam [1:0] CTRL_WAIT_SYNC = 2'd0;
    localparam [1:0] CTRL_ACTIVE    = 2'd1;
    localparam [1:0] CTRL_HALT      = 2'd2;

    wire        clk;
    wire        resetn;
    wire [2:0]  node_id;
    wire [34:0] broadcast_data;
    wire        broadcast_valid;
    wire        broadcast_2bit_err;
    wire [31:0] payload_in;

    wire [7:0]  halt_cmd;
    wire [9:0]  guard_ticks;
    wire        clean_broadcast_valid;
    wire        selected_halt_cmd;
    wire        tx_enable;
    wire        halted;
    wire [31:0] payload;

    reg [1:0] state_ff;
    reg [1:0] state_next;
    reg [9:0] latched_guard_ticks_ff;

    assign clk = i_CLK;
    assign resetn = i_RESETN;
    assign node_id = i_NODE_ID;
    assign broadcast_data = i_BROADCAST_DATA;
    assign broadcast_valid = i_BROADCAST_VALID;
    assign broadcast_2bit_err = i_BROADCAST_2BIT_ERR;
    assign payload_in = i_PAYLOAD_IN;

    assign halt_cmd = broadcast_data[34:27];
    assign guard_ticks = broadcast_data[26:17];
    assign clean_broadcast_valid = broadcast_valid & ~broadcast_2bit_err;
    assign selected_halt_cmd = halt_cmd[node_id];
    assign tx_enable = (state_ff == CTRL_ACTIVE);
    assign halted = (state_ff == CTRL_HALT);
    assign payload = payload_in;

    always @(*) begin
        state_next = state_ff;

        case (state_ff)
            CTRL_WAIT_SYNC: begin
                if (clean_broadcast_valid == 1'b1) begin
                    if (selected_halt_cmd == 1'b1) begin
                        state_next = CTRL_HALT;
                    end else begin
                        state_next = CTRL_ACTIVE;
                    end
                end
            end

            CTRL_ACTIVE: begin
                if (clean_broadcast_valid == 1'b1) begin
                    if (selected_halt_cmd == 1'b1) begin
                        state_next = CTRL_HALT;
                    end else begin
                        state_next = CTRL_ACTIVE;
                    end
                end
            end

            CTRL_HALT: begin
                if (clean_broadcast_valid == 1'b1) begin
                    if (selected_halt_cmd == 1'b1) begin
                        state_next = CTRL_HALT;
                    end else begin
                        state_next = CTRL_ACTIVE;
                    end
                end
            end

            default: begin
                state_next = CTRL_WAIT_SYNC;
            end
        endcase
    end

    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            state_ff <= CTRL_WAIT_SYNC;
        end else begin
            state_ff <= state_next;
        end
    end

    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            latched_guard_ticks_ff <= 10'd0;
        end else if (clean_broadcast_valid == 1'b1) begin
            latched_guard_ticks_ff <= guard_ticks;
        end
    end

    assign o_TX_ENABLE = tx_enable;
    assign o_LATCHED_GUARD_TICKS = latched_guard_ticks_ff;
    assign o_PAYLOAD = payload;
    assign o_HALTED = halted;

endmodule
