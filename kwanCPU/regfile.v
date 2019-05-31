module regfile #(
  parameter XLEN=8, //Width of registers
  parameter N=8, //Number of registers
  parameter A=$clog2(N) //Number of address lines
) (
  //Control signals
  input          we,    //write enable
  input          clk,   //clock
  //Register addresses
  input  [A-1:0] addr0, //Address of register to read to output port 0
  input  [A-1:0] addr1, //Address of register to read to output port 1
  input  [A-1:0] addrw, //Address of register to write to
  output [XLEN-1:0] data0, //Data from register read0
  output [XLEN-1:0] data1, //Data from register read1
  input  [XLEN-1:0] dataw  //Data to write to register write
);
  reg  [XLEN-1:0] RF [N-1:1];
  reg  [XLEN-1:0] reg_read0;
  reg  [XLEN-1:0] reg_read1;
  assign data0=reg_read0;
  assign data1=reg_read1;

  always @(posedge clk) begin
    //synchronous write
    if (we && addrw!=0) begin
      RF[addrw]=dataw;
    end
    //synchronous readout
    reg_read0=(addr0==0)?{XLEN{1'b0}}:RF[addr0];
    reg_read1=(addr1==0)?{XLEN{1'b0}}:RF[addr1];
  end
endmodule

