//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:57:24 01/07/2014 
// Design Name: 
// Module Name:    cascade_adder 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module cascade_adder #(parameter SIZE=4) (
    input [SIZE-1:0] a,
    input [SIZE-1:0] b,
    input c,
    output [SIZE-1:0] s,
    output k
    );
	 
wire internal_carry[SIZE-1:0];

genvar i;
generate
    for (i = 0; i < SIZE; i=i+1) begin: cascade_gen_loop
	   if(i==0) begin //first step in cascade - use carry input
        bit_adder bitadd (
            .a(a[i]),
            .b(b[i]),
            .c(c),
            .s(s[i]),
				.k(internal_carry[i])
        );
		end else if(i==(SIZE-1)) begin //last step in cascade - produce carry output
        bit_adder bitadd (
            .a(a[i]),
            .b(b[i]),
            .c(internal_carry[i-1]),
            .s(s[i]),
				.k(k)
        );
		end else begin //intermediate steps - use internal carry
        bit_adder bitadd (
            .a(a[i]),
            .b(b[i]),
            .c(internal_carry[i-1]),
            .s(s[i]),
				.k(internal_carry[i])
        );
		end
    end
endgenerate

endmodule
