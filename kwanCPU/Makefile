%: sn74xx.sv cpu.sv %.sv
	iverilog -Wall -g2005-sv $^ && vvp a.out
	gtkwave $@.vcd

clean:
	$(RM) a.out *.vcd


