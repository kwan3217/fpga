// Testbench
module test_cpu;
  //Computer size. Note that this is not yet freely settable in a computer based
  //on 74xx parts -- not all cpu modules properly handle all sizes yet.
  parameter N=8;
  parameter A=4;
  parameter T=3;

  //Assembly mnenomics
  parameter NOP=8'h00;
  parameter LDA=8'h10;
  parameter ADD=8'h20;
  parameter SUB=8'h30;
  parameter STA=8'h40;
  parameter LDI=8'h50;
  parameter JMP=8'h60;
  parameter JC =8'h70;
  parameter JZ =8'h80;
  parameter OUT=8'he0;
  parameter HLT=8'hf0;

  //Use regs for things which we may control from the outside.
  wire         ai,ao;    //A register control signals
  wire         bi;       //B register control signal
  wire         ce,co,j;  //PC control signals
  wire         ii,io;    //IR control signals
  wire         oi;       //output register control signal
  wire         mi;       //MAR control signal
  wire         ri,ro;    //Memory control signals
  wire         fi,eo,su; //ALU/Flags control signals
  wire         hlt;
  reg         clk;      //Clock
  reg  [N-1:0] sw_dat;   //Used to manually program memory data
  reg  [A-1:0] sw_mar;   //Used to manually program memory address
  reg         prog;     //Used to set memory mode - use 0 to use sw_dat and sw_mar, 1 to run normally
  reg          sw4;      //Used to clock manual programming - memory is programmed from sw_dat and sw_mar on falling edge
  reg          sw8;      //Reset switch

  //Use wires for things which we only observe, not control
  wire cf,zf;
  wire [T-1:0] t;        //Subcycle phase

  wire [N-1:0] aval,bval,irval,aluval,oval;
  wire [A-1:0] marval,pcval;
  wire [N-1:0] memval;

  // Connect a reg xxx to a wire xxx_w to pass to an inout.
  wire [N-1:0] bus;

  computer #(.N(8),.A(4)) dut (
    .clk(clk & ~hlt),
    .sw8(sw8),
    .sw_dat(sw_dat),
    .sw_mar(sw_mar),
    .prog(prog),
    .aval(aval),
    .bval(bval),
    .irval(irval),
    .pcval(pcval),
    .oval(oval),
    .aluval(aluval),
    .marval(marval),
    .cf(cf),
    .zf(zf),
    .ai(ai),.ao(ao),
    .bi(bi),
    .ce(ce),.co(co),.j(j),
    .ii(ii),.io(io),
    .oi(oi),
    .fi(fi),.eo(eo),.su(su),
    .ri(ri),.ro(ro),
    .mi(mi),
    .hlt(hlt),
    .bus(bus),
    .sw4(sw4),
    .memval(memval),
    .t(t)
  );


  int mem[1<<A];
  initial begin
    // Dump waves
    $dumpfile("test_computer.vcd");
    $dumpvars(1);

    //Memory image
    mem[4'h0]=LDA | 4'd14;
    mem[4'h1]=ADD | 4'd15;
    mem[4'h2]=OUT        ;
    mem[4'h3]=STA | 4'd13;
    mem[4'h4]=SUB | 4'd15;
    mem[4'h5]=OUT        ;
    mem[4'h6]=LDA | 4'd13;
    mem[4'h7]=OUT        ;
    mem[4'h8]=HLT        ;
    mem[4'he]=      8'h16;
    mem[4'hf]=      8'h2c;
    
    // Reset - deassert all control signals
    clk=0;
    //Disconnect manual programming switches
    sw4='z;
    sw_mar={A{1'bz}};
    sw_dat={N{1'bz}};

    //Clock the registers once to do a synchronous reset
    sw8=1;
    #1 clk=1; #1 clk=0;
    sw8=0;
    
    //store to memory image using switches
    //memory address control
    prog=0;
    sw4=1;
    for(int i=0;i<16;i++) begin
      //step 0 - release the button and set the switches
      sw_mar=i;        
      sw_dat=mem[i];
      //step 1 - push the button
      #1 sw4=0; #1 sw4=1;
    end    
    sw4=1;
    sw8=0;

    //Disconnect manual switches
    sw4='z;
    prog=1;
    sw_mar={A{1'bz}};
    sw_dat={N{1'bz}};
    //Deassert memory-in for memory readout

    /*
    //read memory image onto bus by manipulating the bus
    clk=0;  //Lower clock
    for(int i=0;i<16;i++) begin
      //step 0 - force bus to correct address, don't read ram
      bus=i;      ro=0; mi=1;
      #1 clk=1; #1 clk=0;
      //step 1 - don't drive the bus externally, read ram
      bus={N{'z}};ro=1; mi=0;
      #1 clk=1; #1 clk=0;
    end;
    */

    //Now just let it rip
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;

  end

endmodule


