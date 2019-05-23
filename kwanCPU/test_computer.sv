// Testbench
module test_cpu;
  //Computer size. Note that this is not yet freely settable in a computer based
  //on 74xx parts -- not all cpu modules properly handle all sizes yet.
  parameter N=8;
  parameter A=4;

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
  reg          ai,ao;    //A register control signals
  reg          bi;       //B register control signal
  reg          ii,io;    //IR control signals
  reg          oi;       //output register control signal
  reg          mi;       //MAR control signal
  reg          ri,ro;    //Memory control signals
  reg          fi,eo,su; //ALU/Flags control signals
  reg          clk,clr;  //Clock and reset
  reg  [N-1:0] bus;      //Internal bus
  reg  [N-1:0] sw_dat;   //Used to manually program memory data
  reg  [A-1:0] sw_mar;   //Used to manually program memory address
  reg          prog;     //Used to set memory mode - use 0 to use sw_dat and sw_mar, 1 to run normally
  reg          sw4;      //Used to clock manual programming - memory is programmed from sw_dat and sw_mar on falling edge

  //Use wires for things which we only observe, not control
  wire cf,zf;

  wire [N-1:0] aval,bval,irval,aluval,oval;
  wire [A-1:0] marval;
  wire [N-1:0] memval;

  // Connect a reg xxx to a wire xxx_w to pass to an inout.
  wire   ai_w, ao_w;
  assign ai_w=ai;
  assign ao_w=ao;
  wire   bi_w;
  assign bi_w=bi;
  wire   ii_w, io_w;
  assign ii_w=ii;
  assign io_w=io;
  wire   oi_w;
  assign oi_w=oi;
  wire   mi_w;
  assign mi_w=mi;
  wire   ri_w, ro_w;
  assign ri_w=ri;
  assign ro_w=ro;
  wire   fi_w, eo_w, su_w;
  assign fi_w=fi;
  assign eo_w=eo;
  assign su_w=su;
  wire [N-1:0] bus_w;
  assign bus_w=bus;

  computer #(.N(8),.A(4)) dut (
    .clk(clk),
    .clr(clr),
    .sw_dat(sw_dat),
    .sw_mar(sw_mar),
    .prog(prog),
    .aval(aval),
    .bval(bval),
    .irval(irval),
    .oval(oval),
    .aluval(aluval),
    .marval(marval),
    .cf(cf),
    .zf(zf),
    .ai(ai_w),.ao(ao_w),
    .bi(bi_w),
    .ii(ii_w),.io(io_w),
    .oi(oi_w),
    .fi(fi_w),.eo(eo_w),.su(su_w),
    .ri(ri_w),.ro(ro_w),
    .mi(mi_w),
    .bus(bus_w),
    .sw4(sw4),
    .memval(memval)
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
    mem[4'he]=      8'h16;
    mem[4'hf]=      8'h2c;
    
    // Reset - deassert all control signals
    clk=0;
    ai=0; ao=0;
    bi=0;
    ii=0; io=0;
    oi=0;
    ri=0; ro=0;
    mi=0;
    fi=0; eo=0; su=0;
    //Disconnect manual programming switches
    sw4='z;
    sw_mar={A{1'bz}};
    sw_dat={N{1'bz}};
    //Don't drive the bus externally
    bus={N{1'bz}}; 

    //Clock the registers once to do a synchronous reset
    clr=1;
    display;
    clk=1;
    display;
    clk=0;
    clr=0;
    
    //store to memory image using switches
    //memory address control
    prog=0;
    sw4=1;
    mi='z;
    for(int i=0;i<16;i++) begin
      //step 0 - release the button and set the switches
      sw4=1;
      sw_mar=i;        
      sw_dat=mem[i];
      display;
      //step 1 - push the button
      sw4=0; 
      display;
    end    
    sw4=1;
    clr=0;

    //Disconnect manual switches
    sw4='z;
    prog=1;
    sw_mar={A{1'bz}};
    sw_dat={N{1'bz}};
    //Deassert memory-in for memory readout
    ri=0;

    //read memory image onto bus by manipulating the bus
    for(int i=0;i<16;i++) begin
      //step 0 - on low clock, force bus to correct address, don't read ram
      clk=0;  //Lower clock
      bus=i;  //Set bus to correct address
      ro=0;   //Don't put memory output on bus
      mi=1;   //      put bus into MAR
      display;
      //step 1 - raise clock
      clk=1;
      display;
      //step 2 - lower clock, don't drive the bus externally, read ram
      ro=1;
      mi=0;
      bus={N{'z}};
      clk=0;
      display;
      //step 3 - raise clock
      clk=1;
      display;
    end;
    ro=0;

    //Manually drive the control signals to load, add, and out (manually execute the program)
    //Fetch 0
    bus=0;fetch;
    
    //LDA
    clk=0;
    io=1; mi=1;
    display;
    clk=1;
    display;
    io=0; mi=0;

    clk=0;
    ro=1; ai=1;
    display;
    clk=1;
    display;
    ro=0; ai=0;

    //Fetch 1
    bus=1;fetch;
    
    //ADD
    clk=0;
    io=1; mi=1;
    display;
    clk=1;
    display;
    io=0; mi=0;

    clk=0;
    ro=1; bi=1;
    display;
    clk=1;
    display;
    ro=0; bi=0;

    clk=0;
    eo=1; ai=1; fi=1;
    display;
    clk=1;
    display;
    eo=0; ai=0; fi=0;

    //Fetch 2
    bus=2;fetch;
    
    //OUT
    clk=0;
    ao=1; oi=1;
    display;
    clk=1;
    display;
    ao=0; oi=0;

  end

  task fetch;
    //Set bus before entering this task
    //cycle 0 - bus->mar
    clk=0;
    mi=1;
    display;
    clk=1;
    display;
    mi=0; bus={N{'z}};

    //cycle 1 - ram->bus
    clk=0;
    ro=1; ii=1; //ce=1;
    display;
    clk=1;
    display;
    ro=0; ii=0; //ce=0;
  endtask 
  
  task display;
    #1 $display("memval:%0h",memval);
  endtask

endmodule


