`timescale 1ns / 1ps

module vinstru_tb ();

    localparam int Wdata = 8;
    localparam int Wdepth = 2**10;
    
    logic               enable, run, done, reset;
    logic[15:0]         pulse_period;
    logic[15:0]         pulse_width;
    logic[15:0]         pulse_amplitude;
    logic[15:0]         noise_amplitude;
    logic               bram_clk;
    logic               bram_rst;
    logic               bram_en;
    logic[3:0]          bram_we;
    logic[11+2:0]       bram_addr;
    logic[31:0]         bram_din;
    logic[31:0]         bram_dout;    

    localparam time clk_period = 10; logic clk=0; always #(clk_period/2) clk=~clk;

    vinstru uut (.*);
    
    initial begin
    
        enable = 0;
        run = 0;
        reset = 0;
        pulse_period = 10000-1;
        pulse_width = 1000;
        pulse_amplitude = 30000;
        noise_amplitude = 3000;
        #(clk_period*1000);
        
        enable = 1;
        #(clk_period*1000);
        
        reset = 1;
        #(clk_period*10);
        
        reset = 0;
        #(clk_period*10);
        
        run = 1;
        #(clk_period*100);
        
        run = 0;
        
    end

endmodule



/*

*/
