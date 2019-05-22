%.vcd: sn74xx.sv cpu.sv %.sv
	iverilog -Wall -g2005-sv $^ && vvp a.out
	gtkwave $@

clean:
	$(RM) a.out *.vcd


