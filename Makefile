PLATFORM = linux

default:
	$(MAKE) -C src/lua/src $(PLATFORM)
	$(MAKE) -C src
