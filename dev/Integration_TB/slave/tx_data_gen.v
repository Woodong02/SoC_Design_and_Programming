// tx_data_gen: free-running 32-bit counter for TDMA test payload
// slave_tx latches tx_data at tx_trigger, so each slot captures a distinct counter value
module tx_data_gen (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] tx_data
);
    reg [31:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 32'd0;
        else        cnt <= cnt + 32'd1;
    end
    assign tx_data = cnt;
endmodule
