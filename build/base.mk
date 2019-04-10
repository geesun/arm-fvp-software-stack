MODEL  ?= FVP_Base_RevC-2xAEMv8A
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

UBOOT_CONFIG 	= vexpress_aemv8a_semi_config 
TF_CONFIG    	= PLAT=fvp \
				  FVP_HW_CONFIG_DTS=fdts/fvp-base-gicv3-psci-1t.dts \

include ${MK_INC_DIR}cmn.mk
include ${MK_INC_DIR}u-boot.mk
include ${MK_INC_DIR}tftf.mk
include ${MK_INC_DIR}optee.mk
include ${MK_INC_DIR}arm-tf.mk
include ${MK_INC_DIR}linux.mk
include ${MK_INC_DIR}busybox.mk
include ${MK_INC_DIR}ramdisk.mk


MODEL_PARAMS = \
			  -C pctl.startup=0.0.0.0 \
			  -C bp.secure_memory=1   \
			  -C cluster0.NUM_CORES=4 \
			  -C cluster1.NUM_CORES=4 \
			  -C cache_state_modelled=0  \
			  -C bp.pl011_uart0.untimed_fifos=1  \
			  -C bp.pl011_uart0.unbuffered_output=1  \
			  -C bp.secureflashloader.fname=$(TOP_DIR)/arm-tf/build/fvp/debug/bl1.bin \
			  -C bp.flashloader0.fname=$(TOP_DIR)/arm-tf/build/fvp/debug/fip.bin \
			  --data cluster0.cpu0=$(TOP_DIR)/ramdisk/ramdisk.img@0x84000000 \
			  --data cluster0.cpu0=$(TOP_DIR)/linux/out/arch/arm64/boot/Image@0x80080000  \
			  -C bp.ve_sysregs.mmbSiteDefault=0    \
			  -C bp.ve_sysregs.exit_on_shutdown=1 
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
	@echo "add-symbol-file \"$(TOP_DIR)/linux/out/vmlinux\" EL1N:0"


