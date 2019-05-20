// Testbench
module test_reg;
  parameter N=8;
  reg  ai,ao;
  reg  bi;
  reg  fi,eo,su;
  reg  clk,clr;

  wire ai_w, ao_w, bi_w, fi_w, eo_w, su_w;
  assign ai_w=ai;
  assign ao_w=ao;
  assign bi_w=bi;
  assign fi_w=fi;
  assign eo_w=eo;
  assign su_w=su;

  wire [N-1:0] bus,aval,bval,aluval;
  reg  [N-1:0] sw;     //Used to force the bus to a particular value - think of it as a set of dip switches that drive the bus
  reg          sw_en;
  computer #(.BUS_SIZE(8),.ADR_SIZE(4)) dut (
    .clk(clk),
    .clr(clr),
    .sw(sw),
    .sw_en(sw_en),
    .aval(aval),
    .bval(bval),
    .aluval(aluval),
    .bus(bus),
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
    //Input control
    sw_en=0;
    sw=8'h5A;

    clk=1;    //posedge
    display;
    clk=~clk; //negedge
    sw_en=1;
    ai=1;
    clr=0;
    display;
    
    clk=~clk; //posedge
    display;
    clk=~clk; //negedge
    sw_en=0;
    sw=8'h00;
    ai=0;
    display;

    clk=~clk; //posedge
    display;
    clk=~clk; //negedge
    ao=1;
    bi=1;
    display;

    clk=~clk; //posedge
    display;
    clk=~clk; //negedge
    ao=0;
    bi=0;
    display;

    clk=~clk; //posedge
    display;
    clk=~clk; //negedge
    display;
  end
  
  task display;
    #1 $display("bus:%0h",bus);
  endtask

endmodule
