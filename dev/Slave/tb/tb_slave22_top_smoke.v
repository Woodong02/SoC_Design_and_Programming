`timescale 1ns / 1ps

module tb_slave22_top_smoke;

    localparam [2:0] FLT21_ACQUIRE   = 3'd1;
    localparam [2:0] FLT21_SEEN_ONCE = 3'd2;
    localparam [2:0] FLT21_TRACKING  = 3'd3;
    localparam [2:0] FLT21_RECOVERY  = 3'd4;

    reg         i_CLK;
    reg         i_RESETN;
    reg         i_MASTER_SERIAL;
    reg  [31:0] i_PAYLOAD;
    wire        o_SLAVE_SERIAL;
    wire        o_LINK_TRACKING;
    wire        o_HALTED;
    wire        o_RATE_ERR;
    wire [2:0]  o_FAULT_STATE;
    wire [9:0]  o_LATCHED_GUARD_TICKS;

    reg  [34:0] forced_data;
    wire [41:0] forced_codeword;
    integer fail_count;

    slave_hamming_enc u_tb_enc (
        .i_DATA(forced_data),
        .o_CODEWORD(forced_codeword)
    );

    slave22_top #(
        .NODE_ID(3'd1),
        .NODE_CNT(3'd2),
        .BIT_PERIOD_DEFAULT(16'd8),
        .GUARD_TICKS_DEFAULT(10'd10)
    ) dut (
        .i_CLK(i_CLK),
        .i_RESETN(i_RESETN),
        .i_MASTER_SERIAL(i_MASTER_SERIAL),
        .i_PAYLOAD(i_PAYLOAD),
        .o_SLAVE_SERIAL(o_SLAVE_SERIAL),
        .o_LINK_TRACKING(o_LINK_TRACKING),
        .o_HALTED(o_HALTED),
        .o_RATE_ERR(o_RATE_ERR),
        .o_FAULT_STATE(o_FAULT_STATE),
        .o_LATCHED_GUARD_TICKS(o_LATCHED_GUARD_TICKS)
    );

    initial begin
        i_CLK = 1'b0;
        forever #5 i_CLK = ~i_CLK;
    end

    task expect_value;
        input [511:0] label;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s got=0x%08x exp=0x%08x time=%0t", label, got, exp, $time);
            end else begin
                $display("[PASS] %0s got=0x%08x time=%0t", label, got, $time);
            end
        end
    endtask

    task force_frame;
        input [34:0] data_value;
        begin
            forced_data = data_value;
            #1;
            force dut.rx_codeword = forced_codeword;
            force dut.rx_codeword_valid = 1'b1;
            force dut.rx_frame_done = 1'b1;
            @(posedge i_CLK);
            #1;
            release dut.rx_codeword;
            release dut.rx_codeword_valid;
            release dut.rx_frame_done;
            @(posedge i_CLK);
            #1;
        end
    endtask

    task force_bad_frame;
        begin
            force dut.rx_codeword_valid = 1'b0;
            force dut.rx_frame_done = 1'b1;
            @(posedge i_CLK);
            #1;
            release dut.rx_codeword_valid;
            release dut.rx_frame_done;
            @(posedge i_CLK);
            #1;
        end
    endtask

    initial begin
        fail_count = 0;
        i_RESETN = 1'b0;
        i_MASTER_SERIAL = 1'b0;
        i_PAYLOAD = 32'h1234abcd;
        forced_data = 35'd0;

        repeat (4) @(posedge i_CLK);
        i_RESETN = 1'b1;
        repeat (2) @(posedge i_CLK);
        #1;
        force dut.timebase_rate_err = 1'b0;

        expect_value("reset/release acquire", {29'd0, o_FAULT_STATE}, {29'd0, FLT21_ACQUIRE});
        expect_value("reset not tracking", {31'd0, o_LINK_TRACKING}, 32'd0);
        expect_value("reset not halted", {31'd0, o_HALTED}, 32'd0);

        force_frame({8'b00000000, 10'd22, 17'd0});
        expect_value("first good seen once", {29'd0, o_FAULT_STATE}, {29'd0, FLT21_SEEN_ONCE});
        expect_value("first good no tracking", {31'd0, o_LINK_TRACKING}, 32'd0);
        expect_value("guard latched", {22'd0, o_LATCHED_GUARD_TICKS}, 32'd22);

        force_frame({8'b00000000, 10'd24, 17'd0});
        expect_value("second good tracking", {29'd0, o_FAULT_STATE}, {29'd0, FLT21_TRACKING});
        expect_value("link tracking high", {31'd0, o_LINK_TRACKING}, 32'd1);
        expect_value("guard relatched", {22'd0, o_LATCHED_GUARD_TICKS}, 32'd24);

        force_frame({8'b00000010, 10'd26, 17'd0});
        expect_value("halt command halted", {31'd0, o_HALTED}, 32'd1);
        expect_value("halt keeps fault tracking", {29'd0, o_FAULT_STATE}, {29'd0, FLT21_TRACKING});

        force_bad_frame();
        expect_value("bad frame recovery", {29'd0, o_FAULT_STATE}, {29'd0, FLT21_RECOVERY});
        expect_value("recovery not tracking output", {31'd0, o_LINK_TRACKING}, 32'd0);

        if (fail_count == 0) begin
            $display("PASS: tb_slave22_top_smoke");
        end else begin
            $display("FAIL: tb_slave22_top_smoke fail_count=%0d", fail_count);
        end

        $finish;
    end

endmodule
