`timescale 1ns / 1ps

`include "modules/spi/tb/axil_spi_class.svh"
`include "modules/uart/tb/axil_uart_class.svh"
`include "modules/i2c/tb/axil_i2c_class.svh"
`include "modules/rgmii/tb/axil_rgmii_class.svh"
`include "modules/top/rtl/top_pkg.svh"

module axil_top_tb
    import top_pkg::*;
();

    localparam real SIM_CLK_FREQ = CLK_FREQ * 10;
    localparam int WAIT_CYCLES = 250;
    localparam int CLK_PER_NS = 10 ** 9 / SIM_CLK_FREQ;
    localparam int RESET_DELAY = 10;

    logic clk_i;
    logic arstn_i;
    logic uart;

    spi_if #(.CS_WIDTH(SPI_CS_WIDTH)) m_spi ();

    assign m_spi.miso = m_spi.mosi;

    eth_if #(.DATA_WIDTH(RGMII_WIDTH)) m_eth ();

    assign m_eth.rxd    = m_eth.txd;
    assign m_eth.rx_ctl = m_eth.tx_ctl;
    assign m_eth.rx_clk = clk_i;

    axis_if #(
        .DATA_WIDTH(AXIS_DATA_WIDTH)
    ) m_axis (
        .clk_i(clk_i),
        .arstn_i(arstn_i)
    );

    axis_if #(
        .DATA_WIDTH(AXIS_DATA_WIDTH)
    ) s_axis (
        .clk_i(clk_i),
        .arstn_i(arstn_i)
    );

    axil_if #(
        .ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .DATA_WIDTH(AXIL_DATA_WIDTH)
    ) s_axil[MASTER_NUM-1:0] (
        .clk_i  (clk_i),
        .arstn_i(arstn_i)
    );

    initial begin
        arstn_i = 1'b0;
        repeat (RESET_DELAY) @(posedge clk_i);
        arstn_i = 1'b1;
        $display("Reset done in: %0t ns\n.", $time());
    end

    initial begin
        clk_i = 1'b0;
        forever begin
            #(CLK_PER_NS / 2) clk_i = ~clk_i;
        end
    end

    initial begin
        axil_uart_class #(
            .DATA_WIDTH(AXIL_DATA_WIDTH),
            .ADDR_WIDTH(AXIL_ADDR_WIDTH),
            .BASE_ADDR (SLAVE_LOW_ADDR[0])
        ) uart;
        axil_spi_class #(
            .DATA_WIDTH(AXIL_DATA_WIDTH),
            .ADDR_WIDTH(AXIL_ADDR_WIDTH),
            .BASE_ADDR (SLAVE_LOW_ADDR[1])
        ) spi;
        axil_i2c_class #(
            .DATA_WIDTH(AXIL_DATA_WIDTH),
            .ADDR_WIDTH(AXIL_ADDR_WIDTH),
            .BASE_ADDR (SLAVE_LOW_ADDR[2])
        ) i2c;
        axil_rgmii_class #(
            .DATA_WIDTH(AXIL_DATA_WIDTH),
            .ADDR_WIDTH(AXIL_ADDR_WIDTH),
            .TLAST_EN  (0),
            .BASE_ADDR (SLAVE_LOW_ADDR[3])
        ) rgmii;
        uart  = new(s_axil[0]);
        spi   = new(s_axil[0]);
        rgmii = new(s_axil[0], m_axis, s_axis);
        i2c   = new(s_axil[0]);
        uart.uart_start();
        spi.spi_start();
        i2c.i2c_start();
        rgmii.rgmii_start();
        $stop;
    end

    initial begin
        $dumpfile("axil_top_tb.vcd");
        $dumpvars(0, axil_top_tb);
    end

    axil_top #(
        .AXIL_ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH),
        .FIFO_DEPTH     (FIFO_DEPTH),
        .SPI_CS_WIDTH   (SPI_CS_WIDTH),
        .RGMII_WIDTH    (RGMII_WIDTH),
        .SLAVE_NUM      (SLAVE_NUM),
        .MASTER_NUM     (MASTER_NUM),
        .SLAVE_LOW_ADDR (SLAVE_LOW_ADDR),
        .SLAVE_HIGH_ADDR(SLAVE_HIGH_ADDR),
        .ILA_EN         (0),
        .ASYNC_MODE_EN  (0),
        .VENDOR         ("")
    ) i_axil_top (
        .clk_i    (clk_i),
        .arstn_i  (arstn_i),
        .uart_rx_i(uart),
        .uart_tx_o(uart),
        .s_axil   (s_axil),
        .s_axis   (m_axis),
        .m_axis   (s_axis),
        .m_spi    (m_spi),
        .m_eth    (m_eth)
    );

endmodule
