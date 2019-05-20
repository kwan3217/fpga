// Testbench
module test_173;
  parameter N=4;
  reg [N-1:0]d;
  reg g1_;
  reg g2_;
  reg m;
  reg n;
  reg clk;
  reg clr;
  //Actual output
  wire [N-1:0]q;
  //Debug outputs
  wire clk_;
  wire in_en;
  wire in_en_;
  wire out_en;
  wire [N-1:0] q_int;
  wire [N-1:0] d_int;
  wire [N-1:0] top;
  wire [N-1:0] bot;
  
  // Instantiate design under test
  SN74x173 #(N) dut (
              .d(d),
              .m(m),
              .n(n),
              .g1_(g1_),
              .g2_(g2_),
              .clk(clk),
              .clr(clr),
              .q(q),
//Debugging outputs below
              .clk_(clk_),
              .in_en(in_en),
              .in_en_(in_en_),
              .out_en(out_en),
              .q_int(q_int),
              .d_int(d_int),
              .top(top),
              .bot(bot));
          
  initial begin
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(1);
    
    d=4'b1010;
    g1_=1'b1;
    g2_=1'b1;
    m=1'b1;
    n=1'b1;
    clk=1;
    clr=0;
    #1 
    g1_ = 1'b0;
    clk=~clk;
    #1
    
    clk=~clk;
    #1
    g2_ = 1'b0;
    clk=~clk;
    #1

    clk=~clk;
    #1
    m = 1'b0;
    clk=~clk;
    #1

    clk=~clk;
    #1
    n = 1'b0;
    clk=~clk;
    #1

    clk=~clk;
    #1
    clk=~clk;
    //#1

  end
  
endmodule
