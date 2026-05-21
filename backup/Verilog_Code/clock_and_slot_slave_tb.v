module clock_and_slot_slave_tb;
  reg resetn;
  reg clk;
  reg sync;
  reg sel_sig;
  wire ready;

  clock_and_slot_slave uut (
    .resetn(resetn),
    .clk(clk),
    .sync(sync),
    .sel_sig(sel_sig),
    .ready(ready)
  );

  initial begin
    // Initialize signals
    resetn = 0;
    clk = 0;
    sync = 0;
    sel_sig = 0;

    // Apply reset
    #10 resetn = 1;

    // Test case: Toggle sync and sel_sig
    #20 sync = 1; // Sync signal active
    #20 sync = 0; // Sync signal inactive

    #20 sel_sig = 1; // Select slot 6
    #100 sel_sig = 0; // Select slot 2

    // Add more test cases as needed

    #200000000000 $finish; // End simulation
  end

  // Clock generation
  always #5 clk = ~clk; // Toggle clock every 5 time units

endmodule
