module axi_dma_wrap #(
    parameter int   FIFO_DEPTH    = 128,
    parameter logic ASYNC_MODE_EN = 0,
    parameter logic ILA_EN        = 0
) (
    output logic s2mm_irq_o,
    output logic mm2s_irq_o,

    axis_if.slave  s_axis,
    axis_if.master m_axis,

    axil_if.slave s_axil,

    axi_if.master m_axi
);

    
    localparam int CDC_REG_NUM = 3;
    localparam int AXI_DATA_WIDTH = m_axi.DATA_WIDTH;
    localparam logic [1:0] SIGNAL_EN = '1;

    axis_if #(
        .DATA_WIDTH(AXI_DATA_WIDTH)
    ) m_axis_mm2s (
        .clk_i  (s_axil.clk_i),
        .arstn_i(s_axil.arstn_i)
    );

    axis_if #(
        .DATA_WIDTH(AXI_DATA_WIDTH)
    ) s_axis_s2mm (
        .clk_i  (s_axil.clk_i),
        .arstn_i(s_axil.arstn_i)
    );

    axis_dw_conv_wrap #(
        .FIFO_DEPTH   (FIFO_DEPTH),
        .CDC_REG_NUM  (CDC_REG_NUM),
        .SIGNAL_EN    (SIGNAL_EN),
        .ASYNC_MODE_EN(ASYNC_MODE_EN),
        .FIFO_FIRST   (0)
    ) i_s2mm_axis_dw_conv (
        .s_axis(s_axis),
        .m_axis(s_axis_s2mm)
    );

    axis_dw_conv_wrap #(
        .FIFO_DEPTH   (FIFO_DEPTH),
        .CDC_REG_NUM  (CDC_REG_NUM),
        .SIGNAL_EN    (SIGNAL_EN),
        .ASYNC_MODE_EN(ASYNC_MODE_EN),
        .FIFO_FIRST   (0)
    ) i_mm2s_axis_dw_conv (
        .s_axis(m_axis_mm2s),
        .m_axis(m_axis)
    );

    axi_dma_0 i_axi_dma (
        .s_axi_lite_aclk(s_axil.clk_i),
        .m_axi_mm2s_aclk(m_axi.arstn_i),
        .m_axi_s2mm_aclk(m_axi.arstn_i),
        .axi_resetn     (m_axi.arstn_i),

        .s_axi_lite_awvalid(s_axil.awvalid),
        .s_axi_lite_awready(s_axil.awready),
        .s_axi_lite_awaddr (s_axil.awaddr),
        .s_axi_lite_wvalid (s_axil.wvalid),
        .s_axi_lite_wready (s_axil.wready),
        .s_axi_lite_wdata  (s_axil.wdata),
        .s_axi_lite_bresp  (s_axil.bresp),
        .s_axi_lite_bvalid (s_axil.bvalid),
        .s_axi_lite_bready (s_axil.bready),
        .s_axi_lite_arvalid(s_axil.arvalid),
        .s_axi_lite_arready(s_axil.arready),
        .s_axi_lite_araddr (s_axil.araddr),
        .s_axi_lite_rvalid (s_axil.rvalid),
        .s_axi_lite_rready (s_axil.rready),
        .s_axi_lite_rdata  (s_axil.rdata),
        .s_axi_lite_rresp  (s_axil.rresp),

        .m_axi_mm2s_araddr (m_axi.araddr),
        .m_axi_mm2s_arlen  (m_axi.arlen),
        .m_axi_mm2s_arsize (m_axi.arsize),
        .m_axi_mm2s_arburst(m_axi.arburst),
        .m_axi_mm2s_arprot (m_axi.arprot),
        .m_axi_mm2s_arcache(m_axi.arcache),
        .m_axi_mm2s_arvalid(m_axi.arvalid),
        .m_axi_mm2s_arready(m_axi.arready),
        .m_axi_mm2s_rdata  (m_axi.rdata),
        .m_axi_mm2s_rresp  (m_axi.rresp),
        .m_axi_mm2s_rlast  (m_axi.rlast),
        .m_axi_mm2s_rvalid (m_axi.rvalid),
        .m_axi_mm2s_rready (m_axi.rready),

        .mm2s_prmry_reset_out_n(),

        .m_axis_mm2s_tdata (m_axis_mm2s.tdata),
        .m_axis_mm2s_tkeep (m_axis_mm2s.tkeep),
        .m_axis_mm2s_tvalid(m_axis_mm2s.tvalid),
        .m_axis_mm2s_tready(m_axis_mm2s.tready),
        .m_axis_mm2s_tlast (m_axis_mm2s.tlast),

        .m_axi_s2mm_awaddr (m_axi.awaddr),
        .m_axi_s2mm_awlen  (m_axi.awlen),
        .m_axi_s2mm_awsize (m_axi.awsize),
        .m_axi_s2mm_awburst(m_axi.awburst),
        .m_axi_s2mm_awprot (m_axi.awprot),
        .m_axi_s2mm_awcache(m_axi.awcache),
        .m_axi_s2mm_awvalid(m_axi.awvalid),
        .m_axi_s2mm_awready(m_axi.awready),
        .m_axi_s2mm_wdata  (m_axi.wdata),
        .m_axi_s2mm_wstrb  (m_axi.wstrb),
        .m_axi_s2mm_wlast  (m_axi.wlast),
        .m_axi_s2mm_wvalid (m_axi.wvalid),
        .m_axi_s2mm_wready (m_axi.wready),
        .m_axi_s2mm_bresp  (m_axi.bresp),
        .m_axi_s2mm_bvalid (m_axi.bvalid),
        .m_axi_s2mm_bready (m_axi.bready),

        .s2mm_prmry_reset_out_n(),

        .s_axis_s2mm_tdata (s_axis_s2mm.tdata),
        .s_axis_s2mm_tkeep (s_axis_s2mm.tkeep),
        .s_axis_s2mm_tvalid(s_axis_s2mm.tvalid),
        .s_axis_s2mm_tready(s_axis_s2mm.tready),
        .s_axis_s2mm_tlast (s_axis_s2mm.tlast),

        .mm2s_introut(mm2s_irq_o),
        .s2mm_introut(s2mm_irq_o),

        .axi_dma_tstvec()
    );

    if (ILA_EN) begin : g_ila
        axil_ila i_axil_ila (
            .clk    (s_axil.clk_i),
            .probe0 (s_axil.awvalid),
            .probe1 (s_axil.awaddr),
            .probe2 (s_axil.bresp),
            .probe3 (s_axil.bvalid),
            .probe4 (s_axil.bready),
            .probe5 (s_axil.wdata),
            .probe6 (s_axil.wvalid),
            .probe7 (s_axil.wready),
            .probe8 (s_axil.awready),
            .probe9 (s_axil.rready),
            .probe10(s_axil.araddr),
            .probe11(s_axil.arvalid),
            .probe12(s_axil.arready),
            .probe13(s_axil.rresp),
            .probe14(s_axil.rdata),
            .probe15(s_axil.wstrb),
            .probe16(s_axil.rvalid),
            .probe17(s_axil.arprot),
            .probe18(s_axil.awprot)
        );
    end

endmodule
