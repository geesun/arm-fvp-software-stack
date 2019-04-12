ifeq ($(TFTF), 1)

BL33 = $(TOP_DIR)/tftf/build/fvp/debug/tftf.bin

tftf.build:
	export CROSS_COMPILE=$(CROSS_COMPILE) ; \
	cd tftf; \
	make tftf DEBUG=1 TESTS=$(TFTF_TEST)

tftf.clean:
	rm tftf/build -rf 

endif
