dump.vcd: design.sv testbench.sv
	iverilog '-Wall' $^ && vvp a.out
	gtkwave dump.vcd

clean:
	$(RM) a.out dump.vcd


