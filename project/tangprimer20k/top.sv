module top (
    input logic clk_i,
    input logic arstn_i,

    input  logic uart_rx_i,
    output logic uart_tx_o,

    input  logic scl_pad_i,
    output logic scl_pad_o,
    output logic scl_padoen_o,

    input  logic sda_pad_i,
    output logic sda_pad_o,
    output logic sda_padoen_o
);

    localparam int AXIL_ADDR_WIDTH = 32;
    localparam int AXIL_DATA_WIDTH = 32;
    localparam int AXI_DATA_WIDTH = 64;
    localparam int SPI_CS_WIDTH = 1;
    localparam int RGMII_WIDTH = 4;
    localparam int MASTER_NUM = 1;

    axil_if #(
        .ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .DATA_WIDTH(AXIL_DATA_WIDTH)
    ) axil[MASTER_NUM-1:0] (
        .clk_i  (clk_i),
        .arstn_i(arstn_i)
    );

    axi_if #(
        .ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi (
        .clk_i  (clk_i),
        .arstn_i(arstn_i)
    );

    eth_if #(.DATA_WIDTH(RGMII_WIDTH)) eth ();

    spi_if #(.CS_WIDTH(SPI_CS_WIDTH)) spi ();

    axil_top #(
        .FIFO_DEPTH     (128),
        .AXIL_ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH),
        .AXIS_DATA_WIDTH(8),
        .SLAVE_LOW_ADDR ('{default: '0}),
        .SLAVE_HIGH_ADDR('{default: '0}),
        .SLAVE_NUM      (5),
        .SPI_CS_WIDTH   (SPI_CS_WIDTH),
        .RGMII_WIDTH    (RGMII_WIDTH),
        .ILA_EN         (0),
        .MASTER_NUM     (MASTER_NUM),
        .ASYNC_MODE_EN  (0),
        .VENDOR         ("gowin")
    ) i_axil_top (
        .clk_i       (clk_i),
        .arstn_i     (arstn_i),
        .uart_rx_i   (uart_rx_i),
        .uart_tx_o   (uart_tx_o),
        .scl_pad_i   (scl_pad_i),
        .scl_pad_o   (scl_pad_o),
        .scl_padoen_o(scl_padoen_o),
        .sda_pad_i   (sda_pad_i),
        .sda_pad_o   (sda_pad_o),
        .sda_padoen_o(sda_padoen_o),
        .s2mm_irq_o  (),
        .mm2s_irq_o  (),
        .m_eth       (eth),
        .m_spi       (spi),
        .m_axi       (axi),
        .s_axil      (axil)
    );

endmodule
