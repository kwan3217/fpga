// Testbench
module test_cpu;
  //Computer size. Note that this is not yet freely settable in a computer based
  //on 74xx parts -- not all cpu modules properly handle all sizes yet.
  parameter N=32;
  parameter A=16;
  parameter O=N-A;
  parameter MAXPHASE=4;
  parameter T=$clog2(MAXPHASE+1);

  //Assembly mnenomics
  parameter NOP='h0<<A;
  parameter LDA='h1<<A;
  parameter ADD='h2<<A;
  parameter SUB='h3<<A;
  parameter STA='h4<<A;
  parameter LDI='h5<<A;
  parameter JMP='h6<<A;
  parameter JC ='h7<<A;
  parameter JZ ='h8<<A;
  parameter OUT='he<<A;
  parameter HLT='hf<<A;

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

  computer #(.N(N),.A(A)) dut (
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


  reg mem[1<<A];
  initial begin
    $display("LDA:%0h",LDA);
    // Dump waves
    $dumpfile("test_computer.vcd");
    $dumpvars(1);

    //Memory image
    mem['h000]=LDA | 'h00E;
    mem['h001]=ADD | 'h00F;
    mem['h002]=OUT        ;
    mem['h003]=STA | 'hDDD;
    mem['h004]=SUB | 'h00F;
    mem['h005]=OUT        ;
    mem['h006]=LDA | 'hDDD;
    mem['h007]=OUT        ;
    mem['h008]=HLT        ;
    mem['h00e]=      8'h16;
    mem['h00f]=      8'h2c;
    
    // Reset - deassert all control signals
    clk=0;
    //Disconnect manual programming switches
    sw4=1'bz;
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
    for(int i=0;i<16;i=i+1) begin
      //step 0 - release the button and set the switches
      sw_mar=i;        
      sw_dat=mem[i];
      //step 1 - push the button
      #1 sw4=0; #1 sw4=1;
    end    
    sw4=1;
    sw8=0;

    //Disconnect manual switches
    sw4=1'bz;
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


