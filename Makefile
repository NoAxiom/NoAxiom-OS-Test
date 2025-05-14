# NoAxiom-OS-Test Makefile

# console output colors
export ERROR := "\e[31m"
export WARN := "\e[33m"
export NORMAL := "\e[32m"
export RESET := "\e[0m"

# general config
export ARCH_NAME ?= riscv64
export LIB_NAME  ?= glibc
export TEST_TYPE ?= official

ifeq ($(TEST_TYPE),official)
	TARGET_DIR = ./official
else
	TARGET_DIR = ./custom
endif

# fs img config
TEST_DIR ?= $(shell pwd)
RAW_FS_IMG ?= $(TEST_TYPE)/img/$(ARCH_NAME)-$(LIB_NAME).img
FS_IMG_DIR ?= $(TEST_DIR)/$(TEST_TYPE)/tmp-img
FS_IMG ?= $(TEST_TYPE)/tmp-img/$(ARCH_NAME)-$(LIB_NAME).fs.img

CHECKER_PY ?= $(TEST_DIR)/utils/checker.py
check: $(FS_IMG)
	@python3 $(CHECKER_PY) check_or_copy --src $(RAW_FS_IMG) --dest $(FS_IMG)

$(FS_IMG): $(RAW_FS_IMG)
	@mkdir -p $(FS_IMG_DIR)
	@cp $(RAW_FS_IMG) $(FS_IMG)

$(RAW_FS_IMG):
	@cd $(TARGET_DIR) && make all

trace:
	@cd $(TARGET_DIR) && make trace
	@echo -e $(NORMAL)"see $(TARGET_DIR)/trace for trace result"$(RESET)

clean:
	@cd $(TARGET_DIR) && make clean

.PHONY: trace clean check