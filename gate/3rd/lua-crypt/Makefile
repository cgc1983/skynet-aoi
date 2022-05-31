.PHONY : all win clean

all : linux
win : crypt.dll

# For Linux
linux:
	make crypt.so "DLLFLAGS = -shared -fPIC"
	mv crypt.so ../crypt.so
# For Mac OS
macosx:
	make crypt.so "DLLFLAGS = -bundle -undefined dynamic_lookup -I/usr/local/include"
	mv crypt.so ../crypt.so

crypt.so : lua_crypt.c
	env gcc -O2 -Wall $(DLLFLAGS) -o $@ $^

crypt.dll : lua_crypt.c
	gcc -O2 -Wall --shared -o $@ $^ -I/usr/local/include -L/usr/local/bin -llua53

clean :
	rm -f crypt.so crypt.dll
