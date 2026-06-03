`timescale 1ns / 1ps

module tb_slave21_top_full_serial;

    localparam integer BIT_PERIOD = 16;
    localparam integer FRAME_BITS = 50;
    localparam integer NODE_COUNT_PLUS_ONE = 2;
    localparam integer GUARD_TICKS = 20;
    localparam integer MASTER_CYCLE_TICKS = NODE_COUNT_PLUS_ONE * ((FRAME_BITS * BIT_PERIOD) + GUARD_TICKS);
    localparam integer POST_FRAME_IDLE_TICKS = 120;
    localparam integer FIRST_NO_TX_OBSERVE_TICKS = 400;
    localparam integer FIRST_TO_SECOND_REMAIN_TICKS = MASTER_CYCLE_TICKS -
                                                     (FRAME_BITS * BIT_PERIOD) -
                                                     POST_FRAME_IDLE_TICKS -
                                                     FIRST_NO_TX_OBSERVE_TICKS;
    localparam integer RESPONSE_TIMEOUT = 50000;

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

    reg  [34:0] master_data;
    wire [41:0] master_codeword;
    reg  [41:0] response_codeword;
    wire [34:0] response_data;
    wire        response_ham_1bit_err;
    wire        response_ham_2bit_err;

    integer fail_count;
    integer bit_index;
    integer loop_index;
    integer seen_high;
    integer timeout_count;
    integer response_period;
    reg [7:0] response_preamble;

    slave_hamming_enc u_master_enc (
        .i_DATA(master_data),
        .o_CODEWORD(master_codeword)
    );

    slave_hamming_dec u_response_dec (
        .i_CODEWORD(response_codeword),
        .o_DATA(response_data),
        .o_HAM_1BIT_ERR(response_ham_1bit_err),
        .o_HAM_2BIT_ERR(response_ham_2bit_err)
    );

    slave21_top #(
        .NODE_ID(3'd1),
        .NODE_CNT(3'd1),
        .BIT_PERIOD_DEFAULT(16'd16),
        .GUARD_TICKS_DEFAULT(10'd20)
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

    task wait_cycles;
        input integer cycle_count;
        begin
            for (loop_index = 0; loop_index < cycle_count; loop_index = loop_index + 1) begin
                @(posedge i_CLK);
            end
        end
    endtask

    task drive_master_bit;
        input bit_value;
        begin
            i_MASTER_SERIAL = bit_value;
            wait_cycles(BIT_PERIOD);
        end
    endtask

    task send_master_frame_with_idle;
        input [7:0]  preamble_value;
        input [34:0] data_value;
        input integer post_idle_ticks;
        begin
            master_data = data_value;
            #1;
            for (bit_index = 7; bit_index >= 0; bit_index = bit_index - 1) begin
                drive_master_bit(preamble_value[bit_index]);
            end
            for (bit_index = 41; bit_index >= 0; bit_index = bit_index - 1) begin
                drive_master_bit(master_codeword[bit_index]);
            end
            i_MASTER_SERIAL = 1'b0;
            wait_cycles(post_idle_ticks);
        end
    endtask

    task expect_no_slave_activity;
        input [511:0] label;
        input integer cycle_count;
        begin
            seen_high = 0;
            for (loop_index = 0; loop_index < cycle_count; loop_index = loop_index + 1) begin
                @(posedge i_CLK);
                if (o_SLAVE_SERIAL == 1'b1) begin
                    seen_high = 1;
                end
            end
            expect_value(label, seen_high, 0);
        end
    endtask

    task capture_slave_response;
        input integer timeout_limit;
        begin
            response_preamble = 8'd0;
            response_codeword = 42'd0;
            timeout_count = 0;

            while ((o_SLAVE_SERIAL == 1'b0) && (timeout_count < timeout_limit)) begin
                @(posedge i_CLK);
                timeout_count = timeout_count + 1;
            end

            if (timeout_count >= timeout_limit) begin
                fail_count = fail_count + 1;
                $display("[FAIL] response timeout time=%0t", $time);
            end else begin
                response_period = dut.timebase_bit_period;
                if (response_period <= 0) begin
                    response_period = BIT_PERIOD;
                end
                wait_cycles(response_period / 2);
                for (bit_index = 7; bit_index >= 0; bit_index = bit_index - 1) begin
                    response_preamble[bit_index] = o_SLAVE_SERIAL;
                    wait_cycles(response_period);
                end
                for (bit_index = 41; bit_index >= 0; bit_index = bit_index - 1) begin
                    response_codeword[bit_index] = o_SLAVE_SERIAL;
                    wait_cycles(response_period);
                end
                wait_cycles(response_period);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        i_RESETN = 1'b0;
        i_MASTER_SERIAL = 1'b0;
        i_PAYLOAD = 32'h1234abcd;
        master_data = 35'd0;
        response_codeword = 42'd0;
        response_preamble = 8'd0;

        wait_cycles(10);
        i_RESETN = 1'b1;
        wait_cycles(20);

        send_master_frame_with_idle(8'hAA, {8'b00000000, 10'd20, 17'd0}, POST_FRAME_IDLE_TICKS);
        expect_value("first good no tracking", {31'd0, o_LINK_TRACKING}, 32'd0);
        expect_value("first good guard latch", {22'd0, o_LATCHED_GUARD_TICKS}, 32'd20);
        expect_no_slave_activity("first good no tx", FIRST_NO_TX_OBSERVE_TICKS);

        wait_cycles(FIRST_TO_SECOND_REMAIN_TICKS);
        send_master_frame_with_idle(8'hAA, {8'b00000000, 10'd20, 17'd0}, 0);
        expect_value("second good tracking", {31'd0, o_LINK_TRACKING}, 32'd1);
        expect_value("second good not halted", {31'd0, o_HALTED}, 32'd0);

        i_PAYLOAD = 32'hcafef00d;
        capture_slave_response(RESPONSE_TIMEOUT);
        expect_value("response preamble", {24'd0, response_preamble}, 32'h000000aa);
        #1;
        expect_value("response node id", {29'd0, response_data[34:32]}, 32'd1);
        expect_value("response payload", response_data[31:0], 32'hcafef00d);
        expect_value("response no 2bit hamming", {31'd0, response_ham_2bit_err}, 32'd0);

        if (fail_count == 0) begin
            $display("PASS: tb_slave21_top_full_serial");
        end else begin
            $display("FAIL: tb_slave21_top_full_serial fail_count=%0d", fail_count);
        end

        $finish;
    end

endmodule
