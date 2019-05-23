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
  reg          ce,co,j;  //PC control signals
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
  wire [A-1:0] marval,pcval;
  wire [N-1:0] memval;

  // Connect a reg xxx to a wire xxx_w to pass to an inout.
  wire   ai_w, ao_w;
  assign ai_w=ai;
  assign ao_w=ao;
  wire   bi_w;
  assign bi_w=bi;
  wire   ce_w,co_w,j_w;
  assign ce_w=ce;
  assign co_w=co;
  assign j_w =j;
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
    .pcval(pcval),
    .oval(oval),
    .aluval(aluval),
    .marval(marval),
    .cf(cf),
    .zf(zf),
    .ai(ai_w),.ao(ao_w),
    .bi(bi_w),
    .ce(ce_w),.co(co_w),.j(j_w),
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
    mem[4'h3]=HLT        ;
    mem[4'he]=      8'h16;
    mem[4'hf]=      8'h2c;
    
    // Reset - deassert all control signals
    clk=0;
    ai=0; ao=0;
    bi=0;
    ce=0; co=0; j=0;
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
    #1 clk=1; #1 clk=0;
    clr=0;
    
    //store to memory image using switches
    //memory address control
    prog=0;
    sw4=1;
    mi='z;
    for(int i=0;i<16;i++) begin
      //step 0 - release the button and set the switches
      sw_mar=i;        
      sw_dat=mem[i];
      //step 1 - push the button
      #1 sw4=0; #1 sw4=1;
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
    clk=0;  //Lower clock
    for(int i=0;i<16;i++) begin
      //step 0 - force bus to correct address, don't read ram
      bus=i;      ro=0; mi=1;
      #1 clk=1; #1 clk=0;
      //step 1 - don't drive the bus externally, read ram
      bus={N{'z}};ro=1; mi=0;
      #1 clk=1; #1 clk=0;
    end;
    ro=0;

    //Manually drive the control signals to load, add, and out (manually execute the program)
    //Fetch 0
    fetch;
    
    //LDA
    io=1; mi=1;
    #1 clk=1; #1 clk=0;
    io=0; mi=0;

    ro=1; ai=1;
    #1 clk=1; #1 clk=0;
    ro=0; ai=0;

    //Fetch 1
    fetch;
    
    //ADD
    io=1; mi=1;
    #1 clk=1; #1 clk=0;
    io=0; mi=0;

    ro=1; bi=1;
    #1 clk=1; #1 clk=0;
    ro=0; bi=0;

    eo=1; ai=1; fi=1;
    #1 clk=1; #1 clk=0;
    eo=0; ai=0; fi=0;

    //Fetch 2
    fetch;
    
    //OUT
    ao=1; oi=1;
    #1 clk=1; #1 clk=0;
    ao=0; oi=0;

  end

  task fetch;
    //cycle 0 - bus->mar
    co=1;mi=1;
    #1 clk=1; #1 clk=0;
    co=0;mi=0;

    //cycle 1 - ram->bus
    ro=1; ii=1; ce=1;
    #1 clk=1; #1 clk=0;
    ro=0; ii=0; ce=0;
  endtask 
  
endmodule


