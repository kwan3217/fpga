// Testbench
module test_pc;
  parameter A=4;
  reg  [A-1:0] bus;  wire [A-1:0] bus_w; assign bus_w=bus;
  reg          clr;
  reg          clk;
  reg          ce;
  reg          j;
  reg          co;
  wire [A-1:0] pcval;

  // Instantiate design under test
  program_counter #(.A(A)) dut (
    .bus(bus_w),
    .clr_(~clr),
    .clk(clk),
    .ce(ce),
    .j_(~j),
    .co_(~co),
    .pcval(pcval)
  );
          
  initial begin
    // Dump waves
    $dumpfile("test_pc.vcd");
    $dumpvars(1);
    
    clk=0;
    clr=1;
    j=0;
    ce=0;
    co=0;
    bus=4'bz;
    #1 clk=1; #1 clk=0;
    clr=0;
    ce=1;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    co=1;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    co=0;
    #1 clk=1; #1 clk=0;
    ce=0;
    bus=4'b0101;
    j=1;
    #1 clk=1; #1 clk=0;
    j=0;
    bus=4'bz;
    #1 clk=1; #1 clk=0;
    ce=1;
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


