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


