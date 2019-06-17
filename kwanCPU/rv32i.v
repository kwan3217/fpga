module regfile #(
  parameter XLEN=32, //Width of registers
  parameter N=32, //Number of registers
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

/*
module random_access_memory #(
  parameter XLEN=4,
  parameter A=4,
  parameter DEPTH = 1<<A //Memory size is N*(2**A)
) (
  input              clk,
  input      [A-1:0] a, 
  input              we,
  input      [XLEN-1:0] d,
  output     [XLEN-1:0] o
);

  reg [XLEN-1:0] memory_array [0:DEPTH-1]; 
  reg [XLEN-1:0] reg_read;
  assign d=reg_read;

  //Make this edge-triggered on the write enable.
  always @(posedge clk) begin
    //Write operation - store data in memory, HiZ the output
    memory_array[a] <= d;
    reg_read=memory_array[a];
  end
  assign o=memory_array[a];
endmodule
*/

module inst_parse #(
  parameter XLEN=32
) (
  input  [31:0] inst,    //Instruction
  output        valid,   //1 if the instruction could be parsed using the RV32I instruction set, 0 otherwise
  output [ 2:0] format,  //Format, either R, I, S, or U
  output        subformat,//if set, instruction is B instead of S or J instead of U
  output [ 6:0] opcode,  //7-bit opcode
  output [ 4:0] rd,      //5-bit destination register address
  output [ 4:0] rs1,     //5-bit source1 register address
  output [ 4:0] rs2,     //5-bit source2 register address
  output [ 2:0] funct3,  //3-bit function code (op subcode)
  output [ 6:0] funct7,  //7-bit function code (op subcode)
  output [XLEN-1:0] imm
);

  parameter R=2'b00;
  parameter I=2'b01;
  parameter S=2'b10;
  parameter B=S;
  parameter U=2'b11;
  parameter J=U;
  
  assign opcode=inst[6:0];

  /*
  always @(*) begin
    format=2'bxx;
    subformat=1'b0;
    case (inst[6:5])
      2'b00 : case (inst[4:2])
        3'b000: format=I; //LOAD
        3'b011: format=I; //MISC-MEM
        3'b100: format=I; //OP-IMM
        3'b101: format=U; //AUIPC
      endcase
      2'b01 : case (inst[4:2])
        3'b000: format=S; //STORE
        3'b100: format=R; //OP
        3'b101: format=U; //LUI
      endcase
      2'b11 : case (inst[4:2])
        3'b000: begin
          format=S;       //BRANCH (B)
          subformat=1'b1;
        end
        3'b001: format=I; //JALR
        3'b011: begin
          format=U;       //JAL (J)
          subformat=1'b1;
        end
      endcase
    endcase
  end
  */
  //The above would have been more readable, but requires reg datatype instead of wire.
  assign {format,subformat,valid}=((inst[6:5]==2'b01)&(inst[4:2]==3'b100))?{R,1'b0,1'b1}: //OP
                                  ((inst[6:5]==2'b00)&(inst[4:2]==3'b000))|               //LOAD
                                  ((inst[6:5]==2'b00)&(inst[4:2]==3'b011))|               //MISC-MEM 
                                  ((inst[6:5]==2'b00)&(inst[4:2]==3'b100))|               //OP-IMM
                                  ((inst[6:5]==2'b11)&(inst[4:2]==3'b001))|               //JALR
                                  ((inst[6:5]==2'b11)&(inst[4:2]==3'b100))?{I,1'b0,1'b1}: //SYSTEM
                                  ((inst[6:5]==2'b01)&(inst[4:2]==3'b000))?{S,1'b0,1'b0}: //STORE
                                  ((inst[6:5]==2'b11)&(inst[4:2]==3'b000))?{B,1'b1,1'b1}: //BRANCH (B)
                                  ((inst[6:5]==2'b11)&(inst[4:2]==3'b011))?{J,1'b1,1'b1}: //JAL (J)
                                  ((inst[6:5]==2'b00)&(inst[4:2]==3'b101))|               //AUIPC
                                  ((inst[6:5]==2'b01)&(inst[4:2]==3'b101))?{U,1'b0,1'b1}: //LUI
                                  {2'b00,1'b0,1'b0}; //default - mark invalid

  //In general, we grab all the fields out of any instruction format
  //Grab this field, even if it isn't right
  assign rd=inst[11:7];
  assign rs1=inst[19:15];
  assign rs2=inst[24:20];
  assign funct3=inst[14:12];
  assign funct7=inst[31:25];

  //Immediate is the only thing that varies from instruction to instruction
  assign imm=(format==I              )?{{XLEN-11{inst[31]}},inst[30:20]}:
             (format==S&&subformat==0)?{{XLEN-11{inst[31]}},inst[30:25],inst[11:7]}:
             (format==B&&subformat==1)?{{XLEN-11{inst[31]}},inst[7],inst[30:25],inst[11:8]}:
             (format==U&&subformat==0)?{inst[31:12],12'b0}:
             (format==J&&subformat==1)?{{XLEN-20{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0}:
             /*Unknown*/               {XLEN{1'bx}};

endmodule

module execute #(
  parameter XLEN=32,
  parameter NPHASE=4,
  parameter NT=$clog2(NPHASE)
) (
  input  [31:0] inst,
  input  [NT-1:0] t,
  output [ 1:0] A,     //ALU A source
  output [ 1:0] B,     //ALU B source
  output [ 1:0] AL,    //ALU operation
  output        SU,    //ALU subtract/Shift mode switch
  output [ 1:0] SH,    //Shift multiplexer
  output [ 2:0] O,     //ALU output destination
  output        J,     //Load PC
  output        EXC,   //Invalid instruction exception
  output [ 4:0] rd,    //Output register 
  output [ 4:0] rs1,   //Input register 1
  output [ 4:0] rs2,   //Input register 2
  output [XLEN-1:0] imm
);

  wire        valid;   //1 if the instruction could be parsed using the RV32I instruction set, 0 otherwise
  wire [ 2:0] format;  //Format, either R, I, S, or U
  wire        subformat;//if set, instruction is B instead of S or J instead of U
  wire [ 6:0] opcode;  //7-bit opcode
  wire [ 4:0] rd;      //5-bit destination register address
  wire [ 4:0] rs1;     //5-bit source1 register address
  wire [ 4:0] rs2;     //5-bit source2 register address
  wire [ 2:0] funct3;  //3-bit function code (op subcode)
  wire [ 6:0] funct7;  //7-bit function code (op subcode)

  inst_parse #(.XLEN(XLEN)) parse(
    .inst(inst),
    .valid(valid),        //1 if the instruction could be parsed using the RV32I instruction set, 0 otherwise
    .format(format),      //Format, either R, I, S, or U
    .subformat(subformat),//if set, instruction is B instead of S or J instead of U
    .opcode(opcode),      //7-bit opcode
    .rd(rd),              //5-bit destination register address
    .rs1(rs1),            //5-bit source1 register address
    .rs2(rs2),            //5-bit source2 register address
    .funct3(funct3),      //3-bit function code (op subcode)
    .funct7(funct7),     //7-bit function code (op subcode)
    .imm(imm)
  );

  //opcodes
  parameter LOAD    ={2'b00,3'b000,2'b11};
  parameter MISC_MEM={2'b00,3'b011,2'b11};
  parameter OP_IMM  ={2'b00,3'b100,2'b11};
  parameter AUIPC   ={2'b00,3'b101,2'b11};
  parameter STORE   ={2'b01,3'b000,2'b11};
  parameter OP      ={2'b01,3'b100,2'b11};
  parameter LUI     ={2'b01,3'b101,2'b11};
  parameter BRANCH  ={2'b11,3'b000,2'b11};
  parameter JALR    ={2'b11,3'b001,2'b11};
  parameter JAL     ={2'b11,3'b011,2'b11};
  parameter SYSTEM  ={2'b11,3'b100,2'b11};

  //funct3 codes
  //OP
  parameter ADD    =3'b000;
  parameter SUB    =ADD;    //distinguished by funct7[5]
  parameter SLT    =3'b010;
  parameter SLTU   =3'b011;
  parameter AND    =3'b111;
  parameter OR     =3'b110;
  parameter XOR    =3'b100;
  parameter SLL    =3'b001;
  parameter SRL    =3'b101;
  parameter SRA    =SRL;    //distinguished by funct7[5]

  //OP-IMM - exactly the same as OP
    
  //A enumerations
  parameter AZERO    =2'b00;
  parameter ARS1     =2'b01;
  parameter APC      =2'b10;

  //B enumerations
  parameter BZERO    =2'b00;
  parameter BRS2     =2'b01;
  parameter BIMM     =2'b10;

  //AL enumerations
  parameter AADD=2'b00;
  parameter AAND=2'b01;
  parameter AOR =2'b10;
  parameter AXOR=2'b11;

  //SH enumerations
  parameter SALU=2'b00;
  parameter SL  =2'b01;
  parameter SR  =2'b00;
  
  //Output enumerations
  parameter DIRECT=3'b000;
  parameter OSLT  =3'b001;
  parameter OSLTU =3'b010;
  parameter NEXTPC=3'b011;
  parameter TOR0  =3'b100;
  parameter ADDR  =3'b101;

  assign {A    ,B    ,AL  ,SU       ,SH  ,O     ,J   ,EXC}=
     (valid==1'b0)?
         {2'bxx,2'bxx,2'bx,1'bx     ,2'bx,3'bxxx,1'bx,1'b1}:
     (opcode==OP_IMM||opcode==OP)?(
       (funct3==ADD)?
         {ARS1 ,opcode==OP?BIMM:BRS2,AADD,opcode==OP?funct7[5]:1'b0,SALU,DIRECT,1'b0,1'b0}:
       (funct3==SLT)?
         {ARS1 ,opcode==OP?BIMM:BRS2,AADD,1'b1                     ,SALU,OSLT  ,1'b0,1'b0}:
       (funct3==SLTU)?
         {ARS1 ,opcode==OP?BIMM:BRS2,AADD,1'b1                     ,SALU,OSLTU ,1'b0,1'b0}:
       (funct3==AND)?
         {ARS1 ,opcode==OP?BIMM:BRS2,AAND,1'bx                     ,SALU,DIRECT,1'b0,1'b0}:
       (funct3==OR)?
         {ARS1 ,opcode==OP?BIMM:BRS2,AOR ,1'bx                     ,SALU,DIRECT,1'b0,1'b0}:
       (funct3==XOR)?
         {ARS1 ,opcode==OP?BIMM:BRS2,AXOR,1'bx                     ,SALU,DIRECT,1'b0,1'b0}:
       (funct3==SLL)?
         {ARS1 ,opcode==OP?BIMM:BRS2,2'bx,1'b0                     ,SL  ,DIRECT,1'b0,1'b0}:
       (funct3==SRL)?
         {ARS1 ,opcode==OP?BIMM:BRS2,2'bx,           funct7[5]     ,SR  ,DIRECT,1'b0,1'b0}:
         {2'bxx,2'bxx               ,2'bx,1'bx                     ,2'bx,3'bxxx,1'bx,1'b1}): //Default for OP-IMM not found
     (opcode==LUI)?
         {AZERO,BIMM                ,AADD,1'b0                     ,SALU,DIRECT,1'b0,1'b0}:
     (opcode==AUIPC)?
         {APC  ,BIMM                ,AADD,1'b0                     ,SALU,DIRECT,1'b0,1'b0}:
     (opcode==JAL)?
         {APC  ,BIMM                ,AADD,1'b0                     ,SALU,NEXTPC,1'b1,1'b0}:
     (opcode==JALR)?
         {APC  ,BIMM                ,AADD,1'b0                     ,SALU,NEXTPC,1'b1,1'b0}:
     (opcode==LOAD)?
         {ARS1 ,BIMM                ,AADD,1'b0                     ,SALU,ADDR  ,1'b0,1'b0}:
     (opcode==STORE)?
         {ARS1 ,BIMM                ,AADD,1'b0                     ,SALU,ADDR  ,1'b0,1'b0}:
         {2'bxx,2'bxx,2'bx,2'bx,3'bxxx,1'bx,1'b1};  //Default for opcode not found


endmodule

