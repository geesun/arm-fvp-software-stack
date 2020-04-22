CROSS_COMPILE 	?= aarch64-linux-gnu- 
CROSS_COMPILE_M ?= arm-none-eabi-
MODEL 			?= ~/model/FVP_RD_N1_edge/models/Linux64_GCC-4.9/FVP_RD_N1_edge
MODEL_CONFIG	?= ~/model/FVP_RD_N1_edge/models/Linux64_GCC-4.9/RD_N1_E1_cmn600.yml

TOP_DIR = $(shell pwd)
CROSS_COMPILE_DIR=$(dir $(CROSS_COMPILE))
SHELL = /bin/bash 

TARGETS = scp uefi arm-tf linux busybox ramdisk  grub

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
	make PRODUCT=rdn1e1 MODE=release  CC=$(CROSS_COMPILE_M)gcc

scp.clean:
	rm scp/build -rf 

uefi.build:
	export PACKAGES_PATH=:$(TOP_DIR)/uefi/edk2:$(TOP_DIR)/uefi/edk2/edk2-platforms: ;\
    export GCC5_AARCH64_PREFIX=$(CROSS_COMPILE) ;\
    export WORKSPACE=$(TOP_DIR)/uefi/edk2 ;\
	cd uefi/edk2 ; \
	source edksetup.sh ; \
	make -C BaseTools ; \
    build -n 32 -a AARCH64 -t GCC5 -p Platform/ARM/SgiPkg/SgiPlatform.dsc -b DEBUG -D EDK2_OUT_DIR=Build/ArmSgi -D FIRMWARE_VER=c0b1f749ef-dirty ; \
	build -n 32 -a AARCH64 -t GCC5 -p Platform/ARM/SgiPkg/PlatformStandaloneMm.dsc -b DEBUG -s -D EDK2_OUT_DIR=Build/SgiMmStandalone -D FIRMWARE_VER=e4a1bf4842 

uefi.clean:
	cd uefi/edk2 ; \
	PATH="$$PATH:$(CROSS_COMPILE_DIR)" ; \
	source edksetup.sh ; \
	make -C BaseTools clean; \
	rm -rf Build/ArmSgi ; 

arm-tf.build: 
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd arm-tf; \
	make -j 16 PLAT=rdn1edge ARCH=aarch64 DEBUG=1 \
	ENABLE_SPM=1 RAS_EXTENSION=1 SDEI_SUPPORT=1 EL3_EXCEPTION_HANDLING=1 HANDLE_EA_EL3_FIRST=1 \
	ARM_TSP_RAM_LOCATION=dram BL33=../uefi/edk2/Build/ArmSgi/DEBUG_GCC5/FV/BL33_AP_UEFI.fd \
	BL32=../uefi/edk2/Build/SgiMmStandalone/DEBUG_GCC5/FV/BL32_AP_MM.fd \
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


IMG_BB=grub-busybox.img
FAT_SIZE_MB=20
EXT3_SIZE_MB=200
PART_START=2048
FAT_SIZE=40960
EXT3_SIZE=409600

grub.build: 
	cd grub; \
	mkdir -p out ;\
    echo "set prefix=(\$$root)/grub/" >out/rde1edge.cfg ;\
	PATH="$$PATH:$(CROSS_COMPILE_DIR)" ; \
	if [ -e bootstrap ]; then \
                if [ ! -e grub-core/lib/gnulib/stdlib.in.h ]; then \
                    ./bootstrap ; \
                fi\
            fi;\
	if [ ! -e config.status ]; then \
                ./autogen.sh ;\
                ./configure STRIP=$(CROSS_COMPILE_DIR)/aarch64-linux-gnu-strip --target=aarch64-linux-gnu --with-platform=efi --prefix=$(TOP_DIR)/grub/out/ --disable-werror ; \
            fi ; \
    make -j8 install ;\
    out/bin/grub-mkimage -v -c out/rde1edge.cfg -o out/bootaa64.efi -O arm64-efi -p "" part_gpt part_msdos ntfs ntfscomp hfsplus fat ext2   normal chain boot configfile linux help part_msdos terminal terminfo configfile lsefi search normal gettext loadenv read search_fs_file search_fs_uuid  search_label 
	cd grub/out ; \
	grep -q -F 'mtools_skip_check=1' ~/.mtoolsrc || echo "mtools_skip_check=1" >> ~/.mtoolsrc ; \
	rm -f $(IMG_BB); \
	dd if=/dev/zero of=part_table bs=512 count=2048 ;\
	cat part_table > $(IMG_BB) ; \
	dd if=/dev/zero of=fat_part bs=512 count=40960 ; \
	mkfs.vfat fat_part; \
	mmd -i fat_part ::/EFI; \
 	mmd -i fat_part ::/EFI/BOOT; \
 	mmd -i fat_part ::/grub  ;\
 	mcopy -i fat_part bootaa64.efi ::/EFI/BOOT ;\
	echo "set debug=\"loader,mm\"" > grub.cfg ;\
    echo "set term=\"vt100\"" >>grub.cfg ;\
    echo "set default=\"0\""  >>grub.cfg ; \
    echo "set timeout=\"1\"" >> grub.cfg; \
	echo "search --set=root --fs-uuid 535add81-5875-4b4a-b44a-464aee5f5cbd" >>grub.cfg ;\
    echo "menuentry 'RD-N1-Edge BusyBox' {" >>grub.cfg ; \
    echo "        linux /Image acpi=force console=ttyAMA0,115200 ip=dhcp root=PARTUUID=9c53a91b-e182-4ff1-aeac-6ee2c432ae94 rootwait verbose debug" >> grub.cfg ;\
    echo "   initrd /ramdisk-busybox.img " >> grub.cfg ;\
    echo "}" >> grub.cfg ; \
	mcopy -i fat_part -o grub.cfg ::/grub/grub.cfg ;\
	cat fat_part >> $(IMG_BB) ; \
	\
	dd if=/dev/zero of=ext3_part bs=512 count=409600 ;\
	mkdir -p mnt ; \
    mkfs.ext3 -F ext3_part ; \
    tune2fs -U 535add81-5875-4b4a-b44a-464aee5f5cbd ext3_part ; \
	fuse-ext2 ext3_part mnt -o rw+ ; \
	cp $(TOP_DIR)/linux/out/arch/arm64/boot/Image ./mnt ;\
	cp $(TOP_DIR)/ramdisk/ramdisk.img ./mnt/ramdisk-busybox.img ;\
	sync ;\
	fusermount -u mnt ;\
	cat ext3_part >>$(IMG_BB) ;\
	cat part_table >> $(IMG_BB) ; \
	(echo n; echo 1; echo 2048; echo +40959; echo 0700; echo w; echo y;) | gdisk $(IMG_BB); \
    (echo n; echo 2; echo 43008; echo +409599; echo 8300; echo w; echo y;) | gdisk  $(IMG_BB); \
    (echo x; echo c; echo 2; echo 535add81-5875-4b4a-b44a-464aee5f5cbd; echo w; echo y;) | gdisk $(IMG_BB) ; \
	rm -f part_table; \
	rm -f fat_part ; \
	rm -f ext3_part ;

	
grub.clean: 
	rm -rf grub/out/


MODEL_PARAMS= \
			  -C css.cmn600.mesh_config_file="$(MODEL_CONFIG)"  \
			  -C css.cmn600.force_on_from_start=1  \
			  -C css.mcp.ROMloader.fname="$(TOP_DIR)/scp/build/product/rdn1e1/mcp_romfw/release/bin/firmware.bin" \
			  -C css.scp.ROMloader.fname="$(TOP_DIR)/scp/build/product/rdn1e1/scp_romfw/release/bin/firmware.bin" \
			  -C css.trustedBootROMloader.fname="$(TOP_DIR)/arm-tf/build/rdn1edge/debug/bl1.bin" \
			  -C board.flashloader0.fname="$(TOP_DIR)/arm-tf/build/rdn1edge/debug/fip.bin" \
			  -C board.virtioblockdevice.image_path=$(TOP_DIR)/grub/out/grub-busybox.img \
			  -C soc.pl011_uart0.out_file=- \
			  --data css.scp.armcortexm7ct=$(TOP_DIR)/scp/build/product/rdn1e1/scp_ramfw/release/bin/firmware.bin@0x0BD80000 -R 
run:
	$(MODEL) $(MODEL_PARAMS)


ds5:
	@echo "Model params in DS-5:"
	@echo $(MODEL_PARAMS)
	@echo "" 
	@echo "Debug symbol in DS-5:"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/rdn1edge/debug/bl1/bl1.elf\" EL3:0"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/rdn1edge/debug/bl31/bl31.elf\" EL3:0"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/rdn1edge/debug/bl2/bl2.elf\" EL1S:0"
	@echo "add-symbol-file \"$(TOP_DIR)/linux/out/vmlinux\" EL2N:0"



