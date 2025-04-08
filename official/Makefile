
# console output colors
export ERROR := "\e[31m"
export WARN := "\e[33m"
export NORMAL := "\e[32m"
export RESET := "\e[0m"

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

clean:
	rm -rf tmp

.PHONY: all clean 