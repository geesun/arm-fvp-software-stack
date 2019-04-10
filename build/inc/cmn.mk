TOP_DIR = $(shell pwd)

CROSS_COMPILE 	?= aarch64-linux-gnu- 
CROSS_COMPILE32 ?= arm-linux-gnueabi-
CROSS_COMPILE_M ?= arm-none-eabi-

build_TARGETS = $(foreach t,$(TARGETS),$(t).build)
clean_TARGETS = $(foreach t,$(TARGETS),$(t).clean)

all: check $(build_TARGETS)

clean: check $(clean_TARGETS)


check:
	@for d in $(TARGETS) ; do \
		if [ ! -d "$$d" ] ; then  \
			echo "$$d not exist " ; \
			exit 1;  \
		fi; \
	done


