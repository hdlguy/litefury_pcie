// a virtual signal source
module vsource (
    //
    input   logic               clk,
    input   logic               enable,
    //
    input   logic[15:0]         pulse_period,
    input   logic[15:0]         pulse_width,
    input   logic[15:0]         pulse_amplitude,
    input   logic[15:0]         noise_amplitude,
    //
    output  logic               trig_out,
    output  logic               dv_out,
    output  logic[17:0]         d_out
);

    localparam int frame_length = 1024;

    // make 1/8 heartbeat so we can use the iir_filter
    logic heartbeat=0;
    logic[2:0] heart_count=0;
    always_ff @(posedge clk) begin
        heart_count <= heart_count - 1;
        heartbeat <= (0 == heart_count);
    end


    // make a periodic pulse
    logic[15:0] period_count=-1;
    logic period_tc=0;
    always_ff @(posedge clk) begin
        if (enable) begin
            if (heartbeat) begin
                if (period_count == 0) begin
                    period_count <= pulse_period;
                    period_tc <= 1;
                end else begin
                    period_count <= period_count - 1;
                    period_tc <= 0;
                end
            end
        end else begin
            period_count <= pulse_period;
            period_tc <= 0;
        end   
    end
    assign trig_out = period_tc;
    
    
    // generate pulse
    logic[15:0] pulse_count=-1;  
    logic[17:0] pulse=0;  
    always_ff @(posedge clk) begin
    
        if (enable) begin
        
            if (heartbeat) begin        
                if (period_tc) begin
                    pulse_count <= pulse_width;
                end else begin
                    if (pulse_count == 0) begin
                        pulse <= 0;
                    end else begin
                        pulse_count <= pulse_count - 1;
                        pulse <= $signed(pulse_amplitude);
                    end
                end
            end
            
        end else begin
        
            pulse_count <= pulse_width;
            pulse <= 0;
            
        end
        
    end

    
    // generate noise
    // output is signed fixed <16,11> = 5.11 format. with standard deviation = 1.0.
    logic[7:0] del_reset = 8'hff;
    always_ff @(posedge clk) del_reset <= {1'b0, del_reset[7:1]};
    logic noise_dv_out;
    logic[15:0] noise_data_out;
    gng #( .INIT_Z1(64'd5030521883283424767), .INIT_Z2(64'd18445829279364155008), .INIT_Z3(64'd18436106298727503359))
        u_gng (.clk(clk), .rstn(~del_reset[0]), .ce(heartbeat), .valid_out(noise_dv_out), .data_out(noise_data_out));
        
        
    // adjust the noise amplitude
    logic[31:0] noise_prod=0;
    logic[15:0] noise_scaled;
    always_ff @(posedge clk) begin
        noise_prod <= $signed(noise_amplitude) * $signed(noise_data_out);
    end
    assign noise_scaled = noise_prod[11+:16]; // grab bits so that noise_amplitude of 1 gives standard deviation equal to 1 count. 
    
                
    // sum pulse and noise
    logic[17:0] sum_data=0;
    always_ff @(posedge clk) begin
        if (noise_dv_out) sum_data <= $signed(pulse) + $signed(noise_scaled);
    end
    
   
    // iir filter
    localparam int  Ncint  = 3;
    localparam int  Ncwidth = 18;
    localparam int  Ncfrac = Ncwidth - Ncint;
    localparam int  Nsos = 5;
    localparam real coeff[0:Nsos-1][0:5] =  '{
        '{ +0.002563476562, +0.005401611328, +0.002838134766, +1.000000000000, -1.803985595703, +0.813781738281 },
        '{ +0.002563476562, +0.005279541016, +0.002716064453, +1.000000000000, -1.818359375000, +0.828460693359 },
        '{ +0.002563476562, +0.005126953125, +0.002563476562, +1.000000000000, -1.852111816406, +0.862365722656 },
        '{ +0.002563476562, +0.004974365234, +0.002410888672, +1.000000000000, -1.899139404297, +0.909576416016 },
        '{ +0.002563476562, +0.004882812500, +0.002319335938, +1.000000000000, -1.957031250000, +0.967803955078 }
    };
    logic[17:0] filt_d_out;
    logic filt_dv_out;
    iir_filter #(.Ncint(Ncint), .Ncfrac(Ncfrac), .Nsos(Nsos), .coeff(coeff)) filter_inst (.clk(clk), .dv_in(heartbeat), .d_in(sum_data), .dv_out(filt_dv_out), .d_out(filt_d_out));

    assign dv_out = filt_dv_out;
    assign d_out = filt_d_out;

endmodule




