# NoAxiom-OS-Test Makefile

# console output colors
export ERROR := "\e[31m"
export WARN := "\e[33m"
export NORMAL := "\e[32m"
export RESET := "\e[0m"

# general config
export ARCH_NAME ?= riscv64
export SIMPLE_ARCH_NAME ?= rv
export TEST_TYPE ?= official
export TEST_STAGE ?= pre-2025

ifeq ($(TEST_TYPE),official)
	TARGET_DIR = ./official
else
	echo -e $(ERROR)"Unsupported TEST_TYPE: $(TEST_TYPE). Defaulting to 'official'."$(RESET)
	TARGET_DIR = ./official
endif

# fs img config
TEST_DIR 	  	:= $(shell pwd)
FS_IMG_GZ_DIR 	:= $(TEST_DIR)/$(TEST_TYPE)/img/$(TEST_STAGE)
FS_IMG_GZ     	:= $(FS_IMG_GZ_DIR)/sdcard-$(SIMPLE_ARCH_NAME).img.gz
TEST_IMG_DIR 	:= $(TEST_DIR)/$(TEST_TYPE)/tmp-img
TEST_IMG 		:= $(TEST_IMG_DIR)/fs-$(SIMPLE_ARCH_NAME)-$(TEST_STAGE).img
EXTRACT_SCRIPT 	:= $(TEST_DIR)/utils/extract.sh

all: check
	@echo -e $(NORMAL)"NoAxiom-OS Test Suite Complete."$(RESET)

check: 
	@cd $(TEST_DIR)/$(TEST_TYPE) && $(MAKE) check
	@if [ ! -f $(TEST_IMG) ]; then \
		echo -e $(NORMAL)"This is your first run, extracting..."$(RESET); \
		$(MAKE) extract; \
	fi

extract: $(FS_IMG_GZ)
	@echo -e $(NORMAL)"Extracting... Make sure you have gunzip installed."$(RESET)
	@mkdir -p $(TEST_IMG_DIR)
	@$(EXTRACT_SCRIPT) $(FS_IMG_GZ) $(TEST_IMG)
	@echo -e $(NORMAL)"Extraction complete."$(RESET)

mount: extract
	mkdir -p ./mnt
	mountpoint -q ./mnt || sudo mount -t ext4 $(TEST_IMG) ./mnt
	@echo -e $(NORMAL)"Mount $(TEST_IMG) to mnt succeed!"$(RESET)

umount:
	sudo umount ./mnt
	rm -rf ./mnt

git-update:
	@echo -e $(NORMAL)"Updating git submodules..."$(RESET)
	git submodule sync
	git submodule update --init --recursive
	@echo -e $(NORMAL)"Git submodules updated."$(RESET)

clean:
	@cd $(TARGET_DIR) && make clean
	mountpoint -q ./mnt && make umount

.PHONY: all check clean