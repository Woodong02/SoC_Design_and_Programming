`timescale 1ns / 1ps

// Loopback: master_tx drives tx_line → master_rx receives it.
// div=3: bit period=8 clocks; 50 bits = 400 clocks per frame.
module tb_master_tx;

    reg        clk, rst_n;
    reg [9:0]  div;
    reg        tx_trigger,
    reg [7:0]  halt_cmd;

    wire tx_line;
    wire tx_active, data_sent;

    // pull tx_line low when tristated
    wire tx_sync = (tx_line === 1'bz) ? 1'b0 : tx_line;

    // master_rx receives the loopback frame
    wire active_edge, bc_valid, bc_preamble_ok, bc_hamming_err, bc_preamble_err;
    wire [7:0] bc_halt_cmd;

    master_tx u_tx (
        .clk(clk), .rst_n(rst_n),
        .div(div), .tx_trigger(tx_trigger),
        .halt_cmd(halt_cmd),
        .tx_line(tx_line), .tx_active(tx_active), .data_sent(data_sent)
    );

    master_rx u_rx (
        .clk(clk), .rst_n(rst_n),
        .enable(1'b1), .div(div),
        .tx_line_sync(tx_sync),
        .active_edge(active_edge),
        .bc_valid(bc_valid), .bc_preamble_ok(bc_preamble_ok),
        .bc_halt_cmd(bc_halt_cmd),
        .bc_hamming_err(bc_hamming_err),
        .bc_preamble_err(bc_preamble_err)
    );

    always #5 clk = ~clk;

    integer pass_cnt, fail_cnt;
    reg data_sent_seen;
    reg bc_valid_seen;
    reg [7:0] recv_halt_cmd;

    always @(posedge clk) begin
        if (data_sent) data_sent_seen <= 1'b1;
        if (bc_valid)  begin bc_valid_seen <= 1'b1; recv_halt_cmd <= bc_halt_cmd; end
    end

    task send_frame;
        input [7:0] cmd;
        begin
            @(posedge clk); #1;
            halt_cmd   = cmd;
            tx_trigger = 1'b1;
            @(posedge clk); #1;
            tx_trigger = 1'b0;
            // 50 bits × 8 clk = 400 clk; add 60 margin
            repeat(460) @(posedge clk);
        end
    endtask

    initial begin
        clk=0; rst_n=0;
        div=10'd3; tx_trigger=0; halt_cmd=8'h00;
        data_sent_seen=0; bc_valid_seen=0; recv_halt_cmd=0;
        pass_cnt=0; fail_cnt=0;
        #30; @(posedge clk); rst_n=1;
        repeat(5) @(posedge clk);

        // ── Test 1: halt_cmd=0xA5 ──
        $display("\n--- Test 1: halt_cmd=0xA5, check bc_valid and bc_halt_cmd ---");
        data_sent_seen=0; bc_valid_seen=0;
        send_frame(8'hA5);
        if (bc_valid_seen && recv_halt_cmd === 8'hA5) begin
            $display("[PASS] bc_valid=1, bc_halt_cmd=0x%02X", recv_halt_cmd); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] bc_valid=%b, bc_halt_cmd=0x%02X (exp 0xA5)", bc_valid_seen, recv_halt_cmd); fail_cnt=fail_cnt+1;
        end

        // ── Test 2: halt_cmd=0xFF ──
        $display("\n--- Test 2: halt_cmd=0xFF ---");
        data_sent_seen=0; bc_valid_seen=0;
        send_frame(8'hFF);
        if (bc_valid_seen && recv_halt_cmd === 8'hFF) begin
            $display("[PASS] bc_valid=1, bc_halt_cmd=0xFF"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] bc_valid=%b, bc_halt_cmd=0x%02X (exp 0xFF)", bc_valid_seen, recv_halt_cmd); fail_cnt=fail_cnt+1;
        end

        // ── Test 3: halt_cmd=0x00 (all zeros — only hamming bits non-zero) ──
        $display("\n--- Test 3: halt_cmd=0x00 ---");
        data_sent_seen=0; bc_valid_seen=0;
        send_frame(8'h00);
        if (bc_valid_seen && recv_halt_cmd === 8'h00) begin
            $display("[PASS] bc_valid=1, bc_halt_cmd=0x00"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] bc_valid=%b, bc_halt_cmd=0x%02X (exp 0x00)", bc_valid_seen, recv_halt_cmd); fail_cnt=fail_cnt+1;
        end

        // ── Test 4: data_sent pulse ──
        $display("\n--- Test 4: data_sent observed ---");
        data_sent_seen=0;
        send_frame(8'hA5);
        if (data_sent_seen) begin
            $display("[PASS] data_sent pulsed"); pass_cnt=pass_cnt+1;
        end else begin
            $display("[FAIL] data_sent not seen"); fail_cnt=fail_cnt+1;
        end

        $display("\n[DONE] master_tx: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $finish;
    end

endmodule
