compile:
	quartus_map network-switch
	quartus_fit network-switch
	quartus_asm network-switch
	quartus_sta network-switch

clean:
	rm -f build/*

.PHONY: compile clean
