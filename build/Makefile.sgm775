CROSS_COMPILE ?= aarch64-linux-gnu- 
MODEL ?= /usr/local/DS-5_v5.29.1/sw/models/bin/Foundation_Platform
TARGETS = u-boot arm-tf linux busybox ramdisk 

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

arm-tf.build: 
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd arm-tf; \
	make -j 16 PLAT=fvp ARCH=aarch64 DEBUG=1 \
	ARM_TSP_RAM_LOCATION=dram BL33=../u-boot/out/u-boot.bin \
	TRUSTED_BOARD_BOOT=1 ARM_ROTPK_LOCATION=devel_rsa \
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
	$(MODEL) --cores=1 --no-secure-memory --visualization --use-real-time --gicv3  \
	--data=arm-tf/build/fvp/debug/bl1.bin@0x0 \
	--data=arm-tf/build/fvp/debug/fip.bin@0x8000000 \
	--data=linux/out/arch/arm64/boot/Image@0x80080000 \
	--data=linux/out/arch/arm64/boot/dts/arm/foundation-v8-gicv3.dtb@0x82000000 \
	--data=ramdisk/ramdisk.img@0x84000000 \
	--arm-v8.0
