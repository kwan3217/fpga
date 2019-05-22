module test_ram;
  parameter N=8;
  parameter A=4;
  reg  [N-1:0] sw_dat;     //Used to force the bus to a particular value - think of it as a set of dip switches that drive the bus
  reg  [A-1:0] sw_mar;
  reg          prog;
  reg          clk;
  wire [N-1:0] bus;
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

  random_access_memory #(.N(N),.A(A)) dut (
    .a(sw_mar),
    .bus(bus),
    .ro_(1'b1),
    .prog(prog),
    .clk(clk),
    .ri(1'b1),
    .sw_dat(sw_dat),
    .memval(memval),
    .we_(we_),
    .mux2mem(mux2mem),
    .mem2inv(mem2inv)
  );

  initial begin
    // Dump waves
    $dumpfile("test_ram.vcd");
    $dumpvars(1);
    //load memory image
    //memory address control
    prog=0;
    sw_mar=4'h0;
    sw_dat=LDA | 4'd14;
    clk=1;
    display;
    clk=0;
    display;
    clk=1;
    display;

    clk=0;
    sw_mar=4'h1;
    sw_dat=ADD | 4'd15;
    display;
    clk=1;
    display;

    clk=0;
    sw_mar=4'h2;
    sw_dat=OUT;
    display;
    clk=1;
    display;
    clk=0;
    display;
    
  end
  
  task display;
    #1 $display("memval:%0h",memval);
  endtask

endmodule

