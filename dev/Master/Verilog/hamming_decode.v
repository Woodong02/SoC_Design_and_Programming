 module hamming_decode (

    input wire clk,
    input wire [9:0] DIV,
    input wire resetn,
    input wire [2:0] slot,
    input wire [41:0] data_in,
    input wire in_sig,

    output reg out_sig,
    output reg preamble_err

);

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        
    end
    else begin
        if(out_sig) begin
            
        end
    end
  end //data out when the last bit have just been buffer

 endmodule