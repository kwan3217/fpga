// Testbench
module test_jk;
  reg j;
  reg k;
  reg clk;
  reg clr;
  wire q;
  
  // Instantiate design under test
  jkff dut (
    .j(j),
    .k(k),
    .clk(clk),
    .reset(clr),
    .q(q)
  );
          
  initial begin
    // Dump waves
    $dumpfile("test_jk.vcd");
    $dumpvars(1);
    
    clk=0;
    clr=0;
    j=1;
    k=0;
    #1 clk=1; #1 clk=0;
    j=0;
    #1 clk=1; #1 clk=0;
    k=1;
    #1 clk=1; #1 clk=0;
    k=0;
    #1 clk=1; #1 clk=0;
    j=1;
    k=1;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    j=0;
    k=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    clr=1;
    #1 clk=1; #1 clk=0;
    clr=0;
    j=1;
    k=1;
    #1 clk=1; #1 clk=0;



  end
  
endmodule
