CROSS_COMPILE ?= aarch64-linux-gnu- 
CROSS_COMPILE32 ?= arm-linux-gnueabi-
MODEL ?= /usr/local/DS-5_v5.29.1/sw/models/bin/Foundation_Platform
TARGETS = u-boot arm-tf linux busybox ramdisk 

TOP_DIR = $(shell pwd)

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

u-boot.build:
	export ARCH=aarch64 ; \
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd u-boot ;\
	make -j 16 O=out vexpress_aemv8a_semi_config ;\
	make -j 16 O=out ;

u-boot.clean:
	rm u-boot/out -rf 



optee.build: 
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	export CROSS_COMPILE64=$(CROSS_COMPILE) ; \
	export CROSS_COMPILE32=$(CROSS_COMPILE32) ; \
	export CFG_TEE_CORE_LOG_LEVEL=1 ; \
	export CFG_ARM64_core=y ; \
    cd optee/optee_os; \
	make -j 16  PLATFORM=vexpress-fvp CFG_ARM_GICV3=y; \
	cd ../.. ; \
	cd optee/optee_client ; \
	make -j 16 ; 

optee.clean:
	rm optee/optee_os/out -rf 
	rm optee/optee_client/out -rf 


arm-tf.optee.build:
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd arm-tf; \
	make -j 16  PLAT=fvp ARCH=aarch64 DEBUG=1  \
	ARM_TSP_RAM_LOCATION=tdram NEED_BL32=yes SPD=opteed \
	BL32=../optee/optee_os/out/arm-plat-vexpress/core/tee-header_v2.bin \
    BL32_EXTRA1=../optee/optee_os/out/arm-plat-vexpress/core/tee-pager_v2.bin \
    BL32_EXTRA2=../optee/optee_os/out/arm-plat-vexpress/core/tee-pageable_v2.bin \
	BL33=../u-boot/out/u-boot.bin \
	TRUSTED_BOARD_BOOT=1 ARM_ROTPK_LOCATION=devel_rsa \
	KEY_ALG=rsa TF_MBEDTLS_KEY_ALG=rsa \
	ROT_KEY=./plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem  \
	MBEDTLS_DIR=../mbedtls GENERATE_COT=1 \
	FVP_HW_CONFIG_DTS=fdts/fvp-foundation-gicv3-psci.dts \
	FVP_USE_GIC_DRIVER=FVP_GICV3 \
	dtbs all fip;


arm-tf.build: 
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd arm-tf; \
	make -j 16 PLAT=fvp ARCH=aarch64 DEBUG=1 \
	ARM_TSP_RAM_LOCATION=dram BL33=../u-boot/out/u-boot.bin \
	TRUSTED_BOARD_BOOT=1 ARM_ROTPK_LOCATION=devel_rsa \
	KEY_ALG=rsa TF_MBEDTLS_KEY_ALG=rsa \
	ROT_KEY=./plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem  \
	MBEDTLS_DIR=../mbedtls GENERATE_COT=1 \
	FVP_HW_CONFIG_DTS=fdts/fvp-foundation-gicv3-psci.dts \
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
	make O=out/ -j16 Image dtbs

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


run:
	$(MODEL) --arm-v8.0 \
	--cores=4 \
	--secure-memory \
	--visualization \
	--gicv3 \
	--data=arm-tf/build/fvp/debug/bl1.bin@0x0 \
	--data=arm-tf/build/fvp/debug/fip.bin@0x8000000 \
	--data=linux/out/arch/arm64/boot/Image@0x80080000 \
	--data=ramdisk/ramdisk.img@0x84000000 \

ds5:
	@echo "Model params in DS-5:"
	@echo $(MODEL) --arm-v8.0 \
	--cores=1 \
	--secure-memory \
	--visualization \
	--gicv3 \
	--data=$(TOP_DIR)/arm-tf/build/fvp/debug/bl1.bin@0x0 \
	--data=$(TOP_DIR)/arm-tf/build/fvp/debug/fip.bin@0x8000000 \
	--data=$(TOP_DIR)/linux/out/arch/arm64/boot/Image@0x80080000 \
	--data=$(TOP_DIR)/ramdisk/ramdisk.img@0x84000000 
	@echo "\r\nDebug symbol in DS-5:"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl1/bl1.elf\" EL3:0"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl31/bl31.elf\" EL3:0"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl2/bl2.elf\" EL1S:0"
	@echo "add-symbol-file \"$(TOP_DIR)/linux/out/vmlinux\" EL2N:0"
