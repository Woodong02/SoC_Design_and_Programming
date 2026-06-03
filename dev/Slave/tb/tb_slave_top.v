`timescale 1ns / 1ps

module tb_slave_top;

    reg         i_CLK;
    reg         i_RESETN;
    reg         i_MASTER_SERIAL;
    reg  [31:0] i_PAYLOAD;
    wire        o_SLAVE_SERIAL;
    wire        o_SYNCED;
    wire        o_HALTED;
    wire [9:0]  o_LATCHED_GUARD_TICKS;

    parameter [2:0] TB_NODE_ID = 3'd1;
    parameter [2:0] TB_NODE_CNT = 3'd2;
    parameter [9:0] TB_BIT_DIV = 10'd4;
    parameter [9:0] TB_GUARD_TICKS = 10'd16;

    integer fail_count;
    integer bit_index;
    integer wait_count;

    reg [49:0] captured_frame;
    reg [41:0] captured_codeword;
    wire [34:0] captured_data;
    wire        captured_1bit_err;
    wire        captured_2bit_err;

    slave_top #(
        .NODE_ID(TB_NODE_ID),
        .NODE_CNT(TB_NODE_CNT),
        .BIT_DIV(TB_BIT_DIV),
        .GUARD_TICKS_DEFAULT(TB_GUARD_TICKS)
    ) dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_MASTER_SERIAL(i_MASTER_SERIAL),
        .i_PAYLOAD(i_PAYLOAD),
        .o_SLAVE_SERIAL(o_SLAVE_SERIAL),
        .o_SYNCED(o_SYNCED),
        .o_HALTED(o_HALTED),
        .o_LATCHED_GUARD_TICKS(o_LATCHED_GUARD_TICKS)
    );

    slave_hamming_dec u_capture_dec (
        .i_CODEWORD(captured_codeword),
        .o_DATA(captured_data),
        .o_HAM_1BIT_ERR(captured_1bit_err),
        .o_HAM_2BIT_ERR(captured_2bit_err)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

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

    task drive_bit;
        input bit_value;
        integer hold_count;
        begin
            i_MASTER_SERIAL = bit_value;
            for (hold_count = 0; hold_count < TB_BIT_DIV; hold_count = hold_count + 1) begin
                @(posedge i_CLK);
            end
        end
    endtask

    task send_master_frame;
        input [7:0] halt_cmd;
        input [9:0] guard_ticks;
        input corrupt_preamble;
        reg [34:0] master_data;
        reg [41:0] codeword;
        reg [49:0] frame;
        begin
            master_data = {halt_cmd, guard_ticks, 17'd0};
            codeword = reference_codeword(master_data);
            frame = {8'hAA, codeword};
            if (corrupt_preamble)
                frame[49:42] = 8'hA8;

            $display("[PHASE] send master frame halt=0x%02x guard=%0d corrupt=%0d time=%0t",
                     halt_cmd, guard_ticks, corrupt_preamble, $time);

            for (bit_index = 49; bit_index >= 0; bit_index = bit_index - 1) begin
                drive_bit(frame[bit_index]);
            end
            i_MASTER_SERIAL = 1'b0;
            repeat (4) @(posedge i_CLK);
        end
    endtask

    task wait_for_guard;
        input [9:0] expected_guard;
        begin
            wait_count = 0;
            while ((o_LATCHED_GUARD_TICKS !== expected_guard) && (wait_count < 1200)) begin
                wait_count = wait_count + 1;
                @(posedge i_CLK);
            end
            expect_value("latched guard", {22'd0, o_LATCHED_GUARD_TICKS}, {22'd0, expected_guard});
        end
    endtask

    task capture_slave_frame;
        input [31:0] expected_payload;
        begin
            captured_frame = 50'd0;
            wait_count = 0;
            while ((o_SLAVE_SERIAL !== 1'b1) && (wait_count < 2000)) begin
                wait_count = wait_count + 1;
                @(posedge i_CLK);
            end

            if (wait_count >= 2000) begin
                $display("[FAIL] timeout waiting for slave response time=%0t", $time);
                fail_count = fail_count + 1;
            end else begin
                $display("[WAVE] slave response first high observed time=%0t", $time);
                for (bit_index = 49; bit_index >= 0; bit_index = bit_index - 1) begin
                    captured_frame[bit_index] = o_SLAVE_SERIAL;
                    repeat (TB_BIT_DIV) @(posedge i_CLK);
                end

                captured_codeword = captured_frame[41:0];
                #1;
                expect_value("response preamble", {24'd0, captured_frame[49:42]}, 32'h000000aa);
                expect_value("response node id", {29'd0, captured_data[34:32]}, {29'd0, TB_NODE_ID});
                expect_value("response payload", captured_data[31:0], expected_payload);
                expect_bit("response no 2bit hamming", captured_2bit_err, 1'b0);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        i_RESETN = 1'b0;
        i_MASTER_SERIAL = 1'b0;
        i_PAYLOAD = 32'h1234abcd;

        $display("[INFO] tb_slave_top start");
        repeat (6) @(posedge i_CLK);
        i_RESETN = 1'b1;
        repeat (4) @(posedge i_CLK);

        expect_bit("reset released unsynced", o_SYNCED, 1'b0);
        expect_bit("reset released not halted", o_HALTED, 1'b0);

        send_master_frame(8'h00, 10'd77, 1'b0);
        wait_for_guard(10'd77);
        expect_bit("valid broadcast synced", o_SYNCED, 1'b1);
        expect_bit("valid broadcast active", o_HALTED, 1'b0);
        capture_slave_frame(32'h1234abcd);

        send_master_frame(8'h02, 10'd88, 1'b0);
        wait_for_guard(10'd88);
        expect_bit("halt broadcast halted", o_HALTED, 1'b1);

        wait_count = 0;
        while ((o_SLAVE_SERIAL !== 1'b1) && (wait_count < 900)) begin
            wait_count = wait_count + 1;
            @(posedge i_CLK);
        end
        if (wait_count < 900) begin
            $display("[FAIL] halted slave unexpectedly transmitted time=%0t", $time);
            fail_count = fail_count + 1;
        end else begin
            $display("[PASS] halted slave stayed silent");
        end

        i_PAYLOAD = 32'hcafef00d;
        send_master_frame(8'h00, 10'd99, 1'b0);
        wait_for_guard(10'd99);
        expect_bit("halt clear active", o_HALTED, 1'b0);
        capture_slave_frame(32'hcafef00d);

        send_master_frame(8'h02, 10'd111, 1'b1);
        repeat (260) @(posedge i_CLK);
        expect_bit("wrong preamble keeps active state", o_HALTED, 1'b0);
        expect_value("wrong preamble guard unchanged", {22'd0, o_LATCHED_GUARD_TICKS}, 32'd99);

        if (fail_count == 0)
            $display("PASS: tb_slave_top");
        else
            $display("FAIL: tb_slave_top fail_count=%0d", fail_count);

        $finish;
    end

endmodule
