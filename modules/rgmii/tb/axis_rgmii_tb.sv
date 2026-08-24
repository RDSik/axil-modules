`timescale 1ns / 1ps

`include "../../verification/tb/test_pkg.svh"

module axis_rgmii_tb ();

    import test_pkg::*;

    localparam int AXIS_DATA_WIDTH = 8;
    localparam int PAYLOAD_WIDTH = 11;
    localparam int RGMII_WIDTH = 4;

    localparam int ETH_CLK_PER = 2;
    localparam int CLK_PER = 4;
    localparam int ETH_RESET_DELAY = 10;
    localparam int RESET_DELAY = 10;

    localparam logic CHECK_DESTINATION = 1;
    localparam logic [7:0] FPGA_IP_1 = 10;
    localparam logic [7:0] FPGA_IP_2 = 0;
    localparam logic [7:0] FPGA_IP_3 = 0;
    localparam logic [7:0] FPGA_IP_4 = 240;
    localparam logic [7:0] HOST_IP_1 = 10;
    localparam logic [7:0] HOST_IP_2 = 0;
    localparam logic [7:0] HOST_IP_3 = 0;
    localparam logic [7:0] HOST_IP_4 = 10;
    localparam logic [15:0] FPGA_PORT = 17767;
    localparam logic [15:0] HOST_PORT = 17767;
    localparam logic [47:0] FPGA_MAC = 48'he86a64e7e830;
    localparam logic [47:0] HOST_MAC = 48'he86a64e7e829;

    localparam logic [PAYLOAD_WIDTH-1:0] PAYLOAD = 340;
    localparam logic [31:0] HOST_IP = {HOST_IP_1, HOST_IP_2, HOST_IP_3, HOST_IP_4};
    localparam logic [31:0] FPGA_IP = {FPGA_IP_1, FPGA_IP_2, FPGA_IP_3, FPGA_IP_4};

    logic eth_clk_i;
    logic eth_rst_i;

    logic clk_i;
    logic arstn_i;

    eth_if #(.DATA_WIDTH(RGMII_WIDTH)) m_eth ();

    assign m_eth.rxd    = m_eth.txd;
    assign m_eth.rx_ctl = m_eth.tx_ctl;
    assign m_eth.rx_clk = eth_clk_i;

    axis_if #(
        .DATA_WIDTH(AXIS_DATA_WIDTH)
    ) s_axis (
        .clk_i  (clk_i),
        .arstn_i(arstn_i)
    );

    axis_if #(
        .DATA_WIDTH(AXIS_DATA_WIDTH)
    ) m_axis (
        .clk_i  (clk_i),
        .arstn_i(arstn_i)
    );

    initial begin
        eth_rst_i = 1'b1;
        repeat (ETH_RESET_DELAY) @(posedge eth_clk_i);
        eth_rst_i = 1'b0;
        $display("Eth done in: %0t ns\n.", $time());
    end

    initial begin
        eth_clk_i = 1'b0;
        forever begin
            #(ETH_CLK_PER / 2) eth_clk_i = ~eth_clk_i;
        end
    end

    initial begin
        arstn_i = 1'b0;
        repeat (RESET_DELAY) @(posedge clk_i);
        arstn_i = 1'b1;
        $display("Axis reset done in: %0t ns\n.", $time());
    end

    initial begin
        clk_i = 1'b0;
        forever begin
            #(CLK_PER / 2) clk_i = ~clk_i;
        end
    end

    initial begin
        env_base #(
            .S_DATA_WIDTH(AXIS_DATA_WIDTH),
            .M_DATA_WIDTH(AXIS_DATA_WIDTH),
            .TLAST_EN    (0)
        ) env;
        env = new(s_axis, m_axis);
        env.run();
    end

    initial begin
        $dumpfile("axis_rgmii_tb.vcd");
        $dumpvars(0, axis_rgmii_tb);
    end

    axis_rgmii #(
        .RGMII_WIDTH  (RGMII_WIDTH),
        .PAYLOAD_WIDTH(PAYLOAD_WIDTH),
        .VENDOR       ("")
    ) i_axis_rgmii (
        .rx_rst_i           (eth_rst_i),
        .tx_rst_i           (eth_rst_i),
        .check_destination_i(CHECK_DESTINATION),
        .payload_bytes_i    (PAYLOAD),
        .fpga_port_i        (FPGA_PORT),
        .fpga_ip_i          (FPGA_IP),
        .fpga_mac_i         (FPGA_MAC),
        .host_port_i        (HOST_PORT),
        .host_ip_i          (HOST_IP),
        .host_mac_i         (HOST_MAC),
        .crc_err_o          (),
        .m_eth              (m_eth),
        .s_axis             (m_axis),
        .m_axis             (s_axis)
    );

endmodule
