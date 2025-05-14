# NoAxiom-OS-Test Makefile

# console output colors
export ERROR := "\e[31m"
export WARN := "\e[33m"
export NORMAL := "\e[32m"
export RESET := "\e[0m"

# general config
export ARCH_NAME ?= riscv64
export LIB_NAME  ?= musl
export TEST_TYPE ?= official

ifeq ($(TEST_TYPE),official)
	TARGET_DIR = ./official
else
	TARGET_DIR = ./custom
endif

RAW_FS_IMG := $(TEST_TYPE)/img/$(ARCH_NAME)-$(LIB_NAME).img

$(RAW_FS_IMG):
	@cd $(TARGET_DIR) && make all

all: $(RAW_FS_IMG)
	@echo -e $(NORMAL)"NoAxiom-OS Test Suite Complete."$(RESET)

trace:
	@cd $(TARGET_DIR) && make trace
	@echo -e $(NORMAL)"see $(TARGET_DIR)/trace for trace result"$(RESET)

clean:
	@cd $(TARGET_DIR) && make clean

.PHONY: all doc