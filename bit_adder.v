module bit_adder(
    input a,
    input b,
    input c,
    output s,
    output k
    );

assign s = a ^ b ^ c;
assign k = (a & b) | (c & (a ^ b));

endmodule
