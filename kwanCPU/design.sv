// Design

//Single full-adder
module add1(input a,
            input b,
            input c,
            output s,
            output k);
  wire a_xor_b;
  wire and_t;
  wire and_b;
  
  //One operator per line - each line corresponds to a gate
  assign a_xor_b=a ^ b;
  assign s=a_xor_b ^ c;
  assign and_t=a_xor_b & c;
  assign and_b=a & b;
  assign k=and_t | and_b;
endmodule

//Single D-type flip-flop
module dff (
  input clk, 
  input reset,
  input d,
  output q, 
  output q_);

  reg        q;

  assign q_ = ~q;

  always @(posedge clk or posedge reset)
  begin
    if (reset) begin
      // Asynchronous reset when reset goes high
      q <= 1'b0;
    end else begin
      // Assign D to Q on positive clock edge
      q <= d;
    end
  end
endmodule

//2-input NOR gate. By default, matches SN74x02
module SN74x02 #(parameter N=4) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  output [N-1:0] y);

  genvar i;
  generate
    for(i=0;i<N;i=i+1) begin
      assign y[i]=a[i]|~b[i];
    end
  endgenerate

endmodule

//2-input AND gate. By default, matches SN74x08
module SN74x08 #(parameter N=4) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  output [N-1:0] y);

  genvar i;
  generate
    for(i=0;i<N;i=i+1) begin
      assign y[i]=a[i] & b[i];
    end
  endgenerate

endmodule

//2-input XOR gate. By default, matches SN74x86
module SN74x86 #(parameter N=4) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  output [N-1:0] y);

  genvar i;
  generate
    for(i=0;i<N;i=i+1) begin
      assign y[i]=a[i]^b[i];
    end
  endgenerate

endmodule

//D-flipflop array. By default, matches SN74x173
module SN74x173 #(parameter N=4) (
              input  [N-1:0] d,
              input          m,
              input          n,
              input          g1_,
              input          g2_,
              input          clk,
              input          clr,
              output [N-1:0] q);
  
  wire out_en;
  assign out_en=(~m)&(~n); //If both out-enables are low, activate the output buffers

  wire in_en,in_en_;
  assign in_en=(~g1_)&(~g2_); //If both in-enables are low, activate read
  assign in_en_=~in_en;

  wire clk_;
  assign clk_=~clk;

  wire [N-1:0] q_int; //Internal state - output of each gate
  wire [N-1:0] d_int; //Internal state - result of input multiplexer
   
  genvar i;
  generate 
    for (i=0; i<N; i=i+1) begin
      dff flipflop(.d(d_int[i]),
                   .q(q_int[i]),
                   .clk(clk),
                   .reset(clr));
    end
  endgenerate

  //Multiplexer to see what D input each flipflop will get
  wire [N-1:0] top;   
  wire [N-1:0] bot;
  assign top=q_int & {N{in_en_}}; //Use output of flipflop if in-enable is off
  assign bot=d     & {N{in_en }}; //Use data input port if in-enable is on
  assign d_int=top | bot;

  //Tristate buffers to determine what gets out
  assign q=out_en?q_int:'bz;
 
endmodule



//Tristate non-inverting buffer array with inverting control pins. By default matches SN74x244
module SN74x244 #(parameter N=8) (
  input [N/2-1:0] a1,
  input [N/2-1:0] a2,
  input g1_,
  input g2_,
  output [N/2-1:0] y1,
  output [N/2-1:0] y2);
  
  assign y1=(g1_)?'bz:a1;
  assign y2=(g2_)?'bz:a2;
endmodule

//Adder with ripple carry. By default, matches SN74x283
module SN74x283 #(parameter N=4) (
              input  [N-1:0] a,
              input  [N-1:0] b,
              input          c,
              output [N-1:0] s,
              output         k);
  
  wire [N:0]     w_CARRY;
   
  assign w_CARRY[0] = c;        
   
  genvar             ii;
  generate 
    for (ii=0; ii<N; ii=ii+1) 
      begin
        add1 full_adder_inst
            ( 
              .a(a[ii]),
              .b(b[ii]),
              .c(w_CARRY[ii]),
              .s(s[ii]),
              .k(w_CARRY[ii+1])
              );
      end
  endgenerate
   
  assign k = w_CARRY[N];
  
endmodule

module ALUTopHalf #(parameter N=8,
  parameter SIZE_86=4,
  parameter SIZE_283=4,
  parameter SIZE_244=8) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  input          eo_,
  input          su,
  output [N-1:0] led,
  output [N-1:0] bus,
  output         cf);

  wire [N-1:0] b_int;
  wire [N/SIZE_283:0] c_int;
  assign c_int[0]=su;

  //Subtraction selector - if subtract is commanded, invert the B output. Use
  //a bank of XOR gates as controllable inverters.
  genvar i;
  generate
    for(i=0;i<N/SIZE_86;i=i+1) begin
      SN74x86 #(SIZE_86) u18(.a(b[(i+1)*SIZE_86-1:i*SIZE_86]),.b({SIZE_86{su}}),.y(b_int[(i+1)*SIZE_86-1:i*SIZE_86]));
    end
  endgenerate

  //Adding chain - use a bank of '283 adders
  generate
    for(i=0;i<N/SIZE_86;i=i+1) begin
      SN74x283 #(SIZE_283) u21(.a(a    [(i+1)*SIZE_283-1:i*SIZE_283]),
                               .b(b_int[(i+1)*SIZE_283-1:i*SIZE_283]),
                               .c(c_int[i]),
                               .s(led  [(i+1)*SIZE_283-1:i*SIZE_283]),
                               .k(c_int[i+1]));
    end
  endgenerate
  assign cf=c_int[N/SIZE_283];

  //Bus interface - use a bank of '244 buffers. I am not using a '245 like Ben did, because
  //he never uses the bidirectional functionality, and because I haven't been able to get
  //bidirectionality to work in Verilog yet.
  generate
    for(i=0;i<N/SIZE_244;i=i+1) begin
      SN74x244 #(SIZE_244) u17(.a1(led[i*SIZE_244+SIZE_244/2-1:i*SIZE_244]),
                               .y1(bus[i*SIZE_244+SIZE_244/2-1:i*SIZE_244]),
                               .g1_(eo_),
                               .a2(led[(i+1)*SIZE_244-1:i*SIZE_244+SIZE_244/2]),
                               .y2(bus[(i+1)*SIZE_244-1:i*SIZE_244+SIZE_244/2]),
                               .g2_(eo_));
    end
  endgenerate
  
endmodule

module ALUZeroDet #(parameter N=8,
  parameter SIZE_02=4,
  parameter SIZE_08=4) (
  input [N-1:0] s,
  output        zf);

  //This code currently only works for N=8
  //wire [3:0] tree1;
  //wire [1:0] tree2;
  //wire dc;
  //SN74x02 #(.N(SIZE_02)) u22(.a(s[3:0]),.b(s[7:4]),.y(tree1));
  //SN74x08 #(.N(SIZE_08)) u23(.a({tree1[0],tree1[1],tree2[0],'0}),
  //                           .b({tree1[2],tree1[3],tree2[1],'0}),
  //                           .y({tree2[0],tree2[1],zf,dc}));
  wire [N:0] tree_int;
  assign tree_int[0]=s[0];
  genvar i;
  generate
    for(i=0;i<N-1;i=i+1) begin
      assign tree_int[i+1]=tree_int[i] | s[i+1];
    end
  endgenerate
  assign zf=~tree_int[N-1];
endmodule

module ALU #(parameter N=8,
  parameter SIZE_86=4,
  parameter SIZE_283=4,
  parameter SIZE_244=8,
  parameter SIZE_02=4,
  parameter SIZE_08=4,
  parameter SIZE_173=4) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  input          eo_,
  input          su,
  input          fi_,
  input          clk,
  input          clr,
  output [N-1:0] led,
  output [N-1:0] bus,
  output         cf,
  output         zf);

  wire zf_int,cf_int;
  ALUTopHalf #(.N(N),
               .SIZE_86(SIZE_86),
               .SIZE_283(SIZE_283),
               .SIZE_244(SIZE_244)) topHalf(.a(a),.b(b),.eo_(eo_),.su(su),.led(led),.bus(bus),.cf(cf));
  ALUZeroDet #(.N(N),.SIZE_02(SIZE_02),.SIZE_08(SIZE_08)) zeroDet(led,zf_int);
//  SN74x173 #(.N(SIZE_173)) flagReg(

endmodule
