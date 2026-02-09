ALL_EXE = test
all: $(ALL_EXE) 

CC=gcc
CFLAGS=-I. -I../ -Wall

DEPS = Makefile ../fpga.h

# $@ = target file name, $^ = all prerequisites, $< = first prerequisite

%: %.c $(DEPS)
	$(CC) -g -o $@ $< $(CFLAGS)

clean:
	rm -rf $(ALL_EXE) 


