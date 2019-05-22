// Testbench
module test_cpu;
  parameter N=8;
  parameter A=4;
  reg  ai,ao;
  reg  bi;
  reg  fi,eo,su;
  reg  clk,clr;

  //Assembly mnenomics
  parameter NOP=8'h00;
  parameter LDA=8'h10;
  parameter ADD=8'h20;
  parameter SUB=8'h30;
  parameter STA=8'h40;
  parameter LDI=8'h50;
  parameter JMP=8'h60;
  parameter JC =8'h70;
  parameter JZ =8'h80;
  parameter OUT=8'he0;
  parameter HLT=8'hf0;

  wire cf,zf;

  wire ai_w, ao_w, bi_w, fi_w, eo_w, su_w;
  assign ai_w=ai;
  assign ao_w=ao;
  assign bi_w=bi;
  assign fi_w=fi;
  assign eo_w=eo;
  assign su_w=su;

  wire [N-1:0] bus,aval,bval,aluval;
  wire [A-1:0] marval;
  reg  [N-1:0] sw_dat;     //Used to force the bus to a particular value - think of it as a set of dip switches that drive the bus
  reg  [A-1:0] sw_mar;
  reg          prog;
  computer #(.N(8),.A(4)) dut (
    .clk(clk),
    .clr(clr),
    .sw_dat(sw_dat),
    .sw_mar(sw_mar),
    .prog(prog),
    .aval(aval),
    .bval(bval),
    .aluval(aluval),
    .bus(bus),
    .marval(marval),
    .cf(cf),
    .zf(zf),
    .ai(ai_w),
    .ao(ao_w),
    .eo(eo_w),
    .su(su_w),
    .bi(bi_w),
    .fi(fi_w)
  );


  initial begin
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(1);
    
    //Master reset
    clr=1;
    //A register control
    ai=0;    
    ao=0;    
    //B register control
    bi=0;    
    //ALU control
    fi=0;    
    eo=0;
    su =0;

    //load memory image
    //memory address control
    prog=0;
    sw_mar=4'h0;
    sw_dat=LDA | 4'd14;
    clk=1;
    display;
    clk=0;
    display;

    sw_mar=4'h1;
    sw_dat=ADD | 4'd15;
    clk=1;
    display;
    clk=0;
    display;
    
    sw_mar=4'h2;
    sw_dat=OUT;
    clk=1;
    display;
    clk=0;
    display;
    
  end
  
  task display;
    #1 $display("bus:%0h",bus);
  endtask

endmodule

module test_189;

  reg  [3:0] a;
  reg  [3:0] d;
  wire [3:0] o;
  reg        cs_;
  reg        we_;

  SN74x189 dut (
    .a(a),
    .d(d),
    .o_(o),
    .cs_(cs_),
    .we_(we_)
  );


  initial begin
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(1);

    //Write to address 0
    a=4'h0;
    d=4'h5;
    cs_=0;
    we_=0;   //active edge
    display; 

    //Disable
    we_=1;   //inactive edge
    a=4'h1;
    d=4'ha;
    display; //1 to 2

    //Write to address 1
    we_=0;   //active edge
    cs_=0;
    display; //2 to 3

    //Disable
    we_=1;   //inactive edge
    a=4'b0;
    d=4'bz;
    display; //3 to 4

    //Read back address 0
    a=4'h1;
    display; //4 to 5
  end
  
  task display;
    #1 $display("o:%0h",o);
  endtask

endmodule

module test_ram;
  parameter N=8;
  parameter A=4;
  reg  [N-1:0] sw_dat;     //Used to force the bus to a particular value - think of it as a set of dip switches that drive the bus
  reg  [A-1:0] sw_mar;
  reg          prog;
  reg          clk;
  wire [N-1:0] bus;
  wire [N-1:0] memval;
  //catch debug outputs
  wire         we_;
  wire [N-1:0] mux2mem;
  wire [N-1:0] mem2inv;
  //Assembly mnenomics
  parameter NOP=8'h00;
  parameter LDA=8'h10;
  parameter ADD=8'h20;
  parameter SUB=8'h30;
  parameter STA=8'h40;
  parameter LDI=8'h50;
  parameter JMP=8'h60;
  parameter JC =8'h70;
  parameter JZ =8'h80;
  parameter OUT=8'he0;
  parameter HLT=8'hf0;

  random_access_memory #(.N(N),.A(A)) dut (
    .a(sw_mar),
    .bus(bus),
    .ro_(1'b1),
    .prog(prog),
    .clk(clk),
    .ri(1'b1),
    .sw_dat(sw_dat),
    .memval(memval),
    .we_(we_),
    .mux2mem(mux2mem),
    .mem2inv(mem2inv)
  );

  initial begin
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(1);
    //load memory image
    //memory address control
    prog=0;
    sw_mar=4'h0;
    sw_dat=LDA | 4'd14;
    clk=1;
    display;
    clk=0;
    display;
    clk=1;
    display;

    clk=0;
    sw_mar=4'h1;
    sw_dat=ADD | 4'd15;
    display;
    clk=1;
    display;

    clk=0;
    sw_mar=4'h2;
    sw_dat=OUT;
    display;
    clk=1;
    display;
    clk=0;
    display;
    
  end
  
  task display;
    #1 $display("memval:%0h",memval);
  endtask

endmodule

