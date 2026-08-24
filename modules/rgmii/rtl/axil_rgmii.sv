`include "rgmii_pkg.svh"

module axil_rgmii
    import rgmii_pkg::*;
#(
    parameter int   FIFO_DEPTH      = 128,
    parameter int   AXIL_ADDR_WIDTH = 32,
    parameter int   AXIL_DATA_WIDTH = 32,
    parameter int   RGMII_WIDTH     = 4,
    parameter logic ILA_EN          = 0,
    parameter logic ASYNC_MODE_EN   = 0,
    parameter       VENDOR          = "xilinx"
) (
    input logic clk_i,
    input logic arstn_i,

    eth_if.master m_eth,

    axis_if.slave  s_axis,
    axis_if.master m_axis,

    axil_if.slave s_axil
);

    localparam int PAYLOAD_WIDTH = 11;

    rgmii_reg_t                     rd_regs;
    rgmii_reg_t                     wr_regs;

    logic       [RGMII_REG_NUM-1:0] rd_request;
    logic       [RGMII_REG_NUM-1:0] rd_valid;
    logic       [RGMII_REG_NUM-1:0] wr_valid;

    axil_reg_file_wrap #(
        .REG_DATA_WIDTH(AXIL_DATA_WIDTH),
        .REG_ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .REG_NUM       (RGMII_REG_NUM),
        .reg_t         (rgmii_reg_t),
        .REG_INIT      (RGMII_REG_INIT),
        .ILA_EN        (ILA_EN),
        .ASYNC_MODE_EN (ASYNC_MODE_EN)
    ) i_axil_reg_file (
        .clk_i       (m_eth.tx_clk),
        .arstn_i     (arstn_i),
        .s_axil      (s_axil),
        .rd_regs_i   (rd_regs),
        .rd_valid_i  (rd_valid),
        .rd_request_o(rd_request),
        .wr_regs_o   (wr_regs),
        .wr_valid_o  (wr_valid)
    );

    logic crc_err;
    logic pll_locked;

    always_comb begin
        rd_valid                 = '1;
        rd_regs                  = wr_regs;

        rd_regs.param.reg_num    = RGMII_REG_NUM;
        rd_regs.param.fifo_depth = 2 ** PAYLOAD_WIDTH;

        rd_regs.status.crc_err   = crc_err;
    end

    axis_rgmii #(
        .RGMII_WIDTH  (RGMII_WIDTH),
        .PAYLOAD_WIDTH(PAYLOAD_WIDTH),
        .ASYNC_MODE_EN(ASYNC_MODE_EN),
        .VENDOR       (VENDOR)
    ) i_axis_rgmii (
        .tx_rst_i           (wr_regs.control.tx_reset),
        .rx_rst_i           (wr_regs.control.rx_reset),
        .check_destination_i(wr_regs.control.check_destination),
        .payload_bytes_i    (wr_regs.control.payload_bytes),
        .fpga_port_i        (wr_regs.port.fpga),
        .fpga_ip_i          (wr_regs.ip.fpga),
        .fpga_mac_i         (wr_regs.mac.fpga),
        .host_port_i        (wr_regs.port.host),
        .host_ip_i          (wr_regs.ip.host),
        .host_mac_i         (wr_regs.mac.host),
        .crc_err_o          (crc_err),
        .m_eth              (m_eth),
        .s_axis             (s_axis),
        .m_axis             (m_axis)
    );

endmodule
