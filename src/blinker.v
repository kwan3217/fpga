module blinker(
    input clk,
    input rst,
    output [7:0] blink
    );
 
reg [24:0] counter_d, counter_q;
 
assign blink[7:0] = counter_q[24:17];
 
always @(counter_q) begin
    counter_d = counter_q + 1'b1;
end
 
always @(posedge clk) begin
    if (rst) begin
        counter_q <= 25'b0;
    end else begin
        counter_q <= counter_d;
    end
end
 
endmodule