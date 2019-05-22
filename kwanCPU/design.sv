// Design
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

//2-input NOR gate. By default, matches SN74x02
module SN74x02 #(parameter N=4) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  output [N-1:0] y
);

  assign y=a~|b;

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
  input                       cs_,
  input                       we_,
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

module ALU #(parameter N=8,
  parameter SIZE_86=4,
  parameter SIZE_283=4,
  parameter SIZE_244=8) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  input          eo_,
  input          su,
  output [N-1:0] s_int,
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
      SN74x86 #(SIZE_86) u18(
        .a(b[(i+1)*SIZE_86-1:i*SIZE_86]),
        .b({SIZE_86{su}}),
        .y(b_int[(i+1)*SIZE_86-1:i*SIZE_86])
      );
    end
  endgenerate

  //Adding chain - use a bank of '283 adders
  generate
    for(i=0;i<N/SIZE_283;i=i+1) begin
      SN74x283 #(SIZE_283) u21(
        .a(a    [(i+1)*SIZE_283-1:i*SIZE_283]),
        .b(b_int[(i+1)*SIZE_283-1:i*SIZE_283]),
        .c(c_int[i]),
        .s(s_int[(i+1)*SIZE_283-1:i*SIZE_283]),
        .k(c_int[i+1]));
    end
  endgenerate
  assign cf=c_int[N/SIZE_283];

  //Bus interface - use a bank of '244 buffers. I am not using a '245 like Ben did, because
  //he never uses the bidirectional functionality, and because I haven't been able to get
  //bidirectionality to work in Verilog yet.
  generate
    for(i=0;i<N/SIZE_244;i=i+1) begin
      SN74x244 #(SIZE_244) u17(.a1(s_int[i*SIZE_244+SIZE_244/2-1:i*SIZE_244]),
                               .y1(bus  [i*SIZE_244+SIZE_244/2-1:i*SIZE_244]),
                               .g1_(eo_),
                               .a2(s_int[(i+1)*SIZE_244-1:i*SIZE_244+SIZE_244/2]),
                               .y2(bus  [(i+1)*SIZE_244-1:i*SIZE_244+SIZE_244/2]),
                               .g2_(eo_));
    end
  endgenerate
  
endmodule

module ZeroDet #(parameter N=8,
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

module ALUFlags #(parameter N=8,
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
  output [N-1:0] s_int,
  output [N-1:0] bus,
  output         cf,
  output         zf,
//Debugging outputs
  output         cf_int,
  output         zf_int
);

//  wire zf_int,cf_int;
  wire [1:0] q_unused;
  ALU #(.N(N), .SIZE_86(SIZE_86), .SIZE_283(SIZE_283), .SIZE_244(SIZE_244)) topHalf(
    .a(a),
    .b(b),
    .eo_(eo_),
    .su(su),
    .s_int(s_int),
    .bus(bus),
    .cf(cf_int)
  );
  ZeroDet #(.N(N),.SIZE_02(SIZE_02),.SIZE_08(SIZE_08)) zeroDet(
    .s(s_int),
    .zf(zf_int)
  );
  SN74x173 #(.N(SIZE_173)) flagReg(
    .d({cf_int,zf_int,'x,'x   }),
    .q({cf    ,zf    ,q_unused}),
    .m(1'b0),.n(1'b0),
    .g1_(fi_),.g2_(fi_),
    .clk(clk),.clr(clr)
  );

endmodule

module register #(
  parameter N=8,
  parameter SIZE_173=4,
  parameter SIZE_244=4
) (
  inout  [N-1:0] bus,
  input          clk,
  input          clr,
  input          i_,
  input          o_,
  output [N-1:0] val
);

  //storage - use a bank of 74x173 flipflop chips
  genvar i;
  generate
    for(i=0;i<N/SIZE_173;i=i+1) begin
      SN74x173 #(SIZE_173) u12(
        .d(bus    [(i+1)*SIZE_173-1:i*SIZE_173]),
        .q(val    [(i+1)*SIZE_173-1:i*SIZE_173]),
        .m(1'b0),.n(1'b0),
        .g1_(i_),.g2_(i_),
        .clk(clk),.clr(clr));
    end
  endgenerate

  //bus interface - use a bank of 74x244 buffers
  generate
    for(i=0;i<N/SIZE_244;i=i+1) begin
      SN74x244 #(SIZE_244) u17(.a1(val  [i*SIZE_244+SIZE_244/2-1:i*SIZE_244]),
                               .y1(bus  [i*SIZE_244+SIZE_244/2-1:i*SIZE_244]),
                               .g1_(o_),
                               .a2(val  [(i+1)*SIZE_244-1:i*SIZE_244+SIZE_244/2]),
                               .y2(bus  [(i+1)*SIZE_244-1:i*SIZE_244+SIZE_244/2]),
                               .g2_(o_));
    end
  endgenerate

endmodule

module memory_address_register #(
  parameter A=4,
  parameter SIZE_173=4,
  parameter SIZE_157=4
) (
  inout  [A-1:0] bus,
  input          mi_,
  input          clk,
  input          clr,
  output [A-1:0] a,   //This is fed both directly to the LEDs and to the address port of the memory
  input  [A-1:0] sw_mar, //switch bank used to manually program the memory
  input          prog
);

  wire   [A-1:0] q;

  //Flip-flops
  SN74x173 #(.N(SIZE_173)) u34(
    .d(bus),
    .q(q),
    .m(1'b0),
    .n(1'b0),
    .g1_(mi_),
    .g2_(mi_),
    .clk(clk),
    .clr(clr)
  );

  //Multiplexer to select either register or manual address
  SN74x157 #(.N(SIZE_157)) u33(
    .p0(sw_mar),
    .p1(q),
    .sel(prog),
    .g_(1'b0),
    .y(a)
  );
endmodule

module random_access_memory #(
  parameter N=8,
  parameter A=4,
  parameter SIZE_189=4,
  parameter SIZE_157=4
) (
  input  [A-1:0] a,
  inout  [N-1:0] bus,
  input          ro_,  //RAM data out, active low
  input          prog, //0 - use switches for memory address and data (manual program)
                       //1 - use bus for memory data, MAR for address (normal run)
  input          clk,
  input          ri,   //RAM data in, active high
  input  [N-1:0] sw_dat,
  //No need for SW4 (manual program button) since we can do this with CLK in the test bench
  output [N-1:0] memval,
  //debug outputs
  output         we_,
  output [N-1:0] mux2mem,
  output [N-1:0] mem2inv
);

  //Manual bus control
  //SN74x244 #(.N(SIZE_244)) sw_buf(
  //  .a1(sw_bus[3:0]),
  //  .a2(sw_bus[7:4]),
  //  .g1_(~sw_bus_en),
  //  .g2_(~sw_bus_en),
  //  .y1(bus[3:0]),
  //  .y2(bus[7:4])
  //);

  //Data from bus output multiplexers (U26 and U27 on Ben 
  //Eater's schematic) to memory chip inputs
  wire [N-1:0] mux2mem; 
  //Data from memory output to inverters
  wire [N-1:0] mem2inv;
  //wire         we_;

  assign we_=ri ~& clk;

  //Memory chip bank
  genvar i;
  generate
    for(i=0;i<N/SIZE_189;i=i+1) begin
      SN74x189 #(
        .A(A),
        .N(SIZE_189)
      ) u12(
        .o_(mem2inv[(i+1)*SIZE_189-1:i*SIZE_189]),
        .d (mux2mem[(i+1)*SIZE_189-1:i*SIZE_189]),
        .cs_(1'b0),
        .we_(we_),
        .a(a)
      );
    end
  endgenerate

  generate
    for(i=0;i<N/SIZE_157;i=i+1) begin
      SN74x157 #(
        .N(SIZE_157)
      ) u27(
        .p0(sw_dat[(i+1)*SIZE_157-1:i*SIZE_157]),
        .p1(bus   [(i+1)*SIZE_157-1:i*SIZE_157]),
        .y(mux2mem[(i+1)*SIZE_157-1:i*SIZE_157]),
        .sel(prog),
        .g_(1'b0)
      );
    end
  endgenerate
  assign memval=~mem2inv;
  


endmodule
  

module computer #(
  parameter N=8,
  parameter A=4,
  parameter SIZE_244=8
) (
  input          clk,
  input          clr,
  input  [N-1:0] sw_dat,
  input  [A-1:0] sw_mar,
  input          prog, //0 - use switches for memory address and data (manual program)
                       //1 - use bus for memory data, MAR for address (normal run)
  //We put all the observable (IE has LEDs in Ben Eater's design) things here as outputs.
  output [N-1:0] aval,
  output [N-1:0] bval,
  output [N-1:0] irval,
  output [N-1:0] aluval,
  output [A-1:0] marval,
  output [N-1:0] memval,
  output [A-1:0] pcval,
  output [N-1:0] outval,
  output [N-1:0] bus,
  output         cf,
  output         zf,
  //Displays for all control signals, all active high
  //We declare them inout here so that we can control them
  //from outside
  inout          hlt, // Halt clock
  inout          mi,  // Memory address register in
  inout          ri,  // RAM data in
  inout          ro,  // RAM data out
  inout          io,  // Instruction register out
  inout          ii,  // Instruction register in
  inout          ai,  // A register in
  inout          ao,  // A register out
  inout          eo,  // ALU out
  inout          su,  // ALU subtract
  inout          bi,  // B register in
  inout          oi,  // Output register in
  inout          ce,  // Program counter enable
  inout          co,  // Program counter out
  inout          j,   // Jump (program counter in)
  inout          fi   // Flags in
);

  //Register A
  register #(.N(N)) a (
    .bus(bus),
    .val(aval),
    .clk(clk),
    .clr(clr),
    .i_(~ai),
    .o_(~ao)
  );

  //Register B
  register #(.N(N)) b (
    .bus(bus),
    .val(bval),
    .clk(clk),
    .clr(clr),
    .i_(~bi),
    .o_(1'b1) //B register is read-only in this machine
  );

  //ALU/Flags
  ALUFlags #(.N(N)) alu (
    .a(aval),
    .b(bval),
    .eo_(~eo),
    .su(su),
    .fi_(~fi),
    .clk(clk),
    .clr(clr),
    .s_int(aluval),
    .bus(bus),
    .cf(cf),
    .zf(zf)
  );

  //Memory address register
  memory_address_register #(.A(A)) mar (
    .bus(bus[A-1:0]),
    .mi_(~mi),
    .clk(clk),
    .clr(clr),
    .a(marval),
    .sw_mar(sw_mar), //switch bank used to manually program the memory
    .prog(prog)
  );

  //Random access memory
  

endmodule
