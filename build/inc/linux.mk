CPIO_BIN = $(TOP_DIR)/linux/out/usr/gen_init_cpio 

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
	make O=out/ -j $(JOBS) Image dtbs ; \


linux.clean:
	rm linux/out -rf 

