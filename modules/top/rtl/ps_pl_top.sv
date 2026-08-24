/* verilator lint_off TIMESCALEMOD */
`include "top_pkg.svh"

module ps_pl_top
    import top_pkg::*;
(
    input logic clk_i,

    input  logic uart_rx_i,
    output logic uart_tx_o,

    inout        eth_mdio_io,
    output logic eth_mdc_o,

    input logic                   eth_rx_clk_i,
    input logic [RGMII_WIDTH-1:0] eth_rxd_i,
    input logic                   eth_rx_ctl_i,

    output logic                   eth_tx_clk_o,
    output logic [RGMII_WIDTH-1:0] eth_txd_o,
    output logic                   eth_tx_ctl_o,

    input  logic                    spi_miso_i,
    output logic                    spi_mosi_o,
    output logic                    spi_clk_o,
    output logic [SPI_CS_WIDTH-1:0] spi_cs_o,

    inout i2c_scl_io,
    inout i2c_sda_io,

    inout [14:0] DDR_0_addr,
    inout [ 2:0] DDR_0_ba,
    inout        DDR_0_cas_n,
    inout        DDR_0_ck_n,
    inout        DDR_0_ck_p,
    inout        DDR_0_cke,
    inout        DDR_0_cs_n,
    inout [ 3:0] DDR_0_dm,
    inout [31:0] DDR_0_dq,
    inout [ 3:0] DDR_0_dqs_n,
    inout [ 3:0] DDR_0_dqs_p,
    inout        DDR_0_odt,
    inout        DDR_0_ras_n,
    inout        DDR_0_reset_n,
    inout        DDR_0_we_n,
    inout        FIXED_IO_0_ddr_vrn,
    inout        FIXED_IO_0_ddr_vrp,
    inout [53:0] FIXED_IO_0_mio,
    inout        FIXED_IO_0_ps_clk,
    inout        FIXED_IO_0_ps_porb,
    inout        FIXED_IO_0_ps_srstb
);

    logic scl_pad_i;
    logic scl_pad_o;
    logic scl_padoen_o;

    logic sda_pad_i;
    logic sda_pad_o;
    logic sda_padoen_o;

    IOBUF i_scl_IOBUF (
        .O (scl_pad_i),
        .IO(i2c_scl_io),
        .I (scl_pad_o),
        .T (scl_padoen_o)
    );

    IOBUF i_sda_IOBUF (
        .O (sda_pad_i),
        .IO(i2c_sda_io),
        .I (sda_pad_o),
        .T (sda_padoen_o)
    );

    spi_if #(.CS_WIDTH(SPI_CS_WIDTH)) spi ();

    assign spi_cs_o   = spi.cs;
    assign spi_clk_o  = spi.clk;
    assign spi_mosi_o = spi.mosi;
    assign spi.miso   = spi_miso_i;

    eth_if #(.DATA_WIDTH(RGMII_WIDTH)) eth ();

    IOBUF i_mdio_IOBUF (
        .O (eth.mdio_i),
        .IO(eth_mdio_io),
        .I (eth.mdio_o),
        .T (eth.mdio_t)
    );

    assign eth.rx_clk   = eth_rx_clk_i;
    assign eth.rxd      = eth_rxd_i;
    assign eth.rx_ctl   = eth_rx_ctl_i;
    assign eth_txd_o    = eth.txd;
    assign eth_tx_ctl_o = eth.tx_ctl;
    assign eth_tx_clk_o = eth.tx_clk;
    assign eth_mdc_o    = eth.mdc;

    logic ps_clk;
    logic ps_arstn;

    axil_if #(
        .ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .DATA_WIDTH(AXIL_DATA_WIDTH)
    ) axil[MASTER_NUM-1:0] (
        .clk_i  (ps_clk),
        .arstn_i(ps_arstn)
    );

    axi_if #(
        .ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi (
        .clk_i  (ps_clk),
        .arstn_i(ps_arstn)
    );

    logic arstn;

    xpm_cdc_async_rst #(
        .DEST_SYNC_FF   (3),
        .INIT_SYNC_FF   (0),
        .RST_ACTIVE_HIGH(0)
    ) i_xpm_cdc_async_rst (
        .src_arst (ps_arstn),
        .dest_clk (clk_i),
        .dest_arst(arstn)
    );

    logic s2mm_irq;
    logic mm2s_irq;

    axil_top #(
        .FIFO_DEPTH     (FIFO_DEPTH),
        .AXIL_ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH),
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
        .SLAVE_LOW_ADDR (SLAVE_LOW_ADDR),
        .SLAVE_HIGH_ADDR(SLAVE_HIGH_ADDR),
        .SLAVE_NUM      (SLAVE_NUM),
        .SPI_CS_WIDTH   (SPI_CS_WIDTH),
        .RGMII_WIDTH    (RGMII_WIDTH),
        .ILA_EN         (ILA_EN),
        .MASTER_NUM     (MASTER_NUM),
        .ASYNC_MODE_EN  (ASYNC_MODE_EN),
        .VENDOR         ("xilinx")
    ) i_axil_top (
        .clk_i       (clk_i),
        .arstn_i     (arstn),
        .uart_rx_i   (uart_rx_i),
        .uart_tx_o   (uart_tx_o),
        .scl_pad_i   (scl_pad_i),
        .scl_pad_o   (scl_pad_o),
        .scl_padoen_o(scl_padoen_o),
        .sda_pad_i   (sda_pad_i),
        .sda_pad_o   (sda_pad_o),
        .sda_padoen_o(sda_padoen_o),
        .s2mm_irq_o  (s2mm_irq),
        .mm2s_irq_o  (mm2s_irq),
        .m_eth       (eth),
        .m_spi       (spi),
        .m_axi       (axi),
        .s_axil      (axil)
    );

    bd_top i_bd_top (
        .m_axil             (axil[0]),
        .s_axi              (axi),
        .ps_clk_o           (ps_clk),
        .ps_arstn_o         (ps_arstn),
        .s2mm_irq_i         (s2mm_irq),
        .mm2s_irq_i         (mm2s_irq),
        .DDR_0_addr         (DDR_0_addr),
        .DDR_0_ba           (DDR_0_ba),
        .DDR_0_cas_n        (DDR_0_cas_n),
        .DDR_0_ck_n         (DDR_0_ck_n),
        .DDR_0_ck_p         (DDR_0_ck_p),
        .DDR_0_cke          (DDR_0_cke),
        .DDR_0_cs_n         (DDR_0_cs_n),
        .DDR_0_dm           (DDR_0_dm),
        .DDR_0_dq           (DDR_0_dq),
        .DDR_0_dqs_n        (DDR_0_dqs_n),
        .DDR_0_dqs_p        (DDR_0_dqs_p),
        .DDR_0_odt          (DDR_0_odt),
        .DDR_0_ras_n        (DDR_0_ras_n),
        .DDR_0_reset_n      (DDR_0_reset_n),
        .DDR_0_we_n         (DDR_0_we_n),
        .FIXED_IO_0_ddr_vrn (FIXED_IO_0_ddr_vrn),
        .FIXED_IO_0_ddr_vrp (FIXED_IO_0_ddr_vrp),
        .FIXED_IO_0_mio     (FIXED_IO_0_mio),
        .FIXED_IO_0_ps_clk  (FIXED_IO_0_ps_clk),
        .FIXED_IO_0_ps_porb (FIXED_IO_0_ps_porb),
        .FIXED_IO_0_ps_srstb(FIXED_IO_0_ps_srstb)
    );

endmodule
