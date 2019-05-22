%.vcd: design.sv %.sv
	iverilog '-Wall' $^ && vvp a.out
	gtkwave $@

clean:
	$(RM) a.out *.vcd


