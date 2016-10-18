PLATFORM = linux

clean:
	$(MAKE) -C src/lua/src clean

default:
	$(MAKE) -C src/lua/src $(PLATFORM)
	$(MAKE) -C src
