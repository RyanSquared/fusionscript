PLATFORM = linux

.PHONY: clean default

clean:
	$(MAKE) -C src clean

default:
	$(MAKE) -C src
