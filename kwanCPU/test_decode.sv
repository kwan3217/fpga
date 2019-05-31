// Testbench
module test_decode;
  //Computer size. Note that this is not yet freely settable in a computer based
  //on 74xx parts -- not all cpu modules properly handle all sizes yet.
  parameter XLEN=32;      //Size of registers

  reg  [31:0] inst;
  wire [ 2:0] format;  //Format, either R, I, S, or U
  wire        subformat;//if set, instruction is B instead of S or J instead of U
  wire [ 6:0] opcode;  //7-bit opcode
  wire [ 4:0] rd;      //5-bit destination register address
  wire [ 4:0] rs1;     //5-bit source1 register address
  wire [ 4:0] rs2;     //5-bit source2 register address
  wire [ 2:0] funct3;  //3-bit function code (op subcode)
  wire [ 6:0] funct7;  //7-bit function code (op subcode)
  wire [XLEN-1:0] imm;

  //Execute outputs (mostly control signals)
  wire [ 1:0] A;     //ALU A source
  wire [ 1:0] B;     //ALU B source
  wire [ 1:0] ALS;   //ALU Arith/Logic/Shift switch
  wire [ 1:0] S;     //ALU Operation
  wire [ 2:0] O;     //ALU output
  wire        J;     //Load PC
  wire        EXC;   //Invalid instruction exception

  inst_parse #(.XLEN(XLEN)) dut (
    .inst(inst),    //Instruction
    .format(format),  //Format, either R, I, S, or U
    .subformat(subformat),//if set, instruction is B instead of S or J instead of U
    .opcode(opcode),  //7-bit opcode
    .funct3(funct3),  //3-bit function code (op subcode)
    .funct7(funct7)   //7-bit function code (op subcode)
  );

  execute #(.XLEN(XLEN)) exe (
    .inst(inst),
    .A(A),     //ALU A source
    .B(B),     //ALU B source
    .ALS(ALS),   //ALU Arith/Logic/Shift switch
    .S(S),     //ALU Operation
    .O(O),     //ALU output
    .J(J),     //Load PC
    .EXC(EXC),   //Invalid instruction exception
    .rd(rd),    //Output register 
    .rs1(rs1),   //Input register 1
    .rs2(rs2),   //Input register 2
    .imm(imm)
  );

  initial begin
    $dumpfile("test_decode.vcd");
    $dumpvars(1);

    //Clock the registers once to do a synchronous reset
    inst=32'hff010113; //addi sp, sp, -16
    #1;
    inst=32'h00812623; //sw   s0,12(sp) 
    #1;
    inst=32'h01010413; //addi s0,sp,16
    #1;
    inst=32'h02800793; //li   a5,52
    #1;
    inst=32'h00078513; //mv   a0,a5
    #1;
    inst=32'h00c12403; //lw   s0,12(sp)
    #1;
    inst=32'h01010113; //addi sp,sp,16
    #1;
    inst=32'h00008067; //ret
    #1;

  end

endmodule


