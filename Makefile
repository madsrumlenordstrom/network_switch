compile:
	quartus_map network-switch
	quartus_fit network-switch
	quartus_asm network-switch
	quartus_sta network-switch

clean:
	$(RM) -rf db incremental_db output_files

.PHONY: compile clean
