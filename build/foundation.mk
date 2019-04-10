MODEL  ?= Foundation_Platform
TFTF   ?= 0
TTBR   ?= 1

ifeq ($(TFTF), 1)
TARGETS = tftf 
else
TARGETS = u-boot 
endif
ifeq ($(OPTEE), 1)
TARGETS += optee
endif 

TARGETS += arm-tf 

ifeq ($(TFTF), 0)
TARGETS += linux busybox ramdisk
endif

JOBS 			= 4
TOP_DIR 		= $(shell pwd)
MK_INC_DIR		= $(TOP_DIR)/tools/build/inc/
TARGETS = u-boot arm-tf linux busybox ramdisk 

UBOOT_CONFIG 	= vexpress_aemv8a_semi_config 
TF_CONFIG    	= PLAT=fvp \
				  FVP_HW_CONFIG_DTS=fdts/fvp-foundation-gicv3-psci.dts \

include ${MK_INC_DIR}cmn.mk
include ${MK_INC_DIR}u-boot.mk
include ${MK_INC_DIR}tftf.mk
include ${MK_INC_DIR}optee.mk
include ${MK_INC_DIR}arm-tf.mk
include ${MK_INC_DIR}linux.mk
include ${MK_INC_DIR}busybox.mk
include ${MK_INC_DIR}ramdisk.mk

MODEL_PARAMS = --arm-v8.0 \
	--secure-memory \
	--visualization \
	--gicv3 \
	--data=$(TOP_DIR)/arm-tf/build/fvp/debug/bl1.bin@0x0 \
	--data=$(TOP_DIR)/arm-tf/build/fvp/debug/fip.bin@0x8000000 \
	--data=$(TOP_DIR)/linux/out/arch/arm64/boot/Image@0x80080000 \
	--data=$(TOP_DIR)/ramdisk/ramdisk.img@0x84000000 


run:
	$(MODEL) $(MODEL_PARAMS)  \
	--cores=4 \

ds5:
	@echo "Model params in DS-5:"
	@echo $(MODEL)  \
	--cores=1  $(MODEL_PARAMS) \
	@echo ""
	@echo "\r\nDebug symbol in DS-5:"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl1/bl1.elf\" EL3:0"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl31/bl31.elf\" EL3:0"
	@echo "add-symbol-file \"$(TOP_DIR)/arm-tf/build/fvp/debug/bl2/bl2.elf\" EL1S:0"
	@echo "add-symbol-file \"$(TOP_DIR)/linux/out/vmlinux\" EL2N:0"
