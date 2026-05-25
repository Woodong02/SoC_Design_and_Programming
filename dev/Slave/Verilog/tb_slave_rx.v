`timescale 1ns / 1ps

// Loopback: slave_tx drives rx_line → slave_rx receives it.
// div=3: bit period=8 clocks; 50 bits = 400 clocks per frame.
module tb_slave_rx;

    reg        clk, rst_n;
    reg [9:0]  div;
    reg        tx_trigger, tx_enable;
    reg [2:0]  slave_addr;
    reg [31:0] tx_data;

    wire rx_line;
    wire tx_active, data_sent;

    // pull rx_line low when tristated
    wire rx_sync = (rx_line === 1'bz) ? 1'b0 : rx_line;

    // slave_rx receives the loopback frame
    wire active_edge, frame_valid, hamming_err, preamble_err, preamble_ok;
    wire [2:0]  frame_addr;
    wire [31:0] frame_data;

    slave_tx u_tx (
        .clk(clk), .rst_n(rst_n),
        .div(div), .tx_trigger(tx_trigger), .tx_enable(tx_enable),
        .slave_addr(slave_addr), .tx_data(tx_data),
        .rx_line(rx_line), .tx_active(tx_active), .data_sent(data_sent)
    );

    slave_rx u_rx (
        .clk(clk), .rst_n(rst_n),
        .enable(1'b1), .div(div),
        .rx_line_sync(rx_sync),
        .active_edge(active_edge),
        .frame_valid(frame_valid), .frame_addr(frame_addr), .frame_data(frame_data),
        .hamming_err(hamming_err), .preamble_err(preamble_err), .preamble_ok(preamble_ok)
    );

    always #5 clk = ~clk;

    integer pass_cnt, fail_cnt;
    reg        data_sent_seen, active_edge_seen, frame_valid_seen;
    reg [2:0]  recv_addr;
    reg [31:0] recv_data;

    always @(posedge clk) begin
        if (data_sent)   data_sent_seen   <= 1'b1;
        if (active_edge) active_edge_seen <= 1'b1;
        if (frame_valid) begin
            frame_valid_seen <= 1'b1;
            recv_addr <= frame_addr;
            recv_data <= frame_data;
        end
    end

    task send_frame;
        input [2:0]  addr;
        input [31:0] data;
        begin
            @(posedge clk); #1;
            slave_addr = addr;
            tx_data    = data;
            tx_trigger = 1'b1;
            @(posedge clk); #1;
            tx_trigger = 1'b0;
            // 50 bits × 8 clk = 400 clk; add 60 margin
            repeat(460) @(posedge clk);
        end
    endtask

    initial begin
        clk=0; rst_n=0;
        div=10'd3; tx_trigger=0; tx_enable=1; slave_addr=0; tx_data=0;
        data_sent_seen=0; active_edge_seen=0; frame_valid_seen=0;
        recv_addr=0; recv_data=0;
        pass_cnt=0; fail_cnt=0;
        #30; @(posedge clk); rst_n=1;
        repeat(5) @(posedge clk);

        // ── Test 1: addr=2, data=0xDEADBEEF ──
        $display("\n--- Test 1: addr=2, data=0xDEADBEEF ---");
        data_sent_seen=0; frame_valid_seen=0;
        send_frame(3'd2, 32'hDEADBEEF);
        if (frame_valid_seen && recv_addr===3'd2 && recv_data===32'hDEADBEEF) begin
            $display("[PASS] frame_valid=1, addr=%0d, data=0x%08X", recv_addr, recv_data);
            pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] frame_valid=%b addr=%0d(exp 2) data=0x%08X(exp 0xDEADBEEF)",
                     frame_valid_seen, recv_addr, recv_data);
            fail_cnt=fail_cnt+1;
        end

        // ── Test 2: addr=7, data=0xA5A5A5A5 ──
        $display("\n--- Test 2: addr=7, data=0xA5A5A5A5 ---");
        data_sent_seen=0; frame_valid_seen=0;
        send_frame(3'd7, 32'hA5A5A5A5);
        if (frame_valid_seen && recv_addr===3'd7 && recv_data===32'hA5A5A5A5) begin
            $display("[PASS] frame_valid=1, addr=%0d, data=0x%08X", recv_addr, recv_data);
            pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] frame_valid=%b addr=%0d(exp 7) data=0x%08X(exp 0xA5A5A5A5)",
                     frame_valid_seen, recv_addr, recv_data);
            fail_cnt=fail_cnt+1;
        end

        // ── Test 3: active_edge detected ──
        $display("\n--- Test 3: active_edge detected ---");
        active_edge_seen=0;
        send_frame(3'd0, 32'h12345678);
        if (active_edge_seen) begin
            $display("[PASS] active_edge pulsed"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] active_edge not seen"); fail_cnt=fail_cnt+1;
        end

        // ── Test 4: data_sent and frame_valid both observed ──
        $display("\n--- Test 4: data_sent + frame_valid ---");
        data_sent_seen=0; frame_valid_seen=0;
        send_frame(3'd5, 32'hFFFFFFFF);
        if (data_sent_seen && frame_valid_seen) begin
            $display("[PASS] data_sent=%b, frame_valid=%b", data_sent_seen, frame_valid_seen);
            pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] data_sent=%b, frame_valid=%b", data_sent_seen, frame_valid_seen);
            fail_cnt=fail_cnt+1;
        end

        $display("\n[DONE] slave_rx: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $finish;
    end

endmodule
