# NoAxiom-OS-Test Makefile

# console output colors
export ERROR := "\e[31m"
export WARN := "\e[33m"
export NORMAL := "\e[32m"
export RESET := "\e[0m"

# general config
export ARCH_NAME ?= riscv64
export TEST_TYPE ?= Official

ROOT = $(shell pwd)

ifeq ($(TEST_TYPE),Official)
	TARGET_DIR = $(ROOT)/official
else
	TARGET_DIR = $(ROOT)/custom
endif

TARGET_LA := $(TARGET_DIR)/img/sdcard-la.img
TARGET_RV := $(TARGET_DIR)/img/sdcard-rv.img

KERNEL_IMG_LA := fs-loongarch64.img
KERNEL_IMG_RV := fs-riscv64.img
KERNEL_IMG := $(KERNEL_IMG_LA) $(KERNEL_IMG_RV)

$(TARGET_LA) $(TARGET_RV):
	@echo $(TEST_TYPE)
	@cd $(TARGET_DIR) && make all

$(KERNEL_IMG): $(TARGET_LA) $(TARGET_RV)
	@cp $(TARGET_LA) $(KERNEL_IMG_LA)
	@cp $(TARGET_RV) $(KERNEL_IMG_RV)

all: $(KERNEL_IMG)
	@echo -e $(NORMAL)"NoAxiom-OS Test Suite Complete."$(RESET)

trace:
	@cd $(TARGET_DIR) && make trace
	@echo -e $(NORMAL)"see ./official/trace for trace result"$(RESET)

clean:
	@cd $(TARGET_DIR) && make clean

.PHONY: all doc