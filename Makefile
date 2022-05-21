.PHONY: all testcase clean test

all: libmini.so


libmini.so:  libmini64.o libmini.o
	ld -shared -o libmini.so libmini64.o libmini.o

libmini64.o: libmini64.asm
	yasm -f elf64 -DYASM -D__x86_64__ -DPIC libmini64.asm -o libmini64.o

libmini.o: libmini.c
	gcc -c -g -Wall -fno-stack-protector -fPIC -nostdlib libmini.c


testcase: start.o write1 alarm1 alarm2 test testorigin

start.o: start.asm
	yasm -f elf64 -DYASM -D__x86_64__ -DPIC start.asm -o start.o

test: test.c
	gcc -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI test.c
	ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o test test.o start.o -L. -L.. -lmini
	rm test.o

write1: write1.c
	gcc -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI write1.c
	ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o write1 write1.o start.o -L. -L.. -lmini
	rm write1.o

alarm1: alarm1.c
	gcc -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI alarm1.c
	ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o alarm1 alarm1.o start.o -L. -L.. -lmini
	rm alarm1.o

alarm2: alarm2.c
	gcc -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI alarm2.c
	ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o alarm2 alarm2.o start.o -L. -L.. -lmini
	rm alarm2.o

alarm3: alarm3.c
	gcc -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI alarm3.c
	ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.3 -o alarm3 alarm3.o start.o -L. -L.. -lmini
	rm alarm3.o
jmp1: jmp1.c
	gcc -o jmp1.o -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI jmp1.c
	ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o jmp1 jmp1.o start.o -L. -L.. -lmini
	rm jmp1.o

testorigin: testorigin.c
	gcc -g -Wall -o testorigin testorigin.c 

clean: 
	rm -f libmini.so
	rm -f libmini64.o
	rm -f libmini.o
	rm -f write1
	rm -f alarm1
	rm -f alarm2
	rm -f alarm3
	rm -f jmp1
	rm -f test
	rm -f testorigin
	