PROJECT := network-switch

compile:
	quartus_map $(PROJECT)
	quartus_fit $(PROJECT)
	quartus_asm $(PROJECT)
	quartus_sta $(PROJECT)

test: tb/fcs_check_serial_tb.sv src/fcs_check_serial.sv
	echo "NONE"
	verilator --binary -j 0 tb/fcs_check_serial_tb.sv src/fcs_check_serial.sv --trace
	./obj_dir/Vfcs_check_serial_tb

clean:
	$(RM) -rf db incremental_db output_files

.PHONY: compile clean test
