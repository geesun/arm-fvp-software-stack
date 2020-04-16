CROSS_COMPILE 	?= aarch64-linux-gnu- 
CROSS_COMPILE_M ?= arm-none-eabi-
MODEL 			?= FVP_CSS_SGI-575/models/Linux64_GCC-4.8/FVP_CSS_SGI-575
MODEL_CONFIG	?= FVP_CSS_SGI-575/models/Linux64_GCC-4.8/SGI-575_cmn600.yml

TOP_DIR = $(shell pwd)
CROSS_COMPILE_DIR=$(dir $(CROSS_COMPILE))
SHELL = /bin/bash 

TARGETS = scp arm-tf linux busybox ramdisk  grub

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
	make PRODUCT=sgi575 MODE=debug  CC=$(CROSS_COMPILE_M)gcc

scp.clean:
	rm scp/build -rf 

uefi.build:
	export PACKAGES_PATH=:$(TOP_DIR)/uefi/edk2:$(TOP_DIR)/uefi/edk2/edk2-platforms: ;\
    export GCC5_AARCH64_PREFIX=$(CROSS_COMPILE) ;\
    export WORKSPACE=$(TOP_DIR)/uefi/edk2 ;\
	cd uefi/edk2 ; \
	source edksetup.sh ; \
	make -C BaseTools ; \
    build -n 32 -a AARCH64 -t GCC5 -p Platform/ARM/SgiPkg/SgiPlatform.dsc -b DEBUG -D EDK2_OUT_DIR=Build/ArmSgi -D FIRMWARE_VER=c0b1f749ef-dirty

uefi.clean:
	cd uefi/edk2 ; \
	PATH="$$PATH:$(CROSS_COMPILE_DIR)" ; \
	source edksetup.sh ; \
	make -C BaseTools clean; \
	rm -rf Build/ArmSgi ; 

arm-tf.build: 
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd arm-tf; \
	make -j 16 PLAT=sgi575 ARCH=aarch64 DEBUG=1 \
	ARM_TSP_RAM_LOCATION=dram BL33=../uefi/edk2/Build/ArmSgi/DEBUG_GCC5/FV/BL33_AP_UEFI.fd \
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
	make O=out/ defconfig ;\
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
	../linux/out/usr/gen_init_cpio files.txt > ramdisk.img ;\

ramdisk.clean:
	rm ramdisk/busybox ramdisk/*.img -rf

grub.build: 
	cd grub; \
	mkdir -p out ;\
    echo "set prefix=(\$$root)/grub/" >out/sgi575.cfg ;\
	PATH="$$PATH:$(CROSS_COMPILE_DIR)" ; \
	if [ ! -f Makefile ] ; then \
		./autogen.sh ; \
		./configure STRIP=aarch64-linux-gnu-strip --target=aarch64-linux-gnu --with-platform=efi --prefix=$(TOP_DIR)/grub/out/ --disable-werror  CFLAGS="-g" LDFLAGS="-g"; \
	fi ;\
    make -j8 install ;\
    out/bin/grub-mkimage -v -c out/sgi575.cfg -o out/bootaa64.efi -O arm64-efi -p  part_gpt part_msdos ntfs ntfscomp hfsplus fat ext2 normal chain boot configfile linux help part_msdos terminal terminfo configfile lsefi search normal gettext loadenv read search_fs_file search_fs_uuid search_label
	cd grub/out ; \
	IMG_BB=grub-busybox.img ; \
	BLOCK_SIZE=512 ;  \
	SEC_PER_MB=$$((1024*2)) ; \
	FAT_SIZE_MB=20 ; \
	EXT3_SIZE_MB=200 ;\
	PART_START=$$((1*SEC_PER_MB)) ;\
	FAT_SIZE=$$((FAT_SIZE_MB*SEC_PER_MB-(PART_START))) ;\
	EXT3_SIZE=$$((EXT3_SIZE_MB*SEC_PER_MB-(PART_START))) ;\
	rm -f $$IMG_BB ;\
	dd if=/dev/zero of=fat_part bs=512 count=38912 ;\
	mkfs.vfat fat_part ;\
	mmd -i fat_part ::/EFI ;\
	mmd -i fat_part ::/EFI/BOOT ;\
	mmd -i fat_part ::/grub ;\
	mcopy -i fat_part bootaa64.efi ::/EFI/BOOT ;\
	dd if=/dev/zero of=$$IMG_BB bs=$$BLOCK_SIZE count=$$PART_START ;\
	echo "set debug=\"loader,mm\"" > grub.cfg ;\
	echo "set term=\"vt100\"" >>grub.cfg ;\
	echo "set default=\"0\""  >>grub.cfg ; \
	echo "set timeout=\"1\"" >> grub.cfg; \
	echo "set root=(hd1,msdos2)" >>grub.cfg ;\
	echo "menuentry 'Arm SGI575' {" >>grub.cfg ; \
	echo "        linux /Image acpi=force console=ttyAMA0,115200 ip=dhcp root=/dev/vda2 rootwait verbose debug" >> grub.cfg ;\
	echo "	 initrd /ramdisk-busybox.img " >> grub.cfg ;\
	echo "}" >> grub.cfg ; \
	mcopy -i fat_part -o grub.cfg ::/grub/grub.cfg ;\
	dd if=/dev/zero of=ext3_part bs=$$BLOCK_SIZE count=$$EXT3_SIZE ;\
	mkdir -p mnt ;\
	if [[ $$(findmnt -M "mnt") ]]; then \
    	fusermount -u mnt ;\
	fi; \
	mkfs.ext3 -F ext3_part ;\
	fuse-ext2 ext3_part mnt -o rw+ ;\
	cp $(TOP_DIR)/linux/out/arch/arm64/boot/Image ./mnt ;\
	cp $(TOP_DIR)/ramdisk/ramdisk.img ./mnt/ramdisk-busybox.img ;\
	sync ;\
	fusermount -u mnt ;\
	cat fat_part >>$$IMG_BB ;\
	cat ext3_part >>$$IMG_BB ;\
	(echo n; echo p; echo 1; echo $$PART_START; echo +$$((FAT_SIZE-1)); echo t; echo 6; echo n; echo p; echo 2; echo $$((PART_START+FAT_SIZE)); echo +$$(($$EXT3_SIZE-1)); echo w) | fdisk $$IMG_BB

	
grub.clean: 
	rm -rf grub/out/


MODEL_PARAMS= \
			  -C css.cmn600.mesh_config_file="$(MODEL_CONFIG)"  \
			  -C css.cmn600.force_on_from_start=1  \
			  -C css.mcp.ROMloader.fname="$(TOP_DIR)/scp/build/product/sgi575/mcp_romfw/debug/bin/firmware.bin" \
			  -C css.scp.ROMloader.fname="$(TOP_DIR)/scp/build/product/sgi575/scp_romfw/debug/bin/firmware.bin" \
			  -C css.trustedBootROMloader.fname="$(TOP_DIR)/arm-tf/build/sgi575/debug/bl1.bin" \
			  -C board.flashloader0.fname="$(TOP_DIR)/arm-tf/build/sgi575/debug/fip.bin" \
			  -C board.virtioblockdevice.image_path=$(TOP_DIR)/grub/out/grub-busybox.img \
			  --data css.scp.armcortexm7ct=$(TOP_DIR)/scp/build/product/sgi575/scp_ramfw/debug/bin/firmware.bin@0x0BD80000 -R
run:
	$(MODEL) $(MODEL_PARAMS)


ds5:
	@echo "Model params in DS-5:"
	@echo $(MODEL_PARAMS)
	@echo "" 
	@echo "Debug symbol in DS-5:"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl1/bl1.elf\" EL3:0"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl31/bl31.elf\" EL3:0"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl2/bl2.elf\" EL1S:0"
	@echo "add-symbol-file \"$(TOP_DIR)/linux/out/vmlinux\" EL2N:0"



