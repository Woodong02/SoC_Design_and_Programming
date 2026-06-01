`timescale 1ns / 1ps

module tb_slave_tx;

    reg        clk;
    reg        rst_n;
    reg [9:0]  div;
    reg        tx_trigger;
    reg        tx_enable;
    reg [2:0]  slave_addr;
    reg [31:0] tx_data;

    wire       rx_line;
    wire       tx_active;
    wire       data_sent;

    slave_tx uut (
        .clk(clk), .rst_n(rst_n), .div(div),
        .tx_trigger(tx_trigger), .tx_enable(tx_enable),
        .slave_addr(slave_addr), .tx_data(tx_data),
        .rx_line(rx_line), .tx_active(tx_active), .data_sent(data_sent)
    );

    always #5 clk = ~clk;

    // ----------------------------------------------------------------
    // NRZ receiver: mirrors master_rx timing (DIV convention)
    //   bit period  = div clk cycles
    //   sample at   rx_cnt == div>>1  (midpoint)
    //   reset at    rx_cnt == div  → restart at 1
    //   start       rx_cnt = 1 on rising edge
    // ----------------------------------------------------------------
    reg [49:0] rx_buf;
    reg [9:0]  rx_cnt;
    reg        rx_armed;
    reg [5:0]  rx_bits;
    reg        rx_done;
    reg        rx_prev;

    wire [9:0] samp_pt  = div >> 1;  // DIV/2
    wire [9:0] reset_pt = div;       // DIV, full period

    wire rx_in = (rx_line === 1'bz) ? 1'b0 : rx_line;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_buf   <= 50'd0; rx_cnt  <= 10'd0;
            rx_armed <= 1'b0;  rx_bits <= 6'd0;
            rx_done  <= 1'b0;  rx_prev <= 1'b0;
        end else begin
            rx_done <= 1'b0;
            rx_prev <= rx_in;

            if (!rx_armed) begin
                if (!rx_prev && rx_in) begin  // rising edge
                    rx_armed <= 1'b1;
                    rx_cnt   <= 10'd1;
                    rx_bits  <= 6'd0;
                end
            end else begin
                // sample at midpoint
                if (rx_cnt == samp_pt) begin
                    rx_buf  <= {rx_buf[48:0], rx_in};
                    rx_bits <= rx_bits + 6'd1;
                    if (rx_bits == 6'd49) begin
                        rx_armed <= 1'b0;
                        rx_done  <= 1'b1;
                    end
                end
                // counter: reset after full bit period
                if (rx_cnt == reset_pt)
                    rx_cnt <= 10'd1;
                else
                    rx_cnt <= rx_cnt + 10'd1;
            end
        end
    end

    // ----------------------------------------------------------------
    // Hamming reference calculation — systematic SECDED (matches hamming_enc)
    // Returns codeword[6:0] = {p[5:0], p_overall}  (lower 7 bits of 42-bit codeword)
    // ----------------------------------------------------------------
    function [6:0] calc_hamming;
        input [2:0]  addr;
        input [31:0] data;
        reg [34:0] d;
        reg p0,p1,p2,p3,p4,p5,pov;
        begin
            d = {addr, data};
            p0  = d[0]^d[2]^d[4]^d[6]^d[8]^d[10]^d[12]^d[14]
                 ^d[16]^d[18]^d[20]^d[22]^d[24]^d[26]^d[28]^d[30]
                 ^d[32]^d[34];
            p1  = d[1]^d[2]^d[5]^d[6]^d[9]^d[10]^d[13]^d[14]
                 ^d[17]^d[18]^d[21]^d[22]^d[25]^d[26]^d[29]^d[30]
                 ^d[33]^d[34];
            p2  = d[3]^d[4]^d[5]^d[6]^d[11]^d[12]^d[13]^d[14]
                 ^d[19]^d[20]^d[21]^d[22]^d[27]^d[28]^d[29]^d[30];
            p3  = d[7]^d[8]^d[9]^d[10]^d[11]^d[12]^d[13]^d[14]
                 ^d[23]^d[24]^d[25]^d[26]^d[27]^d[28]^d[29]^d[30];
            p4  = d[15]^d[16]^d[17]^d[18]^d[19]^d[20]^d[21]^d[22]
                 ^d[23]^d[24]^d[25]^d[26]^d[27]^d[28]^d[29]^d[30];
            p5  = d[31]^d[32]^d[33]^d[34];
            pov = ^{d, p5, p4, p3, p2, p1, p0};
            calc_hamming = {p5, p4, p3, p2, p1, p0, pov};
        end
    endfunction

    integer pass_cnt, fail_cnt;

    task check_frame;
        input [2:0]  exp_addr;
        input [31:0] exp_data;
        reg [6:0]  exp_h;
        reg [49:0] exp_frame;
        begin
            exp_h     = calc_hamming(exp_addr, exp_data);
            // new frame: {preamble, data[34:0], p[5:0], p_overall}
            exp_frame = {8'hAA, exp_addr, exp_data, exp_h};
            if (rx_buf === exp_frame) begin
                $display("[PASS] frame match: addr=%0d data=0x%H hamming=0x%H",
                         exp_addr, exp_data, exp_h);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] frame mismatch:");
                $display("  expected: 50'h%H", exp_frame);
                $display("  received: 50'h%H", rx_buf);
                $display("  exp_hamming=%b", exp_h);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task send_trigger;
        begin
            @(posedge clk); #1;
            tx_trigger = 1'b1;
            @(posedge clk); #1;
            tx_trigger = 1'b0;
        end
    endtask

    initial begin
        clk = 0; rst_n = 0; div = 10'd8;
        tx_trigger = 0; tx_enable = 1;
        slave_addr = 3'd0; tx_data = 32'd0;
        pass_cnt = 0; fail_cnt = 0;
        #30; @(posedge clk); rst_n = 1;
        repeat(5) @(posedge clk);

        // ---- Test 1: addr=0, data=0, DIV=8 ----
        $display("\n--- Test 1: addr=0, data=0, DIV=8 ---");
        slave_addr = 3'd0; tx_data = 32'd0;
        send_trigger;
        @(posedge rx_done); repeat(5) @(posedge clk);
        check_frame(3'd0, 32'd0);
        repeat(10) @(posedge clk);

        // ---- Test 2: addr=5, data=0xDEADBEEF ----
        $display("\n--- Test 2: addr=5, data=0xDEADBEEF, DIV=8 ---");
        slave_addr = 3'd5; tx_data = 32'hDEADBEEF;
        send_trigger;
        @(posedge rx_done); repeat(5) @(posedge clk);
        check_frame(3'd5, 32'hDEADBEEF);
        repeat(10) @(posedge clk);

        // ---- Test 3: data_sent pulse ----
        $display("\n--- Test 3: data_sent pulse ---");
        slave_addr = 3'd1; tx_data = 32'hA5A5A5A5;
        send_trigger;
        @(posedge data_sent);
        $display("[PASS] data_sent pulse received");
        pass_cnt = pass_cnt + 1;
        repeat(10) @(posedge clk);

        // ---- Test 4: tx_enable=0 → no TX ----
        $display("\n--- Test 4: tx_enable=0 (no TX) ---");
        tx_enable = 0;
        slave_addr = 3'd2; tx_data = 32'hFFFFFFFF;
        send_trigger;
        repeat(div*60) @(posedge clk);
        if (!tx_active && !data_sent) begin
            $display("[PASS] tx_enable=0: no transmission");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("[FAIL] tx_enable=0: unexpected TX");
            fail_cnt = fail_cnt + 1;
        end
        tx_enable = 1;

        $display("\n[DONE] slave_tx: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $finish;
    end

endmodule
