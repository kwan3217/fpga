module mojo_top(
    input clk,
    input rst_n,
    input cclk,
    output[7:0]led,
	 input[8:1]switch,
    output spi_miso,
    input spi_ss,
    input spi_mosi,
    input spi_sck,
    output [3:0] spi_channel,
    input avr_tx,
    output avr_rx,
    input avr_rx_busy
    );

wire rst = ~rst_n;

assign spi_miso = 1'bz;
assign avr_rx = 1'bz;
assign spi_channel = 4'bzzzz;
	 

//assign led[2:0]={switch[3:1]};
assign led[7:5]=3'b000;
//assign led[7:0]=switch[8:1];

wire [3:0] adder_a,adder_b;

register #(.SIZE(4)) a(.in_data(switch[4:1]),.write(1'b1),.out_data(adder_a),.clk(clk));
register #(.SIZE(4)) b(.in_data(switch[8:5]),.write(1'b1),.out_data(adder_b),.clk(clk));

cascade_adder #(.SIZE(4)) adder1 (.a(adder_a),.b(adder_b),.c(1'b0),.s(led[3:0]),.k(led[4]));
	 
endmodule