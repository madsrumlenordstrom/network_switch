PROJECT := network_switch
TOP_MODULE ?= network_switch
TEST_MODULE ?= network_switch_tb

SRC_DIR = src
TB_DIR = tb
OBJ_DIR = obj_dir

SRCS=$(wildcard $(SRC_DIR)/*.sv)
TBS=$(wildcard $(TB_DIR)/*.sv)

compile:
	quartus_map $(PROJECT)
	quartus_fit $(PROJECT)
	quartus_asm $(PROJECT)
	quartus_sta $(PROJECT)

$(OBJ_DIR)/V%: $(TB_DIR)/%.sv $(SRCS)
	verilator --binary -j 0 $< $(SRCS) --top-module $(TEST_MODULE) --trace

test: $(OBJ_DIR)/V$(TEST_MODULE)
	./$(OBJ_DIR)/V$(TEST_MODULE)

clean:
	$(RM) -rf db incremental_db output_files obj_dir

.PHONY: compile clean test
