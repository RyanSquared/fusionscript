PLATS = aix bsd c89 freebsd generic linux macosx mingw posix solaris

.PHONY: clean default

default:
	$(MAKE) -C src

$(PLATS):
	$(MAKE) -C src/lua/src $@

clean:
	$(MAKE) -C src/lua/src clean
	$(MAKE) -C src clean

