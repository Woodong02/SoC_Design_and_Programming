`timescale 1ns / 1ps

module tb_slave_rx;

    reg         i_CLK;
    reg         i_RESETN;
    reg  [9:0]  i_BIT_DIV;
    reg         i_SERIAL_IN;
    wire [41:0] o_CODEWORD;
    wire        o_CODEWORD_VALID;
    wire        o_SYNC_PULSE;
    wire [15:0] o_SYNC_CLK_CNT;
    wire        o_PREAMBLE_ERR;

    integer fail_count;
    integer sync_count;
    integer valid_count;
    integer preamble_err_count;
    integer valid_high_count;
    integer bit_index;
    integer cycle_index;

    reg [15:0] observed_sync_clk_cnt;
    reg [41:0] observed_codeword;
    reg        previous_codeword_valid;
    reg        previous_sync_pulse;
    reg        previous_preamble_err;

    slave_rx dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_BIT_DIV(i_BIT_DIV),
        .i_SERIAL_IN(i_SERIAL_IN),
        .o_CODEWORD(o_CODEWORD),
        .o_CODEWORD_VALID(o_CODEWORD_VALID),
        .o_SYNC_PULSE(o_SYNC_PULSE),
        .o_SYNC_CLK_CNT(o_SYNC_CLK_CNT),
        .o_PREAMBLE_ERR(o_PREAMBLE_ERR)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

    task expect_value;
        input [255:0] name;
        input [63:0]  got;
        input [63:0]  exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %0s got=0x%0h exp=0x%0h time=%0t", name, got, exp, $time);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s got=0x%0h time=%0t", name, got, $time);
            end
        end
    endtask

    task wait_cycles;
        input integer cycles;
        begin
            for (cycle_index = 0; cycle_index < cycles; cycle_index = cycle_index + 1) begin
                @(posedge i_CLK);
            end
        end
    endtask

    task reset_dut;
        begin
            i_RESETN = 1'b0;
            i_SERIAL_IN = 1'b0;
            wait_cycles(4);
            i_RESETN = 1'b1;
            wait_cycles(2);
        end
    endtask

    task clear_monitors;
        begin
            sync_count = 0;
            valid_count = 0;
            preamble_err_count = 0;
            valid_high_count = 0;
            observed_sync_clk_cnt = 16'd0;
            observed_codeword = 42'd0;
            previous_codeword_valid = 1'b0;
            previous_sync_pulse = 1'b0;
            previous_preamble_err = 1'b0;
            @(posedge i_CLK);
        end
    endtask

    task drive_serial_bit;
        input bit_value;
        integer local_count;
        begin
            @(negedge i_CLK);
            i_SERIAL_IN = bit_value;
            for (local_count = 0; local_count < i_BIT_DIV; local_count = local_count + 1) begin
                @(posedge i_CLK);
            end
        end
    endtask

    task drive_idle_low;
        input integer cycles;
        begin
            @(negedge i_CLK);
            i_SERIAL_IN = 1'b0;
            wait_cycles(cycles);
        end
    endtask

    task send_preamble;
        input [7:0] preamble_value;
        begin
            for (bit_index = 7; bit_index >= 0; bit_index = bit_index - 1) begin
                drive_serial_bit(preamble_value[bit_index]);
            end
        end
    endtask

    task send_codeword;
        input [41:0] codeword_value;
        begin
            for (bit_index = 41; bit_index >= 0; bit_index = bit_index - 1) begin
                drive_serial_bit(codeword_value[bit_index]);
            end
        end
    endtask

    task send_valid_frame;
        input [41:0] codeword_value;
        begin
            send_preamble(8'hAA);
            send_codeword(codeword_value);
            drive_idle_low(8);
        end
    endtask

    always @(posedge i_CLK) begin
        if (o_SYNC_PULSE) begin
            sync_count = sync_count + 1;
            observed_sync_clk_cnt = o_SYNC_CLK_CNT;
            $display("[WAVE] sync pulse sync_clk_cnt=%0d time=%0t", o_SYNC_CLK_CNT, $time);
        end

        if (o_CODEWORD_VALID) begin
            valid_count = valid_count + 1;
            valid_high_count = valid_high_count + 1;
            observed_codeword = o_CODEWORD;
            $display("[WAVE] codeword valid codeword=0x%0h time=%0t", o_CODEWORD, $time);
        end

        if (o_PREAMBLE_ERR) begin
            preamble_err_count = preamble_err_count + 1;
            $display("[WAVE] preamble error time=%0t", $time);
        end

        if (previous_codeword_valid && o_CODEWORD_VALID) begin
            $display("[FAIL] codeword_valid wider than 1 cycle time=%0t", $time);
            fail_count = fail_count + 1;
        end

        if (previous_sync_pulse && o_SYNC_PULSE) begin
            $display("[FAIL] sync_pulse wider than 1 cycle time=%0t", $time);
            fail_count = fail_count + 1;
        end

        if (previous_preamble_err && o_PREAMBLE_ERR) begin
            $display("[FAIL] preamble_err wider than 1 cycle time=%0t", $time);
            fail_count = fail_count + 1;
        end

        previous_codeword_valid = o_CODEWORD_VALID;
        previous_sync_pulse = o_SYNC_PULSE;
        previous_preamble_err = o_PREAMBLE_ERR;
    end

    initial begin
        fail_count = 0;
        i_BIT_DIV = 10'd4;
        i_SERIAL_IN = 1'b0;
        previous_codeword_valid = 1'b0;
        previous_sync_pulse = 1'b0;
        previous_preamble_err = 1'b0;

        $display("[INFO] tb_slave_rx start");
        reset_dut();

        $display("[PHASE] idle-low 유지");
        clear_monitors();
        drive_idle_low(40);
        expect_value("idle sync count", {32'd0, sync_count}, 64'd0);
        expect_value("idle valid count", {32'd0, valid_count}, 64'd0);
        expect_value("idle preamble err count", {32'd0, preamble_err_count}, 64'd0);

        $display("[PHASE] valid frame 수신 및 sync preload");
        clear_monitors();
        i_BIT_DIV = 10'd4;
        send_valid_frame(42'h2a5123456a);
        expect_value("valid frame sync count", {32'd0, sync_count}, 64'd1);
        expect_value("valid frame sync preload", {48'd0, observed_sync_clk_cnt}, 64'd32);
        expect_value("valid frame valid count", {32'd0, valid_count}, 64'd1);
        expect_value("valid frame codeword", {22'd0, observed_codeword}, {22'd0, 42'h2a5123456a});
        expect_value("valid frame preamble err count", {32'd0, preamble_err_count}, 64'd0);
        @(posedge i_CLK);
        expect_value("codeword_valid 1-cycle low after frame", {63'd0, o_CODEWORD_VALID}, 64'd0);

        $display("[PHASE] wrong preamble");
        clear_monitors();
        send_preamble(8'hA8);
        drive_idle_low(20);
        expect_value("wrong preamble err count", {32'd0, preamble_err_count}, 64'd1);
        expect_value("wrong preamble sync blocked", {32'd0, sync_count}, 64'd0);
        expect_value("wrong preamble valid blocked", {32'd0, valid_count}, 64'd0);

        $display("[PHASE] wrong preamble 이후 valid frame 재동기화");
        clear_monitors();
        send_preamble(8'hAE);
        drive_idle_low(20);
        send_valid_frame(42'h1550abc123);
        expect_value("resync sync count", {32'd0, sync_count}, 64'd1);
        expect_value("resync valid count", {32'd0, valid_count}, 64'd1);
        expect_value("resync err count", {32'd0, preamble_err_count}, 64'd1);
        expect_value("resync codeword", {22'd0, observed_codeword}, {22'd0, 42'h1550abc123});

        $display("[PHASE] reset 중단");
        clear_monitors();
        drive_serial_bit(1'b1);
        drive_serial_bit(1'b0);
        drive_serial_bit(1'b1);
        drive_serial_bit(1'b0);
        @(negedge i_CLK);
        i_RESETN = 1'b0;
        drive_idle_low(6);
        i_RESETN = 1'b1;
        drive_idle_low(6);
        expect_value("reset abort sync count", {32'd0, sync_count}, 64'd0);
        expect_value("reset abort valid count", {32'd0, valid_count}, 64'd0);
        expect_value("reset abort err count", {32'd0, preamble_err_count}, 64'd0);

        $display("[PHASE] BIT_DIV boundary 1");
        clear_monitors();
        i_BIT_DIV = 10'd1;
        send_valid_frame(42'h03ffffffff);
        expect_value("div1 sync count", {32'd0, sync_count}, 64'd1);
        expect_value("div1 sync preload", {48'd0, observed_sync_clk_cnt}, 64'd8);
        expect_value("div1 valid count", {32'd0, valid_count}, 64'd1);
        expect_value("div1 codeword", {22'd0, observed_codeword}, {22'd0, 42'h03ffffffff});

        $display("[PHASE] BIT_DIV boundary 2");
        clear_monitors();
        i_BIT_DIV = 10'd2;
        send_valid_frame(42'h0123456789);
        expect_value("div2 sync count", {32'd0, sync_count}, 64'd1);
        expect_value("div2 sync preload", {48'd0, observed_sync_clk_cnt}, 64'd16);
        expect_value("div2 valid count", {32'd0, valid_count}, 64'd1);
        expect_value("div2 codeword", {22'd0, observed_codeword}, {22'd0, 42'h0123456789});

        if (fail_count == 0)
            $display("PASS: tb_slave_rx");
        else
            $display("FAIL: tb_slave_rx fail_count=%0d", fail_count);

        $finish;
    end

endmodule
