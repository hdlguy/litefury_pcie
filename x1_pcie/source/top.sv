
module top (
    //
    input   logic       sysclk_p,
    input   logic       sysclk_n,
    //
    output  logic[3:0]  ledn,
    //
    input   logic       pcie_clkin_clk_n,
    input   logic       pcie_clkin_clk_p,
    input   logic[0:0]  pcie_mgt_rxn,
    input   logic[0:0]  pcie_mgt_rxp,
    output  logic[0:0]  pcie_mgt_txn,
    output  logic[0:0]  pcie_mgt_txp,
    input   logic       pcie_reset,
    output  logic       pcie_clkreq_l
);

    logic [11:0]    regfile_addr;
    logic           regfile_clk;
    logic [31:0]    regfile_din;
    logic [31:0]    regfile_dout;
    logic           regfile_en;
    logic           regfile_rst;
    logic [3:0]     regfile_we;          

    logic [13:0]    vinstru_bram_addr;
    logic           vinstru_bram_clk;
    logic [31:0]    vinstru_bram_din;
    logic [31:0]    vinstru_bram_dout;
    logic           vinstru_bram_en;
    logic           vinstru_bram_rst;
    logic [3:0]     vinstru_bram_we;    

    system system_i(
        .pcie_clkin_clk_n   (pcie_clkin_clk_n),
        .pcie_clkin_clk_p   (pcie_clkin_clk_p),
        .pcie_mgt_rxn       (pcie_mgt_rxn),
        .pcie_mgt_rxp       (pcie_mgt_rxp),
        .pcie_mgt_txn       (pcie_mgt_txn),
        .pcie_mgt_txp       (pcie_mgt_txp),
        .pcie_reset         (pcie_reset),     
        //
        .regfile_addr       (regfile_addr),
        .regfile_clk        (regfile_clk),
        .regfile_din        (regfile_din),
        .regfile_dout       (regfile_dout),
        .regfile_en         (regfile_en),
        .regfile_rst        (regfile_rst),
        .regfile_we         (regfile_we),  
        //
        .axi_aclk           (axi_aclk),
        .axi_aresetn        (axi_aresetn),
        //
        .vinstru_bram_addr  (vinstru_bram_addr),
        .vinstru_bram_clk   (vinstru_bram_clk),
        .vinstru_bram_din   (vinstru_bram_din),
        .vinstru_bram_dout  (vinstru_bram_dout),
        .vinstru_bram_en    (vinstru_bram_en),
        .vinstru_bram_rst   (vinstru_bram_rst),
        .vinstru_bram_we    (vinstru_bram_we)                
);                
    
    assign pcie_clkreq_l = 1'b0;

    logic clk;
    IBUFDS #(.DIFF_TERM("TRUE"), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("DEFAULT")) IBUFDS_inst (.O(clk), .I(sysclk_p), .IB(sysclk_n));
    
    logic[3:0] led;
    logic[27:0] led_count;
    always_ff @(posedge axi_aclk) begin
        if (pcie_reset==0) begin
            led_count <= 0;
        end else begin
            led_count <= led_count + 1;
        end
        //led <= led_count[27:24];
    end    
    assign ledn = ~led;
    
    
    logic vinstru_run, vinstru_done, vinstru_pulse_enable, vinstru_reset;
    logic[31:0] vinstru_pulse_period;
    logic[15:0] vinstru_pulse_width, vinstru_pulse_amplitude, vinstru_noise_amplitude;
    
    // This register file gives software contol over unit under test (UUT).
    localparam int Nregs = 16;
    logic [Nregs-1:0][31:0] slv_reg, slv_read;

    assign slv_read[0] = 32'hdeadbeef;
    assign slv_read[1] = 32'h76543210;
    
    assign led = slv_reg[2][3:0];
    assign slv_read[2] = slv_reg[2];

    assign vinstru_pulse_enable = slv_reg[3][0];
    assign slv_read[ 3] = slv_reg[ 3];
    
    assign vinstru_run = slv_reg[4][0];
    assign slv_read[4][3:0] = slv_reg[4][3:0];
    assign slv_read[4][4] = vinstru_done;
    assign vinstru_reset = slv_reg[4][8];
    assign slv_read[4][31:5] = slv_reg[4][31:5];
    
    assign vinstru_pulse_period = slv_reg[5];
    assign slv_read[5] = slv_reg[5];
    
    assign vinstru_pulse_width = slv_reg[6][15:0];
    assign slv_read[6] = slv_reg[6];

    assign vinstru_pulse_amplitude = slv_reg[7][15:0];    
    assign slv_read[7] = slv_reg[7];

    assign vinstru_noise_amplitude = slv_reg[8][15:0];     
    assign slv_read[8] = slv_reg[8];
    
    assign slv_read[ 9] = slv_reg[ 9];
    assign slv_read[10] = slv_reg[10];
    assign slv_read[11] = slv_reg[11];
    assign slv_read[12] = slv_reg[12];
    assign slv_read[13] = slv_reg[13];
    assign slv_read[14] = slv_reg[14];
    assign slv_read[15] = slv_reg[15];

    mem_regfile #(
       .Naddr(4)  // 16 registers
    ) mem_regfile_inst (
        .clk        (regfile_clk),
        .addr       (regfile_addr[5:2]),
        .wr_data    (regfile_din),
        .rd_data    (regfile_dout),
        .en         (regfile_en),
        .reset      (regfile_rst),
        .we         (regfile_we),
        //
        .reg_val    (slv_reg),
        .pul_val    (),
        .read_val   (slv_read)
    );


    // a virtual instrument
    vinstru vinstru_inst (
        .clk                (axi_aclk),
        .enable             (vinstru_pulse_enable),
        .reset              (vinstru_reset),
        .run                (vinstru_run),
        .done               (vinstru_done),
        .pulse_period       (vinstru_pulse_period),
        .pulse_width        (vinstru_pulse_width),
        .pulse_amplitude    (vinstru_pulse_amplitude),
        .noise_amplitude    (vinstru_noise_amplitude),
        //
        .bram_clk           (vinstru_bram_clk),
        .bram_rst           (vinstru_bram_rst),
        .bram_en            (vinstru_bram_en),
        .bram_we            (vinstru_bram_we),
        .bram_addr          (vinstru_bram_addr),
        .bram_din           (vinstru_bram_din),
        .bram_dout          (vinstru_bram_dout)
    );

endmodule

/*
*/


