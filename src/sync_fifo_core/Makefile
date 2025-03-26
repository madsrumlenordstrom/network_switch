target ?= sync_fifo_core

.PHONY: comp
comp:
	verilator --binary --trace $(target).sv $(target)_tb.sv --top $(target)_tb

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
