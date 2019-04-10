ifneq ($(TFTF), 1)
BL33 	= $(TOP_DIR)/u-boot/out/u-boot.bin 
endif
MK_IMG 	= $(TOP_DIR)/u-boot/out/tools/mkimage

u-boot.build:
	export ARCH=aarch64 ; \
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd u-boot ;\
	make -j 16 O=out $(UBOOT_CONFIG);\
	make -j 16 O=out ;

u-boot.clean:
	rm u-boot/out -rf 

