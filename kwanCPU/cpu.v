// Design
// Throughout this design, the following parameters shall be used consistently:
// * N - Number of data bits a device can process - This is the number of gates
//       in a gate array, number of channels in a multiplexer, etc. It's what makes
//       an 8-bit computer 8-bit (N=8). Nearly all devices have an N parameter.
// * A - Number of address bits in device - number of words in a memory, etc. The 
//       memory address register as a special case will use A as its size parameter
//       rather than N. In this design, A must be strictly smaller than N, since
//       an instruction is 1 word and is split between opcode bits and address bits.
// In this design, all 74xx parts are expanded or contracted to their natural size,
// and all gate arrays are implemented as Verilog operators rather than 74xx parts.
// Sometimes it makes sense to copy a 74xx part and make it more uniform -- for instance
// the 74x244 has two 4-bit ports which are always used together, so we make a bus_buffer
// that has one noninverted control input and one N-bit port.

module bus_interface #(
  parameter N=8
) (
  input  [N-1:0] a,
  input          g,
  output [N-1:0] y
);
  
  assign y=g?a:{N{1'bz}};
endmodule

//16x4 bit RAM with tristate output and no clock (Weird!). 
module ram_chip #(
  parameter N=4,
  parameter A=4,
  parameter DEPTH = 1<<A //Memory size is N*(2**A)
) (
  input              clk,
  input      [A-1:0] a, 
  input              we,
  input      [N-1:0] d,
  output     [N-1:0] o
);

  reg [N-1:0] memory_array [0:DEPTH-1]; 

  //Make this edge-triggered on the write enable.
  always @(posedge clk)
  begin
    //Write operation - store data in memory, HiZ the output
    memory_array[a] <= d;
  end
  assign o=memory_array[a];
endmodule



module ALU #(
  parameter N=8
) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  input          eo,
  input          su,
  output [N-1:0] s_int,
  output [N-1:0] bus,
  output         cf);

  wire [N-1:0] b_int;

  //Subtraction selector - if subtract is commanded, invert the B output. Use
  //a bank of XOR gates as controllable inverters.
  assign b_int=b ^ {N{su}};

  //Adding chain - use an appropriately sized '283
  SN74x283 #(.N(N)) u21(
        .a(a    ),
        .b(b_int),
        .c(su   ),
        .s(s_int),
        .k(cf   ));

  bus_interface #(.N(N)) u17(.a(s_int),
                             .y(bus  ),
                             .g(eo   ));
  
endmodule

module ZeroDet #(
  parameter N=8
) (
  input [N-1:0] s,
  output        zf
);

  wire [N-1:0] tree_int;
  assign tree_int[0]=s[0];
  genvar i;
  generate
    for(i=0;i<N-1;i=i+1) begin
      assign tree_int[i+1]=tree_int[i] | s[i+1];
    end
  endgenerate
  assign zf=~tree_int[N-1];
endmodule

module ALUFlags #(
  parameter N=8
) (
  input  [N-1:0] a,
  input  [N-1:0] b,
  input          eo,
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

  ALU #(.N(N)) alu (
    .a(a),
    .b(b),
    .eo(eo),
    .su(su),
    .s_int(s_int),
    .bus(bus),
    .cf(cf_int)
  );
  ZeroDet #(.N(N)) zeroDet (
    .s(s_int),
    .zf(zf_int)
  );
  SN74x173 #(.N(2)) flagReg (
    .d({cf_int,zf_int}),
    .q({cf    ,zf    }),
    .m(1'b0),.n(1'b0),
    .g1_(fi_),.g2_(fi_),
    .clk(clk),.clr(clr)
  );

endmodule

module register #(
  parameter N=8
) (
  inout  [N-1:0] bus,
  input          clk,
  input          clr,
  input          i_,
  input          o,
  output [N-1:0] val
);

  SN74x173 #(N) u12(
    .d(bus),
    .q(val),
    .m(1'b0),.n(1'b0),
    .g1_(i_),.g2_(i_),
    .clk(clk),.clr(clr));

  bus_interface #(.N(N)) u17(.a(val),
                             .y(bus),
                             .g(o));

endmodule

module memory_address_register #(
  parameter A=4
) (
  inout  [A-1:0] bus,
  input          mi_,
  input          clk,
  input          clr,
  output [A-1:0] a,   //This is fed both directly to the LEDs and to the address port of the memory
  input  [A-1:0] sw_mar, //switch bank used to manually program the memory
  input          prog,
  //debug displays
  output [A-1:0] q
);

  //wire   [A-1:0] q;

  //Flip-flops
  SN74x173 #(.N(A)) u34(
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
  SN74x157 #(.N(A)) u33(
    .p0(sw_mar),
    .p1(q),
    .sel(prog),
    .g_(1'b0),
    .y(a)
  );
endmodule

module random_access_memory #(
  parameter N=8,
  parameter A=4
) (
  input  [A-1:0] a,
  inout  [N-1:0] bus,
  input          ro,   //RAM data out
  input          prog, //0 - use switches for memory address and data (manual program)
                       //1 - use bus for memory data, MAR for address (normal run)
  input          clk,
  input          ri,   //RAM data in, active high
  input  [N-1:0] sw_dat,
  input          sw4,  //Manual we_, default floating (high), push to write to memory
  //Data from inverters to bus buffers, also used as display for memory contents
  output [N-1:0] memval
);


  //Data from bus output multiplexers (U26 and U27 on Ben 
  //Eater's schematic) to memory chip inputs
  wire [N-1:0] mux2mem; 
  //Data from memory output to inverters
  wire [N-1:0] mem2inv;

  wire         we_;
  assign we_=prog?ri & clk:sw4;

  //Memory chip
  ram_chip #(
    .A(A),
    .N(N)
  ) u12(
    .o(memval),
    .d(mux2mem),
    .clk(clk),
    .we(we),
    .a(a)
  );

  SN74x157 #(
    .N(N)
  ) u27(
    .p0(sw_dat),
    .p1(bus   ),
    .y(mux2mem),
    .sel(prog),
    .g_(1'b0)
  );

  bus_interface #(.N(N)) u30 (
    .a(memval),
    .g(ro),
    .y(bus)
  );
endmodule

module program_counter #(
  parameter A=4
) (  
  inout  [A-1:0] bus,
  input          clr_,
  input          clk,
  input          ce,
  input          j_,
  input          co,
  output [A-1:0] pcval
);

  SN74x163 #(.N(A)) u35(
    .clk(clk),
    .clr_(clr_),
    .p(ce),
    .t(ce),
    .load_(j_),
    .d(bus),
    .q(pcval)
  );

  bus_interface #(.N(A)) u36(
    .a(pcval),
    .g(co),
    .y(bus)
  );
endmodule

module control_unit #(  
  parameter N=8,
  parameter A=4,
  parameter O=N-A,
  parameter MAXPHASE=4,
  parameter T=$clog2(MAXPHASE+1)
) (
  input          clk_,// Out-of-phase clock
  output         clr,
  input          sw8, //Reset switch
  input          cf,
  input          zf,
  input  [O-1:0] ir,
  output         hlt, // Halt clock
  output         mi,  // Memory address register in
  output         ri,  // RAM data in
  output         ro,  // RAM data out
  output         io,  // Instruction register out
  output         ii,  // Instruction register in
  output         ai,  // A register in
  output         ao,  // A register out
  output         eo,  // ALU out
  output         su,  // ALU subtract
  output         bi,  // B register in
  output         oi,  // Output register in
  output         ce,  // Program counter enable
  output         co,  // Program counter out
  output         j,   // Jump (program counter in)
  output         fi,  // Flags in
  output [T-1:0] t    // subcycle phase
);

  wire                  phase_reset;
  wire                  rco;

  //Phase counter
  SN74x163 #(.N(T)) u48 (
    .clk(clk_),
    .clr_(~(clr|phase_reset)),
    .p(1'b1),
    .t(1'b1),
    .load_(1'b1),
    .d({T{1'b1}}),
    .q(t),
	 .rco(rco)
  );

  assign clr=sw8;

  assign phase_reset=(t==MAXPHASE);

  assign hlt=    (t==2  & (ir==15)                                    );
  assign mi =    (t==0                                                )|
                 (t==2  & (ir== 1|ir== 2|ir== 3|ir== 4|ir== 5)        );
  assign ri =    (t==3  & (ir== 4)                                    );  
  assign ro =    (t==1                                                )|
                 (t==3  & (ir== 1|ir== 2|ir== 3)                      );
  assign io =    (t==2  & (ir== 1|ir== 2|ir== 3|ir== 4|ir== 5|ir== 6) );
  assign ii =    (t==1                                                );  
  assign ai =    (t==2  & (ir== 5)                                    )|
                 (t==3  & (ir== 1)                                    )|
                 (t==4  & (ir== 2|ir== 3)                             );
  assign ao =    (t==2  & (ir==14)                                    )|
                 (t==3  & (ir== 4)                                    );
  assign eo =    (t==4  & (ir== 2|ir== 3)                             );  
  assign su =    (t==4  & (ir== 3)                                    );  
  assign bi =    (t==3  & (ir== 2|ir== 3|ir== 4)                      );  
  assign oi =    (t==2  & (ir==14)                                    );  
  assign ce =    (t==1                                                );
  assign co =    (t==0                                                );
  assign j  =    (t==2  & (ir== 6|(ir==7&cf)|(ir==8&zf))              );  
  assign fi =    (t==4  & (ir== 2|ir== 3)                             );  

endmodule

module computer #(
  parameter N=8,   //Word size
  parameter A=4    //Address bus size
) (
  input          clk,
  input  [N-1:0] sw_dat,
  input  [A-1:0] sw_mar,
  input          prog, //0 - use switches for memory address and data (manual program)
                       //1 - use bus for memory data, MAR for address (normal run)
  input          sw4,  //Use to manually toggle clock. Memory reads/writes occur on falling edge.
  input          sw8,  //Reset switch
  //We put all the observable (IE has LEDs in Ben Eater's design) things here as outputs.
  output [N-1:0] aval,
  output [N-1:0] bval,
  output [N-1:0] irval,
  output [N-1:0] oval,
  output [N-1:0] aluval,
  output [A-1:0] marval,
  output [N-1:0] memval,
  output [A-1:0] pcval,
  output [N-1:0] outval,
  output [N-1:0] bus,
  output         cf,
  output         zf,
  output [2:0]   t,
  //Displays for all control signals, all active high
  //We declare them inout here so that we can control them
  //from outside
  output         hlt, // Halt clock
  output         mi,  // Memory address register in
  output         ri,  // RAM data in
  output         ro,  // RAM data out
  output         io,  // Instruction register out
  output         ii,  // Instruction register in
  output         ai,  // A register in
  output         ao,  // A register out
  output         eo,  // ALU out
  output         su,  // ALU subtract
  output         bi,  // B register in
  output         oi,  // Output register in
  output         ce,  // Program counter enable
  output         co,  // Program counter out
  output         j,   // Jump (program counter in)
  output         fi,  // Flags in
  //Debug stuff
  output         clr
);

  
  //Register A
  register #(.N(N)) a (
    .bus(bus),
    .val(aval),
    .clk(clk),
    .clr(clr),
    .i_(~ai),
    .o(ao)
  );

  //Register B
  register #(.N(N)) b (
    .bus(bus),
    .val(bval),
    .clk(clk),
    .clr(clr),
    .i_(~bi),
    .o(1'b0) //B register is read-only in this machine
  );

  //Instruction register
  register #(.N(N)) ir (
    .bus(bus),
    .val(irval),
    .clk(clk),
    .clr(clr),
    .i_(~ii),
    .o(io)
  );

  //Output register. Since we are happy with the display in gtkwave, we don't need the 7-segment driver
  register #(.N(N)) o (
    .bus(bus),
    .val(oval),
    .clk(clk),
    .clr(clr),
    .i_(~oi),
    .o(1'b0) 
  );

  //ALU/Flags
  ALUFlags #(.N(N)) alu (
    .a(aval),
    .b(bval),
    .eo(eo),
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
  random_access_memory #(.N(N),.A(A)) ram (
    .a(marval),
    .bus(bus),
    .ro(ro),
    .prog(prog),
    .clk(clk),
    .ri(ri),
    .sw_dat(sw_dat),
    .sw4(sw4),
    .memval(memval)
  );

  //Program counter
  program_counter #(.A(A)) pc (  
    .bus(bus[A-1:0]),
    .clr_(~clr),
    .clk(clk),
    .ce(ce),
    .j_(~j),
    .co(co),
    .pcval(pcval)
  );

  control_unit #(.N(N),.A(A)) control (
    .clk_(~clk),
    .clr(clr),
    .sw8(sw8),
    .ir(irval[N-1:A]),
    .cf(cf),
    .zf(zf),
    .hlt(hlt),
    .mi(mi),  
    .ri(ri),  
    .ro(ro),  
    .io(io),  
    .ii(ii),  
    .ai(ai),  
    .ao(ao),  
    .eo(eo),  
    .su(su),  
    .bi(bi),  
    .oi(oi),  
    .ce(ce),  
    .co(co),  
    .j(j),   
    .fi(fi),
    .t(t)
  );


endmodule
