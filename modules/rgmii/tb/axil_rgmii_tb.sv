`timescale 1ns / 1ps

`include "modules/rgmii/tb/axil_rgmii_class.svh"

module axil_rgmii_tb ();

    localparam real CLK_FREQ = 500 * 10 ** 6;
    localparam int AXIL_ADDR_WIDTH = 32;
    localparam int AXIL_DATA_WIDTH = 32;
    localparam int AXIS_DATA_WIDTH = 8;
    localparam int RGMII_WIDTH = 4;

    localparam logic [AXIL_ADDR_WIDTH-1:0] BASE_ADDR = 'h200000;

    localparam int CLK_PER_NS = 10 ** 9 / CLK_FREQ;
    localparam int RESET_DELAY = 10;

    logic clk_i;
    logic arstn_i;

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
    ) s_axil (
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
        axil_rgmii_class #(
            .DATA_WIDTH(AXIL_DATA_WIDTH),
            .ADDR_WIDTH(AXIL_ADDR_WIDTH),
            .TLAST_EN  (0),
            .BASE_ADDR (BASE_ADDR)
        ) rgmii;
        rgmii = new(s_axil, m_axis, s_axis);
        rgmii.rgmii_start();
        #10 $stop;
    end

    initial begin
        $dumpfile("axil_rgmii_tb.vcd");
        $dumpvars(0, axil_rgmii_tb);
    end

    axil_rgmii #(
        .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH),
        .AXIL_ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .RGMII_WIDTH    (RGMII_WIDTH),
        .ILA_EN         (0),
        .ASYNC_MODE_EN  (0),
        .VENDOR         ("")
    ) i_axil_rgmii (
        .clk_i  (clk_i),
        .arstn_i(arstn_i),
        .s_axil (s_axil),
        .s_axis (m_axis),
        .m_axis (s_axis),
        .m_eth  (m_eth)
    );

endmodule
