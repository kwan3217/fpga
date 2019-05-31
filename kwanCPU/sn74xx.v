// Throughout this design, the following parameters shall be used consistently:
// * N - Number of data bits a device can process - This is the number of gates
//       in a gate array, number of channels in a multiplexer, etc. It's what makes
//       an 8-bit computer 8-bit (N=8). Nearly all devices have an N parameter.
// * A - Number of address bits in device - number of words in a memory, etc. The 
//       memory address register as a special case will use A as its size parameter
//       rather than N.
// * SIZE_xxx - Size of the sub-devices a device uses. Parts in the 74xx series are
//       typically 4-bit devices, and therefore a real physical implementation of an
//       8-bit machine will typically have banks of two such devices. We simulate 
//       that here. Rather than make an 8-gate NAND array, we use generate to make
//       a bank of two 4-bit arrays. We use the SIZE_xxx to specify the default size
//       of the 

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
  output reg q, 
  output q_);

//  reg        q;

  assign q_ = ~q;

  always @(posedge clk)
  begin
    if (reset) begin
      // Synchronous reset when reset goes high, based on recommendation in 
      // Xilinx training material
      q <= 1'b0;
    end else begin
      // Assign D to Q on positive clock edge
      q <= d;
    end
  end
endmodule

module jkff (
  input      clk,
  input      reset,
  input      j,
  input      k,
  output reg q,
  output     q_
);

  assign q_ = ~q;

  always @(posedge clk) begin
    if (reset) begin
      q<=0;
    end else begin
      case({j,k})
        2'b00 : q <=    q;
        2'b01 : q <= 1'b0;
        2'b10 : q <= 1'b1;
        2'b11 : q <=   ~q;
      endcase
    end
  end
endmodule

//2-input NOR gate. By default, matches SN74x02
module SN74x02 #(parameter N=4) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  output [N-1:0] y
);

  assign y=~(a|b);

endmodule

//2-input AND gate. By default, matches SN74x08
module SN74x08 #(parameter N=4) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  output [N-1:0] y
);

  assign y=a & b;

endmodule

//2-input XOR gate. By default, matches SN74x86
module SN74x86 #(parameter N=4) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  output [N-1:0] y
);

  assign y=a^b;

endmodule

//2-to-1 multiplexer. By default, matches SN74x157
module SN74x157 #(
  parameter N=4
) (
  input  [N-1:0] p0,
  input  [N-1:0] p1,
  input          sel,
  input          g_,
  output [N-1:0] y
);
  wire sel0=~sel;
  wire sel1= sel;
  wire g=~g_;
  wire [N-1:0] int0;
  wire [N-1:0] int1;
  assign int0=(p0 & {N{sel0 & g}});
  assign int1=(p1 & {N{sel1 & g}});
  assign y=int0 | int1;

endmodule

//Programmable counter. By default, matches SN74x163A. Ben Eater's design uses a '161, 
//but we use a:
//  '163x because we like synchronous clear (in fact this doesn't even use the clear input)
//  not A because the front end is too complicated, and this exercises the JK flipflop
module SN74x163 #(parameter N=4) (
  input  [N-1:0] d,
  input          load_,
  input          clk,
  input          clr_,
  input          p,
  input          t,
  output [N-1:0] q,
  output         rco,
  //Debug outputs
  output [N-1:0] j,
  output [N-1:0] k,
  output [N-1:0] top,
  output [N-1:0] mid,
  output [N-1:0] bot,
  output         ttop,
  output [N  :0] tmid,
  output [N-1:0] q_,
  output         en
);

  genvar i;
  generate
    for(i=0;i<N;i=i+1) begin
      jkff jk(
        .j(j[i]),
        .k(k[i]),
        .clk(clk),
        .reset(1'b0),
        .q(q[i]),
        .q_(q_[i])
      );
    end
  endgenerate

  //input layer
   and  (en     ,p    ,t);
  nand  (ttop   ,load_,clr_);

  //left layer
  assign tmid[0]=en;
  generate
    for(i=0;i<N;i=i+1) begin
      and  (tmid[i+1],q[i],tmid[i]);
    end
  endgenerate
  assign rco=tmid[N];

  //Middle layer
  //   y = a   #b   ...
  generate
    for(i=0;i<N;i=i+1) begin
      nand(top[i],ttop   ,bot[i]);
       or (mid[i],tmid[i],ttop  );
      nand(bot[i],d[i]   ,clr_  ,ttop);
    end
  endgenerate
   
  //right-most layer, up against the flipflops
  assign j = top & mid;
  assign k = mid & bot;
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
              output [N-1:0] q,
//Debugging outputs below
              output clk_,
              output in_en,
              output in_en_,
              output out_en,
              output [N-1:0] q_int,
              output [N-1:0] d_int,
              output [N-1:0] top,
              output [N-1:0] bot);
  
  //wire out_en;
  assign out_en=(~m)&(~n); //If both out-enables are low, activate the output buffers

  //wire in_en,in_en_;
  assign in_en=(~g1_)&(~g2_); //If both in-enables are low, activate read
  assign in_en_=~in_en;

  //wire clk_;
  assign clk_=~clk;

  //wire [N-1:0] q_int; //Internal state - output of each gate
  //wire [N-1:0] d_int; //Internal state - result of input multiplexer
   
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
  //wire [N-1:0] top;   
  //wire [N-1:0] bot;
  assign top=q_int & {N{in_en_}}; //Use output of flipflop if in-enable is off
  assign bot=d     & {N{in_en }}; //Use data input port if in-enable is on
  assign d_int=top | bot;

  //Tristate buffers to determine what gets out
  assign q=out_en?q_int:'bz;
 
endmodule

//16x4 bit RAM with tristate output and no clock (Weird!). 
module SN74x189 #(
  parameter N=4,
  parameter A=4,
  parameter DEPTH = 1<<A //Memory size is N*(2**A)
) (
  input      [A-1:0] a, 
  input              cs_,
  input              we_,
  input      [N-1:0] d,
  output     [N-1:0] o_ 
);

  reg [N-1:0] memory_array [0:DEPTH-1]; 

  //Make this edge-triggered on the write enable.
  always @(negedge we_ & ~cs_)
  begin
    //Write operation - store data in memory, HiZ the output
    memory_array[a] <= d;
  end
  assign o_=(~cs_ & we_)?~memory_array[a]:{N{1'bz}};
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


