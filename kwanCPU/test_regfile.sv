// Testbench
module test_regfile;
  //Computer size. Note that this is not yet freely settable in a computer based
  //on 74xx parts -- not all cpu modules properly handle all sizes yet.
  parameter N=16;         //Number of registers
  parameter XLEN=32;      //Size of registers
  parameter RA=$clog2(N);

  reg clk;
  reg rst;
  reg we;

  reg  [  RA-1:0] addr0;
  reg  [  RA-1:0] addr1;
  reg  [  RA-1:0] addrw;

  wire [XLEN-1:0] data0;
  wire [XLEN-1:0] data1;
  reg  [XLEN-1:0] dataw;

  regfile #(.N(N),.XLEN(XLEN)) dut (
    .clk(clk),
    .we(we),
    .addr0(addr0),
    .addr1(addr1),
    .addrw(addrw),
    .data0(data0),
    .data1(data1),
    .dataw(dataw)
  );

  initial begin
    $dumpfile("test_regfile.vcd");
    $dumpvars(1);

    // Reset - deassert all control signals
    clk=0;
    we=0;
    rst=0;
    addrw=0;
    addr0=0;
    addr1=1;
    dataw=0;

    //Clock the registers once to do a synchronous reset
    rst=1;
    #1 clk=1; #1 clk=0;
    rst=0;

    #1 clk=1; #1 clk=0;
    we=1;dataw='h0101;
    #1 clk=1; #1 clk=0;
    we=0;dataw='hz;
    #1 clk=1; #1 clk=0;
    we=1;dataw='h0101; addrw=1;
    #1 clk=1; #1 clk=0;
    we=0;dataw='hz;
    #1 clk=1; #1 clk=0;
    we=1;dataw='h2222; addrw=2;
    #1 clk=1; #1 clk=0;
    we=0;dataw='hz;
    #1 clk=1; #1 clk=0;
    addr0=1;
    addr1=2;
    #1 clk=1; #1 clk=0;

  end

endmodule


