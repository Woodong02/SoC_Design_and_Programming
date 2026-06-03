// irq_ctrl: IRQ status latch with W1C clear and mask
// IRQ_STATUS bits: [0]=data_sent [1]=no_broadcast [2]=bc_hamming_err
//                 [3]=halt_cmd  [4]=state_change
// Set by 1-clock event pulses; cleared by W1C write (irq_clr); if both fire, clear wins.
module irq_ctrl (
    input  wire       clk,
    input  wire       rst_n,

    input  wire       data_sent,
    input  wire       no_broadcast,
    input  wire       bc_hamming_err,
    input  wire       halt_cmd,
    input  wire       state_change,

    input  wire [4:0] irq_clr,
    input  wire [4:0] irq_mask,

    output reg  [4:0] irq_status,
    output wire       irq
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_status <= 5'd0;
        end else begin
            irq_status[0] <= (irq_status[0] | data_sent)      & ~irq_clr[0];
            irq_status[1] <= (irq_status[1] | no_broadcast)   & ~irq_clr[1];
            irq_status[2] <= (irq_status[2] | bc_hamming_err) & ~irq_clr[2];
            irq_status[3] <= (irq_status[3] | halt_cmd)       & ~irq_clr[3];
            irq_status[4] <= (irq_status[4] | state_change)   & ~irq_clr[4];
        end
    end

    assign irq = |(irq_status & irq_mask);

endmodule
