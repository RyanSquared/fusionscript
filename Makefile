PLATFORM = linux

default:
	$(MAKE) -C src/lua/src $(PLATFORM)
	$(MAKE) -C src


clean:
	$(MAKE) -C src/lua/src clean
