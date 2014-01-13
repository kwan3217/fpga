module register #(parameter SIZE=4)(
    input [SIZE-1:0] in_data,
    output [SIZE-1:0] out_data,
    input write,
    input clk
    );

reg [SIZE-1:0] value_d;
reg [SIZE-1:0] value_q;

assign out_data=value_q;

always @(posedge clk) begin
  if(write) begin
    value_d=in_data;
  end
  value_q = value_d;
end

endmodule
