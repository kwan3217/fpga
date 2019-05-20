// Testbench
module test_full_add;
  parameter N=8;
  reg [N-1:0]a;
  reg [N-1:0]b;
  reg su;
  reg clk;
  wire [N-1:0]bus;
  wire cf,zf;
  wire cf_int,zf_int;
  
  // Instantiate design under test
  ALUFlags #(8) dut (.a(a), .b(b), .su(su), .bus(bus), .cf(cf),.zf(zf),.eo_('0),.fi_('0),.clk(clk),.cf_int(cf_int),.zf_int(zf_int));
          
  initial begin
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(1);
    
    a = 0;
    b = 0;
    su = 0;
    clk=1;    //posedge
    display;
    clk=~clk; //negedge
    display;
    
    clk=~clk; //posedge
    display;
    clk=~clk; //negedge
    a = 34;  
    display;

    clk=~clk; //posedge
    display;
    clk=~clk; //negedge
    b = 12;
    display;

    clk=~clk; //posedge
    display;
    clk=~clk; //negedge
    su = 1;
    display;

    clk=~clk; //posedge
    display;
    clk=~clk; //negedge
    su = 1;
    display;
  end
  
  task display;
    #1 $display("a:%0d, b:%0d, su:%0h, s:%0d, k:%0h",
      a, b, su, bus, cf);
  endtask

endmodule
