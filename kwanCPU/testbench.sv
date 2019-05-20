// Testbench
module test_full_add;
  parameter N=8;
  reg [N-1:0]a;
  reg [N-1:0]b;
  reg su;
  reg clk;
  wire [N-1:0]bus;
  wire cf,zf;
  
  // Instantiate design under test
  ALUFlags #(8) dut (.a(a), .b(b), .su(su), .bus(bus), .cf(cf),.zf(zf),.eo_('0),.fi_('0),.clk(clk));
          
  initial begin
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(1);
    
    $display("All zero");
    a = 0;
    b = 0;
    su = 0;
    clk=1;
    display;
    clk=~clk;
    display;
    
    $display("a=1");
    a = 34;
    clk=~clk;
    display;
    clk=~clk;
    display;

    $display("b=1");
    b = 12;
    clk=~clk;
    display;
    clk=~clk;
    display;

    $display("su=1");
    su = 1;
    clk=~clk;
    display;
    clk=~clk;
    display;
  end
  
  task display;
    #1 $display("a:%0d, b:%0d, su:%0h, s:%0d, k:%0h",
      a, b, su, bus, cf);
  endtask

endmodule
