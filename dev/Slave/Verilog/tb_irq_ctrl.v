`timescale 1ns / 1ps

module tb_irq_ctrl;

    reg       clk, rst_n;
    reg       data_sent, no_broadcast, bc_hamming_err, halt_cmd, state_change;
    reg [4:0] irq_clr, irq_mask;

    wire [4:0] irq_status;
    wire       irq;

    irq_ctrl uut (
        .clk(clk), .rst_n(rst_n),
        .data_sent(data_sent), .no_broadcast(no_broadcast),
        .bc_hamming_err(bc_hamming_err), .halt_cmd(halt_cmd),
        .state_change(state_change),
        .irq_clr(irq_clr), .irq_mask(irq_mask),
        .irq_status(irq_status), .irq(irq)
    );

    always #5 clk = ~clk;

    integer pass_cnt, fail_cnt;

    task pulse_event;
        input [4:0] bits; // which event signals to pulse
        begin
            @(posedge clk); #1;
            if (bits[0]) data_sent     = 1;
            if (bits[1]) no_broadcast  = 1;
            if (bits[2]) bc_hamming_err= 1;
            if (bits[3]) halt_cmd      = 1;
            if (bits[4]) state_change  = 1;
            @(posedge clk); #1;
            data_sent=0; no_broadcast=0; bc_hamming_err=0; halt_cmd=0; state_change=0;
        end
    endtask

    initial begin
        clk=0; rst_n=0;
        data_sent=0; no_broadcast=0; bc_hamming_err=0; halt_cmd=0; state_change=0;
        irq_clr=5'd0; irq_mask=5'h1F;  // all enabled
        pass_cnt=0; fail_cnt=0;
        #30; @(posedge clk); rst_n=1;
        repeat(3) @(posedge clk);

        // ---- Test 1: each event sets its bit ----
        $display("\n--- Test 1: event pulse sets irq_status bit ---");
        pulse_event(5'b00001); repeat(2) @(posedge clk);
        if (irq_status[0]) begin $display("[PASS] data_sent sets bit 0"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] data_sent bit 0 not set"); fail_cnt=fail_cnt+1; end

        pulse_event(5'b00010); repeat(2) @(posedge clk);
        if (irq_status[1]) begin $display("[PASS] no_broadcast sets bit 1"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] no_broadcast bit 1 not set"); fail_cnt=fail_cnt+1; end

        pulse_event(5'b00100); repeat(2) @(posedge clk);
        if (irq_status[2]) begin $display("[PASS] bc_hamming_err sets bit 2"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] bc_hamming_err bit 2 not set"); fail_cnt=fail_cnt+1; end

        pulse_event(5'b01000); repeat(2) @(posedge clk);
        if (irq_status[3]) begin $display("[PASS] halt_cmd sets bit 3"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] halt_cmd bit 3 not set"); fail_cnt=fail_cnt+1; end

        pulse_event(5'b10000); repeat(2) @(posedge clk);
        if (irq_status[4]) begin $display("[PASS] state_change sets bit 4"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] state_change bit 4 not set"); fail_cnt=fail_cnt+1; end

        // ---- Test 2: irq asserted when status & mask != 0 ----
        $display("\n--- Test 2: irq asserted ---");
        // irq_status should have all 5 bits set from test 1
        repeat(2) @(posedge clk);
        if (irq) begin $display("[PASS] irq asserted"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] irq not asserted"); fail_cnt=fail_cnt+1; end

        // ---- Test 3: W1C clear ----
        $display("\n--- Test 3: W1C clear individual bits ---");
        @(posedge clk); #1; irq_clr = 5'h1F;  // clear all
        @(posedge clk); #1; irq_clr = 5'h00;
        repeat(2) @(posedge clk);
        if (irq_status === 5'h00) begin $display("[PASS] all bits cleared by W1C"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] irq_status=%b after clear", irq_status); fail_cnt=fail_cnt+1; end

        // ---- Test 4: irq deasserted after clear ----
        $display("\n--- Test 4: irq deasserted after clear ---");
        repeat(2) @(posedge clk);
        if (!irq) begin $display("[PASS] irq deasserted"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] irq still asserted"); fail_cnt=fail_cnt+1; end

        // ---- Test 5: mask gates irq ----
        $display("\n--- Test 5: mask gates irq ---");
        irq_mask = 5'b00100;  // only bit 2 (bc_hamming_err) unmasked
        pulse_event(5'b00001);  // data_sent: sets bit 0 (masked out)
        repeat(2) @(posedge clk);
        if (!irq) begin $display("[PASS] bit 0 masked, irq not asserted"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] irq asserted despite mask"); fail_cnt=fail_cnt+1; end

        pulse_event(5'b00100);  // bc_hamming_err: sets bit 2 (unmasked)
        repeat(2) @(posedge clk);
        if (irq) begin $display("[PASS] bit 2 unmasked, irq asserted"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] irq not asserted for unmasked bit"); fail_cnt=fail_cnt+1; end

        // ---- Test 6: bits sticky (stay set until cleared) ----
        $display("\n--- Test 6: sticky bits ---");
        irq_mask = 5'h1F;
        @(posedge clk); #1; irq_clr = 5'h1F;  // clear all
        @(posedge clk); #1; irq_clr = 5'h00;
        pulse_event(5'b00001);  // set bit 0
        repeat(5) @(posedge clk);  // wait several clocks
        if (irq_status[0]) begin $display("[PASS] bit stays set"); pass_cnt=pass_cnt+1; end
        else begin $display("[FAIL] bit cleared spontaneously"); fail_cnt=fail_cnt+1; end

        $display("\n[DONE] irq_ctrl: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $finish;
    end

endmodule
