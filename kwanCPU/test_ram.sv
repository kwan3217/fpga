module test_ram;
  parameter N=8;
  parameter A=4;
  reg  [N-1:0] sw_dat;     //Used to force the bus to a particular value - think of it as a set of dip switches that drive the bus
  reg  [A-1:0] sw_mar;
  reg          prog;
  reg          clk;
  reg          sw4;
  reg  [N-1:0] bus;
  reg          mi;
  reg          ri;
  reg          ro;
  wire [A-1:0] a;
  wire [A-1:0] mar_int;
  wire [N-1:0] bus_w;
  wire [N-1:0] memval;
  //catch debug outputs
  wire         we_;
  wire [N-1:0] mux2mem;
  wire [N-1:0] mem2inv;
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

  assign bus_w=bus;
  random_access_memory #(.N(N),.A(A)) dut (
    .a(a),
    .bus(bus_w),
    .ro_(~ro),
    .prog(prog),
    .clk(clk),
    .ri(ri),
    .sw_dat(sw_dat),
    .sw4(sw4),
    .memval(memval),
    .we_(we_),
    .mux2mem(mux2mem),
    .mem2inv(mem2inv)
  );

  memory_address_register #(.A(A)) mar (
    .bus(bus_w[3:0]),
    .mi_(~mi),
    .clk(clk),
    .clr(1'b0),
    .a(a),
    .q(mar_int),   
    .sw_mar(sw_mar), 
    .prog(prog)
  );

  int mem[1<<A];
  initial begin
    // Dump waves
    $dumpfile("test_ram.vcd");
    $dumpvars(1);

    //Memory image
    mem[4'h0]=LDA | 4'd14;
    mem[4'h1]=ADD | 4'd15;
    mem[4'h2]=OUT        ;
    mem[4'he]=      8'd14;
    mem[4'hf]=      8'd28;

    //store to memory image using switches
    //memory address control
    /*
    prog=0;
    sw4=1;
    bus={N{1'bz}};
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

    //read memory image by manipulating the bus
    for(int i=0;i<16;i++) begin
      //step 0 - on low clock, force bus to correct address
      clk=0;
      bus=i;
      display;
      //step 1 - raise clock
      clk=1;
      display;
    end;
    */
    //store to memory image by manipulating the bus
    prog=1;
    sw4='z;
    clk=0;
    mi=1;
    ro=0;
    sw_mar={A{1'bz}};
    sw_dat={N{1'bz}};
    for(int i=0;i<16;i++) begin
      //step 0 - on low clock, force bus to correct address, assert mi, deassert ri
      clk=0;
      mi=1;
      ri=0;
      bus=i;
      display;
      //step 1 - raise clock to get address into MAR
      clk=1;
      display;
      //step 2 - lower clock, force bus to correct data value assert ri, deassert mi
      clk=0;
      mi=0;
      ri=1;
      bus=mem[i];
      display;
      //step 3 - raise clock to get address into RAM
      clk=1;
      display;
    end;

    //read memory image onto bus by manipulating the bus
    ri=0;
    for(int i=0;i<16;i++) begin
      //step 0 - on low clock, force bus to correct address, don't read ram
      clk=0;
      bus=i;
      ro=0;
      mi=1;
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

  end
  
  task display;
    #1 $display("memval:%0h",memval);
  endtask

endmodule

