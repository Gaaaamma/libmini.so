.PHONY: all testcase clean test

all: libmini.so


libmini.so:  libmini64.o libmini.o
	ld -shared -o libmini.so libmini64.o libmini.o

libmini64.o: libmini64.asm
	yasm -f elf64 -DYASM -D__x86_64__ -DPIC libmini64.asm -o libmini64.o

libmini.o: libmini.c
	gcc -c -g -Wall -fno-stack-protector -fPIC -nostdlib libmini.c


testcase: start.o write1

start.o: start.asm
	yasm -f elf64 -DYASM -D__x86_64__ -DPIC start.asm -o start.o

write1: write1.c
	gcc -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI write1.c
	ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o write1 write1.o start.o -L. -L.. -lmini
	rm write1.o
	
clean: 
	rm -f libmini.so
	rm -f libmini64.o
	rm -f libmini.o
	rm -f write1

test:
	LD_LIBRARY_PATH=. ./write1
	