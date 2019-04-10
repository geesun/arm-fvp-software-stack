ramdisk.build:
	cd ramdisk ; \
	cp $(BUSYBOX_BIN) . ;\
	$(CPIO_BIN) files.txt > ramdisk-busybox.img ;\
	$(MK_IMG) -A arm64 -O linux -C none -T ramdisk -n ramdisk -a 0x88000000 -e 0x88000000 -n "BusyBox ramdisk" -d ramdisk-busybox.img ramdisk.img

ramdisk.clean:
	rm ramdisk/busybox ramdisk/*.img -rf

