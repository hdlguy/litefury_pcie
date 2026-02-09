
module top (
    //
    input   logic       sysclk_p,
    input   logic       sysclk_n,
    //
    output  logic[3:0]  ledn,
    //
    input   logic       pcie_clkin_clk_n,
    input   logic       pcie_clkin_clk_p,
    input   logic[3:0]  pcie_mgt_rxn,
    input   logic[3:0]  pcie_mgt_rxp,
    output  logic[3:0]  pcie_mgt_txn,
    output  logic[3:0]  pcie_mgt_txp,
    input   logic       pcie_reset,
    output  logic       pcie_clkreq_l
);
    
    logic [31:0]    M00_AXI_araddr;
    logic [2:0]     M00_AXI_arprot;
    logic           M00_AXI_arready;
    logic           M00_AXI_arvalid;
    logic [31:0]    M00_AXI_awaddr;
    logic [2:0]     M00_AXI_awprot;
    logic           M00_AXI_awready;
    logic           M00_AXI_awvalid;
    logic           M00_AXI_bready;
    logic [1:0]     M00_AXI_bresp;
    logic           M00_AXI_bvalid;
    logic [31:0]    M00_AXI_rdata;
    logic           M00_AXI_rready;
    logic [1:0]     M00_AXI_rresp;
    logic           M00_AXI_rvalid;
    logic [31:0]    M00_AXI_wdata;
    logic           M00_AXI_wready;
    logic [3:0]     M00_AXI_wstrb;
    logic           M00_AXI_wvalid;
    logic           axi_aclk, axi_aresetn;
   

    system system_i(
        .pcie_clkin_clk_n   (pcie_clkin_clk_n),
        .pcie_clkin_clk_p   (pcie_clkin_clk_p),
        .pcie_mgt_rxn       (pcie_mgt_rxn),
        .pcie_mgt_rxp       (pcie_mgt_rxp),
        .pcie_mgt_txn       (pcie_mgt_txn),
        .pcie_mgt_txp       (pcie_mgt_txp),
        .pcie_reset         (pcie_reset),     
        //
        .axi_aclk           (axi_aclk),
        .axi_aresetn        (axi_aresetn),
        .M00_AXI_araddr     (M00_AXI_araddr),
        .M00_AXI_arprot     (M00_AXI_arprot),
        .M00_AXI_arready    (M00_AXI_arready),
        .M00_AXI_arvalid    (M00_AXI_arvalid),
        .M00_AXI_awaddr     (M00_AXI_awaddr),
        .M00_AXI_awprot     (M00_AXI_awprot),
        .M00_AXI_awready    (M00_AXI_awready),
        .M00_AXI_awvalid    (M00_AXI_awvalid),
        .M00_AXI_bready     (M00_AXI_bready),
        .M00_AXI_bresp      (M00_AXI_bresp),
        .M00_AXI_bvalid     (M00_AXI_bvalid),
        .M00_AXI_rdata      (M00_AXI_rdata),
        .M00_AXI_rready     (M00_AXI_rready),
        .M00_AXI_rresp      (M00_AXI_rresp),
        .M00_AXI_rvalid     (M00_AXI_rvalid),
        .M00_AXI_wdata      (M00_AXI_wdata),
        .M00_AXI_wready     (M00_AXI_wready),
        .M00_AXI_wstrb      (M00_AXI_wstrb),
        .M00_AXI_wvalid     (M00_AXI_wvalid)
);           
    
    assign pcie_clkreq_l = 1'b0;

    logic clk;
    IBUFDS #(.DIFF_TERM("TRUE"), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("DEFAULT")) IBUFDS_inst (.O(clk), .I(sysclk_p), .IB(sysclk_n));
    
    logic[3:0] led;
    logic[27:0] led_count;
    always_ff @(posedge clk) begin
        led_count <= led_count + 1;
        led <= led_count[27:24];
    end    
    assign ledn = ~led;
    
    
    // This register file gives software contol over unit under test (UUT).
    localparam int Nregs = 16;
    logic [Nregs-1:0][31:0] slv_reg, slv_read;

    assign slv_read[0] = 32'hdeadbeef;
    assign slv_read[1] = 32'h76543210;
    
    assign slv_read[2] = slv_reg[2];

    assign slv_read[Nregs-1:3] = slv_reg[Nregs-1:3];

    localparam int Npci_addr = 6; 
    axi_regfile_v1_0_S00_AXI #  (
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(Npci_addr) // 16 32-bit registers.
    ) axi_regfile_inst (
        // register interface
        .slv_read(slv_read),
        .slv_reg (slv_reg),
        // axi interface
        .S_AXI_ACLK    (axi_aclk),
        .S_AXI_ARESETN (axi_aresetn),
        //
        .S_AXI_ARADDR  (M00_AXI_araddr[Npci_addr-1:0] ),
        .S_AXI_ARPROT  (M00_AXI_arprot ),
        .S_AXI_ARREADY (M00_AXI_arready),
        .S_AXI_ARVALID (M00_AXI_arvalid),
        .S_AXI_AWADDR  (M00_AXI_awaddr[Npci_addr-1:0] ),
        .S_AXI_AWPROT  (M00_AXI_awprot ),
        .S_AXI_AWREADY (M00_AXI_awready),
        .S_AXI_AWVALID (M00_AXI_awvalid),
        .S_AXI_BREADY  (M00_AXI_bready ),
        .S_AXI_BRESP   (M00_AXI_bresp  ),
        .S_AXI_BVALID  (M00_AXI_bvalid ),
        .S_AXI_RDATA   (M00_AXI_rdata  ),
        .S_AXI_RREADY  (M00_AXI_rready ),
        .S_AXI_RRESP   (M00_AXI_rresp  ),
        .S_AXI_RVALID  (M00_AXI_rvalid ),
        .S_AXI_WDATA   (M00_AXI_wdata  ),
        .S_AXI_WREADY  (M00_AXI_wready ),
        .S_AXI_WSTRB   (M00_AXI_wstrb  ),
        .S_AXI_WVALID  (M00_AXI_wvalid )
    );    

endmodule

