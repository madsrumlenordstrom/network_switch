compile:
	quartus_map network-switch
	quartus_fit network-switch
	quartus_asm network-switch
	quartus_sta network-switch

clean:
	rm -rf db incremental_db

.PHONY: compile clean
