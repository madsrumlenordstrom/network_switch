target ?= switchcore

SV_SRCS := \
	switchcore.sv \
	demux1to2.sv \
	demux1to4.sv \
	fcs_check.sv \
	mux4to1.sv \
	trash_control.sv \
	../crossbar/arbiter.sv \
	../crossbar/crossbar.sv \
	../mac_learning/mac_learning.sv \
	$(wildcard ../sync_fifo_core/*.sv) \

	
TB_SRC  := switchcore_tb.sv

.PHONY: comp
comp:
	verilator --binary --trace $(SV_SRCS) $(target)_tb.sv --top $(target)_tb
	
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
