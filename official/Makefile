
# console output colors
export ERROR := "\e[31m"
export WARN := "\e[33m"
export NORMAL := "\e[32m"
export RESET := "\e[0m"

export ARCH_NAME ?= riscv64
export SIMPLE_ARCH_NAME ?= rv
export LIB_NAME ?= glibc
export TEST_STAGE ?= pre-2025

IMG_DIR 	 	:= img
TEST_IMG_DIR 	:= tmp-img
TARGET_IMG_GZ   := $(IMG_DIR)/$(TEST_STAGE)/sdcard-$(SIMPLE_ARCH_NAME).img.gz
TEST_IMG     	:= $(TEST_IMG_DIR)/fs-$(ARCH_NAME).img
USER_QEMU    	:= $(shell which qemu-$(ARCH_NAME))

all: check

check:
	@if [ ! -f $(TARGET_IMG_GZ) ]; then \
		echo -e $(ERROR)"Error: $(TARGET_IMG_GZ) not found."$(RESET); \
		echo -e $(ERROR)"Make sure you have pulled the repository correctly and are using the correct image name."$(RESET); \
		exit 1; \
	fi
	@echo -e $(NORMAL)"Found $(TARGET_IMG_GZ)."$(RESET)

clean:
	rm -rf $(TEST_IMG_DIR)

help:
	@echo -e $(WARN)"Usage: make [target]"$(RESET)
	@echo -e $(WARN)"'*' is represent in common use."$(RESET)
	@echo -e ""
	@echo -e $(NORMAL)"Targets:"$(RESET)
	@echo -e $(NORMAL)" *all        Check test images."$(RESET)
	@echo -e $(NORMAL)"  check      Check if the test image exists."$(RESET)
	@echo -e $(NORMAL)"  clean      Clean up temporary files."$(RESET)
	@echo -e $(NORMAL)"  help       Show this help message."$(RESET)

.PHONY: all mount umount clean help