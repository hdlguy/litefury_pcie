//
module vinstru (
    //
    input   logic               clk,
    input   logic               enable,
    //
    input   logic               reset,
    input   logic               run,
    output  logic               done,
    //
    input   logic[15:0]         pulse_period,
    input   logic[15:0]         pulse_width,
    input   logic[15:0]         pulse_amplitude,
    input   logic[15:0]         noise_amplitude,
    //
    input   logic               bram_clk,
    input   logic               bram_rst,
    input   logic               bram_en,
    input   logic[3:0]          bram_we,
    input   logic[11+2:0]       bram_addr,
    input   logic[31:0]         bram_din,
    output  logic[31:0]         bram_dout
);

    logic source_trigger, source_dv_out;
    logic[17:0] source_d_out;
    vsource vsource_inst (
        .clk                (clk),
        .enable             (enable),
        .pulse_period       (pulse_period),
        .pulse_width        (pulse_width),
        .pulse_amplitude    (pulse_amplitude),
        .noise_amplitude    (noise_amplitude),
        .trig_out           (source_trigger),
        .dv_out             (source_dv_out),
        .d_out              (source_d_out)
    );


    localparam int frame_length = 4096;

    // generate output frame
    logic[3:0] state=0, next_state;
    logic[15:0] data_count=0;
    logic data_count_clear, frame_enable;
    always_comb begin

        // defaults
        next_state = state;
        done = 0;
        data_count_clear = 0;
        frame_enable = 0;

        case (state)

            0: begin
                next_state = 1;
            end

            1: begin
                data_count_clear = 1;
                if (run) begin
                    next_state = 2;
                end
            end
            
            2: begin
                data_count_clear = 1;
                if (source_trigger) begin
                    next_state = 3;
                end
            end

            3: begin
                frame_enable = 1;
                if (data_count == frame_length) begin
                    next_state = 4;
                end
            end

            4: begin
                next_state = 5;
            end

            5: begin
                done = 1;
                if (~run) begin
                    next_state = 6;
                end
            end

            6: begin
                next_state = 1;
            end

            default: begin
                next_state = 0;
            end

        endcase

    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= 0;
        end else begin
            state <= next_state;
        end
    end



    // count the data wordspulse_period
    always_ff @(posedge clk) begin
        if (data_count_clear) begin
            data_count <= 0;
        end else begin
            if (source_dv_out) begin
                data_count <= data_count + 1;
            end
        end
    end
    
    logic[3:0] wea;
    logic[11:0] addra;
    logic[31:0] dina, douta;
    
    assign wea = {4{source_dv_out & frame_enable}};
    assign addra = data_count[11:0];
    assign dina  = $signed(source_d_out);
    
    // dual port memory
    xpm_memory_tdpram #(
        .ADDR_WIDTH_A(12),               
        .ADDR_WIDTH_B(12),               
        .AUTO_SLEEP_TIME(0),      
        .WRITE_DATA_WIDTH_A(32),        
        .WRITE_DATA_WIDTH_B(32),               
        .BYTE_WRITE_WIDTH_A(8),        
        .BYTE_WRITE_WIDTH_B(8),        
        .CASCADE_HEIGHT(0),             
        .CLOCKING_MODE("independent_clock"), 
        .ECC_BIT_RANGE("7:0"),          
        .ECC_MODE("no_ecc"),            
        .ECC_TYPE("none"),              
        .IGNORE_INIT_SYNTH(0),          
        .MEMORY_INIT_FILE("none"),      
        .MEMORY_INIT_PARAM("0"),        
        .MEMORY_OPTIMIZATION("true"),   
        .MEMORY_PRIMITIVE("auto"),      
        .MEMORY_SIZE(4096*32),             
        .MESSAGE_CONTROL(0),            
        .RAM_DECOMP("auto"),            
        .READ_DATA_WIDTH_A(32),         
        .READ_DATA_WIDTH_B(32),         
        .READ_LATENCY_A(1),             
        .READ_LATENCY_B(1),             
        .READ_RESET_VALUE_A("0"),       
        .READ_RESET_VALUE_B("0"),       
        .RST_MODE_A("SYNC"),            
        .RST_MODE_B("SYNC"),            
        .SIM_ASSERT_CHK(0),             
        .USE_EMBEDDED_CONSTRAINT(0),    
        .USE_MEM_INIT(1),               
        .USE_MEM_INIT_MMI(0),           
        .WAKEUP_TIME("disable_sleep"), 
        .WRITE_MODE_A("no_change"),     
        .WRITE_MODE_B("no_change"),     
        .WRITE_PROTECT(1)               
    ) xpm_memory_tdpram_inst (                 
        .clka   (clk),       
        .rsta   (1'b0),                       
        .ena    (1'b1),                          
        .wea    (wea),                                                  
        .addra  (addra),                                                                                                  
        .dina   (dina),                                               
        .douta  (douta),   
        //                                                                             
        .clkb   (bram_clk),           
        .rstb   (bram_rst),                   
        .enb    (bram_en),  
        .web    (bram_we),                   
        .addrb  (bram_addr[13:2]),                 
        .dinb   (bram_din),                     
        .doutb  (bram_dout),  
        //   
        .dbiterra(),                                                    
        .dbiterrb(),                    
        .sbiterra(),                                                    
        .sbiterrb(),    
        .injectdbiterra(1'b0), 
        .injectdbiterrb(1'b0), 
        .injectsbiterra(1'b0), 
        .injectsbiterrb(1'b0), 
        .regcea(1'b1),   
        .regceb(1'b1),  
        .sleep(1'b0)
    );    
    
    // debug
    vinstru_ila ila_inst (.clk(clk), .probe0({wea, addra, source_d_out, enable, state, data_count_clear, run, done, frame_enable, source_trigger})); // 44

endmodule

/*
*/

