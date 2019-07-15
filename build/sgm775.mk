CROSS_COMPILE 	?= aarch64-linux-gnu- 
CROSS_COMPILE_M ?= arm-none-eabi-
MODEL 			?= models/Linux64_GCC-4.9/FVP_CSS_SGM-775

TARGETS = scp u-boot arm-tf linux busybox ramdisk device-tree
TOP_DIR 		= $(shell pwd)

build_TARGETS = $(foreach t,$(TARGETS),$(t).build)
clean_TARGETS = $(foreach t,$(TARGETS),$(t).clean)

all: check $(build_TARGETS)

clean: check $(clean_TARGETS)

check:
	for d in $(TARGETS) ; do \
		if [ ! -d "$$d" ] ; then  \
			echo "$$d not exist " ; \
			exit 1;  \
		fi; \
    done ;


scp.build:
	cd scp ; \
	export CROSS_COMPILE=$(CROSS_COMPILE_M) ; \
	make PRODUCT=sgm775 MODE=debug  

scp.clean:
	rm scp/build -rf 

u-boot.build:
	export ARCH=aarch64 ; \
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd u-boot ;\
	make -j 16 O=out sgm_fvp_config;\
	make -j 16 O=out ;

u-boot.clean:
	rm u-boot/out -rf 

arm-tf.build: 
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd arm-tf; \
	make -j 16  PLAT=sgm775 ARCH=aarch64 DEBUG=1 CSS_USE_SCMI_SDS_DRIVER=1 \
	ARM_TSP_RAM_LOCATION=dram BL33=../u-boot/out/u-boot.bin \
	SCP_BL2=../scp/build/product/sgm775/scp_ramfw/debug/bin/firmware.bin \
	TRUSTED_BOARD_BOOT=0 ARM_ROTPK_LOCATION=devel_rsa \
	KEY_ALG=rsa TF_MBEDTLS_KEY_ALG=rsa \
	ROT_KEY=./plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem  \
	MBEDTLS_DIR=../mbedtls GENERATE_COT=1 \
	dtbs all fip;

arm-tf.clean:
	rm arm-tf/build -rf 


linux.build:
	export ARCH=arm64; \
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd linux ; \
	mkdir -p out ;\
	scripts/kconfig/merge_config.sh -O out/ \
	linaro/configs/linaro-base.conf \
	linaro/configs/linaro-base-arm64.conf \
	linaro/configs/big-LITTLE-MP.conf \
	linaro/configs/vexpress64.conf; \
	make O=out/ -j16 Image dtbs ; \
	../u-boot/out/tools/mkimage -A arm64 -O linux -C none -T kernel -n Linux -a 0x80080000 -e 0x80080000 -n Linux -d out/arch/arm64/boot/Image  out/uImage


linux.clean:
	rm linux/out -rf 

busybox.build:
	export ARCH=arm64;  \
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd busybox ; \
	mkdir -p out/ ;\
	make O=out defconfig ;\
	sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g' out/.config ;\
	make O=out/ -j 16 install

busybox.clean:
	rm busybox/out -rf 

ramdisk.build:
	cd ramdisk ; \
	cp ../busybox/out/_install/bin/busybox . ;\
	../linux/out/usr/gen_init_cpio files.txt > ramdisk-busybox.img ;\
	../u-boot/out/tools/mkimage  -A arm64 -O linux -C none -T ramdisk -n ramdisk -a 0x88000000 -e 0x88000000 -n "BusyBox ramdisk" -d ramdisk-busybox.img ramdisk.img

ramdisk.clean:
	rm ramdisk/busybox ramdisk/*.img -rf

device-tree.build:
	cd device-tree ; \
	$(CROSS_COMPILE)cpp -I../linux/include -x assembler-with-cpp -o sgm775.pre sgm775.dts ;\
	sed -i /stdc-predef.h/d sgm775.pre ; \
	../linux/out/scripts/dtc/dtc -O dtb -o sgm775.dtb -i sgm775.dts -b 0 sgm775.pre ;

device-tree.clean: 
	rm device-tree/sgm775.dtb 
	rm device-tree/sgm775.pre

MODEL_PARAMS = \
	-C css.trustedBootROMloader.fname=$(TOP_DIR)/arm-tf/build/sgm775/debug/bl1.bin \
	-C css.scp.ROMloader.fname=$(TOP_DIR)/scp/build/product/sgm775/scp_romfw/debug/bin/firmware.bin \
	-C soc.pl011_uart0.unbuffered_output=1 \
	-C config_id=0 \
	-C displayController=2 \
	-C board.flashloader0.fname=$(TOP_DIR)/arm-tf/build/sgm775/debug/fip.bin \
	-C css.cache_state_modelled=0 \
	--data css.cluster0.cpu0=$(TOP_DIR)/ramdisk/ramdisk.img@0x88000000 \
	--data css.cluster0.cpu0=$(TOP_DIR)/linux/out/uImage@0x80080000  -RSp \
	--data css.cluster0.cpu0=$(TOP_DIR)/device-tree/sgm775.dtb@0x83000000 \



run:
	$(MODEL) $(MODEL_PARAMS) 


ds5:
	@echo "Model params in DS-5:"
	@echo $(MODEL_PARAMS)
	@echo "" 
	@echo "\r\nDebug symbol in DS-5:"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl1/bl1.elf\" EL3:0"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl31/bl31.elf\" EL3:0"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl2/bl2.elf\" EL1S:0"
	@echo "add-symbol-file \"$(TOP_DIR)/linux/out/vmlinux\" EL2N:0"


