.PHONY : all win clean

all : linux
win : cmsgpack.dll

# For Linux
linux:
	make cmsgpack.so "DLLFLAGS = -shared -fPIC"
	mv cmsgpack.so ../cmsgpack.so
# For Mac OS
macosx:
	make cmsgpack.so "DLLFLAGS = -bundle -undefined dynamic_lookup -I/usr/local/include"
	mv cmsgpack.so ../cmsgpack.so

cmsgpack.so : lua_cmsgpack.c
	env gcc -O2 -Wall $(DLLFLAGS) -o $@ $^

cmsgpack.dll : lua_cmsgpack.c
	gcc -O2 -Wall --shared -o $@ $^ -I/usr/local/include -L/usr/local/bin -llua53

clean :
	rm -f cmsgpack.so cmsgpack.dll
