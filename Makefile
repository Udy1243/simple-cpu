RTL = rtl/cpu.sv rtl/alu.sv rtl/register_file.sv rtl/memory.sv
TB  = tb/cpu_tb.sv

.PHONY: sim synth clean

sim:
	mkdir -p sim
	iverilog -g2012 -o sim/cpu_tb $(TB) $(RTL) && vvp sim/cpu_tb

synth:
	yosys syn/cpu.ys

clean:
	rm -f sim/cpu_tb sim/waves.vcd