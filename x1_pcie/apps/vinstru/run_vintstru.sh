#!/bin/sh
./set_fpga_led 15 # turn on the PL LED
./get_fpga_version
./set_register 15 256
./get_register 15
./set_pulse_params 10000 800 +30000 3000 # period, width, pulse amplitude, noise amplitude
./enable_pulse
./capture_waveform
./read_vinstru_bram 2000 > junk.txt
./set_fpga_led 0 # turn off the PL LED




