// this is a simple design to verify that the pcie reference clock and pcie reset are received by the fpga.
module top (
    input   logic       pcie_clkin_clk_p, pcie_clkin_clk_n,
    input   logic       pcie_reset,
    input   logic       pcie_clkreq_l,
    output  logic[3:0]  ledn
);

    assign pcie_clkreq_l = 1'b0;
    logic[3:0] led;
    assign ledn = ~led;
    
    logic pcie_clkin, clk;
    IBUFDS_GTE2 #(.CLKCM_CFG("TRUE"), .CLKRCV_TRST("TRUE"), .CLKSWING_CFG(2'b11)) IBUFDS_GTE2_inst (.O(pcie_clkin), .ODIV2(), .CEB(1'b0), .I(pcie_clkin_clk_p), .IB(pcie_clkin_clk_n));   
    BUFG BUFG_inst (.O(clk), .I(pcie_clkin));
    
    logic[27:0] led_count=0;
    logic reset_latch=1;
    always_ff @(posedge clk) begin
    
        if (pcie_reset==0) reset_latch <= 1'b0;
        
        if (reset_latch==0) begin
            led_count <= led_count + 1;
        end
        
        led <= led_count[27:24];
    end     


endmodule

