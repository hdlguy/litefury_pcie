ALL_EXE = get_fpga_version set_fpga_led read_vinstru_bram write_vinstru_bram set_pulse_params \
enable_pulse disable_pulse capture_waveform set_register get_register bram2json get_sysmon get_xadc

all: $(ALL_EXE) 

CC=gcc
CFLAGS=-I. -I../ -Wall

DEPS = Makefile ../fpga.h 

# $@ = target file name, $^ = all prerequisites, $< = first prerequisite

%: %.c $(DEPS)
	$(CC) -g -o $@ $< $(CFLAGS)

clean:
	rm -rf $(ALL_EXE) 


