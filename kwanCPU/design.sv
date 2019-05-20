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

module mar #(
  parameter ADR_SIZE=4,
  parameter SIZE_173=4,
  parameter SIZE_157=4
) (
  inout  [ADR_SIZE-1:0] bus,
  input                 mi_,
  input                 clk,
  input                 clr,
  output                a,   //This is fed both directly to the LEDs and to the address port of the memory
  input  [ADR_SIZE-1:0] sw_mar, //switch bank used to manually program the memory
  input                 prog,
)

endmodule
  

module computer #(
  parameter BUS_SIZE=8,
  parameter ADR_SIZE=4,
  parameter SIZE_244=8
) (
  input                 clk,
  input                 clr,
  input  [BUS_SIZE-1:0] sw_bus,
  input                 sw_bus_en,
  input  [BUS_SIZE-1:0] sw_mar,
  input                 sw_mar_en,
  //We put all the observable (IE has LEDs in Ben Eater's design) things here as outputs.
  output [BUS_SIZE-1:0] aval,
  output [BUS_SIZE-1:0] bval,
  output [BUS_SIZE-1:0] irval,
  output [BUS_SIZE-1:0] aluval,
  output [ADR_SIZE-1:0] marval,
  output [BUS_SIZE-1:0] memval,
  output [ADR_SIZE-1:0] pcval,
  output [BUS_SIZE-1:0] outval,
  output [BUS_SIZE-1:0] bus,
  output                cf,
  output                zf,
  //Displays for all control signals, all active high
  //We declare them inout here so that we can control them
  //from outside
  inout                 hlt, // Halt clock
  inout                 mi,  // Memory address register in
  inout                 ri,  // RAM data in
  inout                 ro,  // RAM data out
  inout                 io,  // Instruction register out
  inout                 ii,  // Instruction register in
  inout                 ai,  // A register in
  inout                 ao,  // A register out
  inout                 eo,  // ALU out
  inout                 su,  // ALU subtract
  inout                 bi,  // B register in
  inout                 oi,  // Output register in
  inout                 ce,  // Program counter enable
  inout                 co,  // Program counter out
  inout                 j,   // Jump (program counter in)
  inout                 fi   // Flags in
);

  //Register A
  register #(.N(BUS_SIZE)) a (
    .bus(bus),
    .val(aval),
    .clk(clk),
    .clr(clr),
    .i_(~ai),
    .o_(~ao)
  );

  //Register B
  register #(.N(BUS_SIZE)) b (
    .bus(bus),
    .val(bval),
    .clk(clk),
    .clr(clr),
    .i_(~bi),
    .o_(1'b1) //B register is read-only in this machine
  );

  //ALU/Flags
  ALUFlags #(.N(BUS_SIZE)) alu (
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

  //Manual bus control
  SN74x244 #(.N(SIZE_244)) sw_buf(
    .a1(sw[3:0]),
    .a2(sw[7:4]),
    .g1_(~sw_en),
    .g2_(~sw_en),
    .y1(bus[3:0]),
    .y2(bus[7:4])
  );
  
endmodule
