ifeq ($(OPTEE), 1)
TF_CONFIG += ARM_TSP_RAM_LOCATION=tdram NEED_BL32=yes SPD=opteed \
			 BL32=$(TOP_DIR)/optee/optee_os/out/arm-plat-vexpress/core/tee-header_v2.bin \
    		 BL32_EXTRA1=$(TOP_DIR)/optee/optee_os/out/arm-plat-vexpress/core/tee-pager_v2.bin \
    	   	 BL32_EXTRA2=$(TOP_DIR)/optee/optee_os/out/arm-plat-vexpress/core/tee-pageable_v2.bin 
else 
TF_CONFIG += ARM_TSP_RAM_LOCATION=dram SPD=tspd
endif

optee.build: 
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	export CROSS_COMPILE64=$(CROSS_COMPILE) ; \
	export CROSS_COMPILE32=$(CROSS_COMPILE32) ; \
	export CFG_TEE_CORE_LOG_LEVEL=3 ; \
	export CFG_ARM64_core=y ; \
    cd optee/optee_os; \
	make -j $(JOBS) PLATFORM=vexpress-fvp  DEBUG=1 CFG_ARM_GICV3=y; \
	mkdir -p out/arm-plat-fvp/core ;\
	$(CROSS_COMPILE)objcopy -O binary out/arm-plat-vexpress/core/tee.elf out/arm-plat-fvp/core/tee.bin ; \
	cd ../.. ; \
	cd optee/optee_client ; \
	make -j 16 ; 

optee.clean:
	rm optee/optee_os/out -rf 
	rm optee/optee_client/out -rf 

