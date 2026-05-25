`timescale 1ns / 1ps

module tb_master_rx;

    reg        clk;
    reg        rst_n;
    reg        enable;
    reg [9:0]  div;
    reg        tx_line_sync;

    wire       active_edge;
    wire       bc_valid;
    wire       bc_preamble_ok;
    wire [7:0] bc_halt_cmd;
    wire       bc_hamming_err;
    wire       bc_preamble_err;

    master_rx uut (
        .clk(clk), .rst_n(rst_n), .enable(enable),
        .div(div), .tx_line_sync(tx_line_sync),
        .active_edge(active_edge), .bc_valid(bc_valid),
        .bc_preamble_ok(bc_preamble_ok), .bc_halt_cmd(bc_halt_cmd),
        .bc_hamming_err(bc_hamming_err), .bc_preamble_err(bc_preamble_err)
    );

    always #5 clk = ~clk;

    // Send one NRZ bit: holds level for 2*(div+1) clock cycles
    task send_bit;
        input bval;
        integer k;
        begin
            tx_line_sync = bval;
            repeat (2*(div+1)) @(posedge clk);
        end
    endtask

    // Send a 50-bit frame: preamble(8) + data(42 bits)
    // data[41:0] = addr[2:0] + payload[31:0] + hamming[6:0]
    task send_frame;
        input [41:0] data42; // addr+payload+hamming
        integer i;
        begin
            // preamble 0xAA = 10101010
            send_bit(1); send_bit(0);
            send_bit(1); send_bit(0);
            send_bit(1); send_bit(0);
            send_bit(1); send_bit(0);
            // 42-bit data MSB first
            for (i = 41; i >= 0; i = i - 1)
                send_bit(data42[i]);
            // idle
            tx_line_sync = 0;
            repeat (2*(div+1)*5) @(posedge clk);
        end
    endtask

    // Capture outputs at any posedge with a timeout
    task wait_signal;
        input [255:0] name;
        input         expected;
        input         sig;
        begin
            // signal is 1-cycle pulse; sample after last bit
            repeat(5) @(posedge clk);
            if (sig === expected)
                $display("[PASS] %s = %b", name, sig);
            else
                $display("[FAIL] %s expected %b, got %b", name, expected, sig);
        end
    endtask

    reg active_edge_seen;
    reg bc_valid_seen;
    reg bc_preamble_ok_seen;
    reg bc_hamming_err_seen;
    reg bc_preamble_err_seen;

    // Monitor signals
    always @(posedge clk) begin
        if (active_edge)    active_edge_seen    <= 1;
        if (bc_valid)       bc_valid_seen       <= 1;
        if (bc_preamble_ok) bc_preamble_ok_seen <= 1;
        if (bc_hamming_err) bc_hamming_err_seen <= 1;
        if (bc_preamble_err)bc_preamble_err_seen<= 1;
    end

    task clear_flags;
        begin
            active_edge_seen    = 0;
            bc_valid_seen       = 0;
            bc_preamble_ok_seen = 0;
            bc_hamming_err_seen = 0;
            bc_preamble_err_seen= 0;
        end
    endtask

    task check_flags;
        input exp_ae, exp_valid, exp_pok, exp_herr, exp_perr;
        begin
            repeat(3) @(posedge clk); // settle
            if (active_edge_seen    === exp_ae)   $display("[PASS] active_edge    = %b", exp_ae);
            else $display("[FAIL] active_edge    expected %b got %b", exp_ae, active_edge_seen);
            if (bc_preamble_ok_seen === exp_pok)  $display("[PASS] bc_preamble_ok = %b", exp_pok);
            else $display("[FAIL] bc_preamble_ok expected %b got %b", exp_pok, bc_preamble_ok_seen);
            if (bc_valid_seen       === exp_valid) $display("[PASS] bc_valid       = %b", exp_valid);
            else $display("[FAIL] bc_valid       expected %b got %b", exp_valid, bc_valid_seen);
            if (bc_hamming_err_seen === exp_herr)  $display("[PASS] bc_hamming_err = %b", exp_herr);
            else $display("[FAIL] bc_hamming_err expected %b got %b", exp_herr, bc_hamming_err_seen);
            if (bc_preamble_err_seen=== exp_perr)  $display("[PASS] bc_preamble_err= %b", exp_perr);
            else $display("[FAIL] bc_preamble_err expected %b got %b", exp_perr, bc_preamble_err_seen);
        end
    endtask

    initial begin
        clk = 0; rst_n = 0; enable = 0; div = 10'd3; tx_line_sync = 0;
        clear_flags;
        #30; @(posedge clk); rst_n = 1; enable = 1;
        repeat(5) @(posedge clk);

        // ---- Test 1: valid frame, addr=0, payload=0, hamming=0 ----
        $display("\n--- Test 1: valid frame (addr=0,payload=0,hamming=0), DIV=3 ---");
        clear_flags;
        send_frame(42'd0);
        check_flags(1, 1, 1, 0, 0);

        // ---- Test 2: preamble error (0xFF = all-ones, != 0xAA) ----
        $display("\n--- Test 2: preamble error (0xFF sent) ---");
        clear_flags;
        // 0xFF = 11111111 — starts with 1 so receiver triggers, but != 0xAA
        send_bit(1); send_bit(1); send_bit(1); send_bit(1);
        send_bit(1); send_bit(1); send_bit(1); send_bit(1);
        // data field (all zeros)
        repeat(42) begin send_bit(0); end
        tx_line_sync = 0;
        repeat(2*(div+1)*5) @(posedge clk);
        check_flags(1, 0, 0, 0, 1);

        // ---- Test 3: 2-bit Hamming error — flip bits 0 and 1 of hamming ----
        $display("\n--- Test 3: 2-bit Hamming error ---");
        clear_flags;
        send_frame(42'b11); // hamming[1:0] = 11 on all-zero data → 2-bit error
        check_flags(1, 0, 1, 1, 0);

        // ---- Test 4: same frame, larger DIV ----
        $display("\n--- Test 4: valid frame, DIV=9 ---");
        div = 10'd9;
        clear_flags;
        send_frame(42'd0);
        check_flags(1, 1, 1, 0, 0);

        $display("\n[DONE] master_rx verification complete.");
        $finish;
    end

endmodule
