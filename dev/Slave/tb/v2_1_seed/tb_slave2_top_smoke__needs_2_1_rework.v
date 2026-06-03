`timescale 1ns / 1ps

module tb_slave2_top_smoke;

    reg         i_CLK;
    reg         i_RESETN;
    reg         i_MASTER_SERIAL;
    reg  [31:0] i_PAYLOAD;
    wire        o_SLAVE_SERIAL;
    wire        o_SYNCED;
    wire        o_HALTED;
    wire        o_RATE_LOCKED;
    wire        o_RATE_ERR;
    wire [9:0]  o_LATCHED_GUARD_TICKS;

    parameter [2:0] TB_NODE_ID = 3'd1;
    parameter [2:0] TB_NODE_CNT = 3'd3;
    parameter [9:0] TB_BIT_DIV_DEFAULT = 10'd8;
    parameter [9:0] TB_GUARD_TICKS_DEFAULT = 10'd19;

    integer fail_count;

    slave2_top #(
        .NODE_ID(TB_NODE_ID),
        .NODE_CNT(TB_NODE_CNT),
        .BIT_DIV_DEFAULT(TB_BIT_DIV_DEFAULT),
        .GUARD_TICKS_DEFAULT(TB_GUARD_TICKS_DEFAULT)
    ) dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_MASTER_SERIAL(i_MASTER_SERIAL),
        .i_PAYLOAD(i_PAYLOAD),
        .o_SLAVE_SERIAL(o_SLAVE_SERIAL),
        .o_SYNCED(o_SYNCED),
        .o_HALTED(o_HALTED),
        .o_RATE_LOCKED(o_RATE_LOCKED),
        .o_RATE_ERR(o_RATE_ERR),
        .o_LATCHED_GUARD_TICKS(o_LATCHED_GUARD_TICKS)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

    task expect_bit;
        input [511:0] name;
        input got;
        input exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %0s got=%0b exp=%0b time=%0t", name, got, exp, $time);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s got=%0b time=%0t", name, got, $time);
            end
        end
    endtask

    task expect_value;
        input [511:0] name;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %0s got=0x%08x exp=0x%08x time=%0t", name, got, exp, $time);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s got=0x%08x time=%0t", name, got, $time);
            end
        end
    endtask

    function [41:0] reference_codeword;
        input [34:0] data;
        reg p0;
        reg p1;
        reg p2;
        reg p3;
        reg p4;
        reg p5;
        reg p_overall;
        begin
            p0 = data[0] ^ data[2] ^ data[4] ^ data[6] ^ data[8] ^ data[10] ^ data[12] ^ data[14]
               ^ data[16] ^ data[18] ^ data[20] ^ data[22] ^ data[24] ^ data[26] ^ data[28] ^ data[30]
               ^ data[32] ^ data[34];
            p1 = data[1] ^ data[2] ^ data[5] ^ data[6] ^ data[9] ^ data[10] ^ data[13] ^ data[14]
               ^ data[17] ^ data[18] ^ data[21] ^ data[22] ^ data[25] ^ data[26] ^ data[29] ^ data[30]
               ^ data[33] ^ data[34];
            p2 = data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[11] ^ data[12] ^ data[13] ^ data[14]
               ^ data[19] ^ data[20] ^ data[21] ^ data[22] ^ data[27] ^ data[28] ^ data[29] ^ data[30];
            p3 = data[7] ^ data[8] ^ data[9] ^ data[10] ^ data[11] ^ data[12] ^ data[13] ^ data[14]
               ^ data[23] ^ data[24] ^ data[25] ^ data[26] ^ data[27] ^ data[28] ^ data[29] ^ data[30];
            p4 = data[15] ^ data[16] ^ data[17] ^ data[18] ^ data[19] ^ data[20] ^ data[21] ^ data[22]
               ^ data[23] ^ data[24] ^ data[25] ^ data[26] ^ data[27] ^ data[28] ^ data[29] ^ data[30];
            p5 = data[31] ^ data[32] ^ data[33] ^ data[34];
            p_overall = ^{data, p5, p4, p3, p2, p1, p0};
            reference_codeword = {data, p5, p4, p3, p2, p1, p0, p_overall};
        end
    endfunction

    initial begin
        fail_count = 0;
        i_RESETN = 1'b0;
        i_MASTER_SERIAL = 1'b0;
        i_PAYLOAD = 32'h13572468;

        $display("[INFO] tb_slave2_top_smoke start");
        repeat (4) @(posedge i_CLK);
        i_RESETN = 1'b1;
        repeat (3) @(posedge i_CLK);

        expect_bit("reset released no rx sync pulse", o_SYNCED, 1'b0);
        expect_bit("timebase starts unlocked", o_RATE_LOCKED, 1'b0);
        expect_bit("timebase no initial rate error", o_RATE_ERR, 1'b0);
        expect_bit("initial not halted", o_HALTED, 1'b0);

        force dut.rx_codeword =
            reference_codeword({8'h00, TB_GUARD_TICKS_DEFAULT, 17'd0});
        force dut.rx_codeword_valid = 1'b1;
        force dut.rx_sync_pulse = 1'b1;
        @(posedge i_CLK);
        #1;
        expect_bit("o_SYNCED follows rx sync pulse", o_SYNCED, 1'b1);
        expect_value("default guard latched by control", {22'd0, o_LATCHED_GUARD_TICKS},
                     {22'd0, TB_GUARD_TICKS_DEFAULT});

        force dut.rx_codeword =
            reference_codeword({8'h02, 10'd23, 17'd0});
        @(posedge i_CLK);
        #1;
        expect_bit("selected halt command halts node", o_HALTED, 1'b1);
        expect_value("halt frame guard latched", {22'd0, o_LATCHED_GUARD_TICKS}, 32'd23);

        force dut.rx_codeword =
            reference_codeword({8'h00, 10'd31, 17'd0});
        @(posedge i_CLK);
        #1;
        expect_bit("clear halt command re-enables node", o_HALTED, 1'b0);
        expect_value("clear frame guard latched", {22'd0, o_LATCHED_GUARD_TICKS}, 32'd31);

        release dut.rx_codeword;
        release dut.rx_codeword_valid;
        release dut.rx_sync_pulse;
        @(posedge i_CLK);
        #1;
        expect_bit("o_SYNCED drops with rx sync pulse", o_SYNCED, 1'b0);

        if (fail_count == 0)
            $display("PASS: tb_slave2_top_smoke");
        else
            $display("FAIL: tb_slave2_top_smoke fail_count=%0d", fail_count);

        $finish;
    end

endmodule
