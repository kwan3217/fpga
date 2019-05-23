// Testbench
module test_163;
  parameter N=4;
  reg  [N-1:0] d;
  reg          clk;
  reg          clr;
  reg          load;
  reg          p;
  reg          t;
  //Actual output
  wire [N-1:0] q;
  //Debug output
  wire [N-1:0] j;
  wire [N-1:0] k;
  wire [N-1:0] top;
  wire [N-1:0] mid;
  wire [N-1:0] bot;
  wire         ttop;
  wire [N-1:0] tmid;
  wire [N-1:0] q_;
  wire         en;
  
  // Instantiate design under test
  SN74x163 #(N) dut (
    .d(d),
    .clk(clk),
    .clr_(~clr),
    .load_(~load),
    .p(p),
    .t(t),
    .q(q) /*,
    .j(j),
    .k(k),
    .top(top),
    .mid(mid),
    .bot(bot),
    .ttop(ttop),
    .tmid(tmid),
    .q_(q_),
    .en(en) */
  );
          
  initial begin
    // Dump waves
    $dumpfile("test_163.vcd");
    $dumpvars(1);
    
    d=4'b0000;
    load=0;
    clk=0;
    clr=1;
    p=1;
    t=1;
    #1 clk=1; #1 clk=0;
    clr=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    d=4'b0010;
    load=1;
    #1 clk=1; #1 clk=0;
    load=0;
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
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
    #1 clk=1; #1 clk=0;
  end
  
endmodule


