// Testbench
module test_full_add;
  parameter N=8;
  reg [N-1:0]a;
  reg [N-1:0]b;
  reg su;
  wire [N-1:0]bus;
  wire cf,zf;
  
  // Instantiate design under test
  ALU #(8) dut (.a(a), .b(b), .su(su), .bus(bus), .cf(cf),.zf(zf),.eo_('0));
          
  initial begin
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(1);
    
    $display("All zero");
    a = 0;
    b = 0;
    su = 0;
    display;
    
    $display("a=1");
    a = 34;
    display;

    $display("b=1");
    b = 12;
    display;

    $display("su=1");
    su = 1;
    display;
  end
  
  task display;
    #1 $display("a:%0d, b:%0d, su:%0h, s:%0d, k:%0h",
      a, b, su, bus, k);
  endtask

endmodule
