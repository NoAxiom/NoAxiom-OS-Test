
# console output colors
export ERROR := "\e[31m"
export WARN := "\e[33m"
export NORMAL := "\e[32m"
export RESET := "\e[0m"

export ARCH_NAME ?= riscv64
export LIB_NAME ?= glibc

TARGET_IMG := img/fs-$(ARCH_NAME).img
USER_QEMU := $(shell which qemu-$(ARCH_NAME))

# test points
TEST_POINT := 
TEST_POINT += busybox_testcode.sh
TEST_RUNBASE += sudo $(USER_QEMU) ./busybox

# maybe need to modify(now disable)
MODIFIED_FILE := 
# MODIFIED_FILE += busybox_cmd.txt
# MODIFIED_FILE += busybox_testcode.sh

all: $(TARGET_IMG)

download:
	mkdir -p tmp
	wget -O tmp/sdcard-la.img.gz https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250513/sdcard-la.img.gz
	wget -O tmp/sdcard-rv.img.gz https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250513/sdcard-rv.img.gz

tmp/sdcard-la.img: tmp/sdcard-la.img.gz
	gunzip tmp/sdcard-la.img.gz

tmp/sdcard-rv.img: tmp/sdcard-rv.img.gz
	gunzip tmp/sdcard-rv.img.gz

img/fs-loongarch64.img: tmp/sdcard-la.img
	mkdir -p img
	mv tmp/sdcard-la.img img/fs-loongarch64.img

img/fs-riscv64.img: tmp/sdcard-rv.img
	mkdir -p img
	mv tmp/sdcard-rv.img img/fs-riscv64.img

# images: 
# 	make mount ARCH_NAME=riscv64
# 	sudo python3 images.py glibc
# 	mv -f img/glibc.img img/riscv64-glibc.img
# 	sudo python3 images.py musl
# 	mv -f img/musl.img img/riscv64-musl.img
# 	make umount
# 	make mount ARCH_NAME=loongarch64
# 	sudo python3 images.py glibc
# 	mv -f img/glibc.img img/loongarch64-glibc.img
# 	sudo python3 images.py musl
# 	mv -f img/musl.img img/loongarch64-musl.img
# 	make umount

doc: 
	git clone https://github.com/oscomp/oskernel-testsuits-cooperation.git ./doc

mount:
	mkdir -p ./mnt
	mountpoint -q ./mnt || sudo mount -t ext4 $(TARGET_IMG) ./mnt
	@echo -e $(NORMAL)"Mount $(TARGET_IMG) to mnt succeed!"$(RESET)

umount:
	sudo umount ./mnt
	rm -rf ./mnt

list: mount
	@cd mnt && $(TEST_RUNBASE) ls

trace: mount
	mkdir -p ./trace
	@cd mnt && \
	for modify in $(MODIFIED_FILE); do \
		$(TEST_RUNBASE) sed -i 's/\.\/busybox/busybox/g' $$modify; \
	done; \
	for test in $(TEST_POINT); do \
		$(TEST_RUNBASE) \
		sh -c "strace -f -o ../trace/$(ARCH_NAME)-strace-$$test.txt \
		sh $$test > ../trace/$(ARCH_NAME)-$$test.txt"; \
		echo -e $(NORMAL)"Generate $$test trace done."$(RESET); \
	done
	make umount

clean:
	rm -rf trace
	rm -rf tmp
	mountpoint -q ./mnt && make umount

help:
	@echo -e $(WARN)"Usage: make [target]"$(RESET)
	@echo -e $(WARN)"'*' is represent in common use."$(RESET)
	@echo -e ""
	@echo -e $(NORMAL)"Targets:"$(RESET)
	@echo -e $(NORMAL)"  all        Download and extract test images."$(RESET)
	@echo -e $(NORMAL)"  mount      Mount the image to ./mnt."$(RESET)
	@echo -e $(NORMAL)"  umount     Unmount the image from ./mnt."$(RESET)
	@echo -e $(NORMAL)" *trace      Run tests and generate trace files."$(RESET)
	@echo -e $(NORMAL)"  clean      Clean up temporary files."$(RESET)
	@echo -e $(NORMAL)"  help       Show this help message."$(RESET)

.PHONY: all images clean mount umount trace help download