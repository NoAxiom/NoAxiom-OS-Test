
# console output colors
export ERROR := "\e[31m"
export WARN := "\e[33m"
export NORMAL := "\e[32m"
export RESET := "\e[0m"

export ARCH_NAME ?= loongarch64

TARGET_IMG := img/fs-$(ARCH_NAME).img

all:
	@echo $(NORMAL)"NoAxiom-OS Test Suite"$(RESET)
	mkdir -p tmp
	mkdir -p img
	wget -O tmp/sdcard-la.img.gz https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250407/sdcard-la.img.gz
	wget -O tmp/sdcard-rv.img.gz https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250407/sdcard-rv.img.gz
	gunzip tmp/sdcard-la.img.gz
	gunzip tmp/sdcard-rv.img.gz
	mv tmp/sdcard-la.img img/sdcard-la.img
	mv tmp/sdcard-rv.img img/sdcard-rv.img
	rm -rf tmp

doc: 
	git clone https://github.com/oscomp/oskernel-testsuits-cooperation.git ./doc

mount:
	mkdir -p ./mnt
	mountpoint -q ./mnt || sudo mount -t ext4 $(TARGET_IMG) ./mnt
	@echo -e $(NORMAL)"Mounting $(TARGET_IMG) to mnt succeed!"$(RESET)

umount:
	sudo umount ./mnt
	rm -rf ./mnt

USER_QEMU := $(shell which qemu-$(ARCH_NAME))
TEST_POINT := 
TEST_POINT += busybox_testcode.sh
TEST_RUNBASE += sudo $(USER_QEMU) ./busybox

list:
	@cd mnt/glibc && $(TEST_RUNBASE) ls

trace: mount
	@echo -e $(WARN)"Make sure that the img is right at LA arch!"$(RESET)
	mkdir -p ./trace
	@cd mnt/glibc && \
	for test in $(TEST_POINT); do \
		$(TEST_RUNBASE) sh $$test > ../../trace/$(ARCH_NAME)-$$test.txt; \
		echo -e $(NORMAL)"Generate $$test trace done."$(RESET); \
	done

clean:
	rm -rf tmp

.PHONY: all clean mount umount trace