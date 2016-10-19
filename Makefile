PLATFORM = linux

.PHONY: clean default

clean:
	$(MAKE) -C src clean
	$(MAKE) -C src/lua/src clean

default:
	$(MAKE) -C src
