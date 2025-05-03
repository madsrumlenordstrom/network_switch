target ?= crossbar

RTL_SRC := \
	arbiter.sv \
	../sync_fifo_core/sdp_1clk_ram.sv \
	../sync_fifo_core/sync_fifo_core.sv \
	crossbar.sv 

.PHONY: comp
comp:
	verilator --binary -j 6 --trace $(RTL_SRC) $(target)_tb.sv --top $(target)_tb

.PHONY: sim
sim:
	./obj_dir/V$(target)_tb

.PHONY: all
all: comp sim

.PHONY: clean
clean:
	rm -rf \
	obj_dir \
	dump.vcd
