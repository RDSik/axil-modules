module axis_rgmii #(
    parameter int RGMII_WIDTH   = 4,
    parameter int PAYLOAD_WIDTH = 11,
    parameter     VENDOR        = "xilinx"
) (
    input logic tx_rst_i,
    input logic rx_rst_i,

    input logic check_destination_i,

    input logic [PAYLOAD_WIDTH-1:0] payload_bytes_i,

    input logic [15:0] fpga_port_i,
    input logic [31:0] fpga_ip_i,
    input logic [47:0] fpga_mac_i,

    input logic [15:0] host_port_i,
    input logic [31:0] host_ip_i,
    input logic [47:0] host_mac_i,

    output logic crc_err_o,

    eth_if.master m_eth,

    axis_if.slave  s_axis,
    axis_if.master m_axis
);

    localparam int GMII_WIDTH = 8;

    logic [GMII_WIDTH-1:0] tx_d;
    logic                  tx_en;

    mac_tx #(
        .GMII_WIDTH     (GMII_WIDTH),
        .PAYLOAD_WIDTH  (PAYLOAD_WIDTH),
        .AXIS_DATA_WIDTH(GMII_WIDTH)
    ) i_mac_tx (
        .clk_i          (m_eth.tx_clk),
        .rst_i          (tx_rst_i),
        .tx_en_o        (tx_en),
        .tx_d_o         (tx_d),
        .payload_bytes_i(payload_bytes_i),
        .fpga_port_i    (fpga_port_i),
        .fpga_ip_i      (fpga_ip_i),
        .fpga_mac_i     (fpga_mac_i),
        .host_port_i    (host_port_i),
        .host_ip_i      (host_ip_i),
        .host_mac_i     (host_mac_i),
        .s_axis         (s_axis)
    );

    logic [GMII_WIDTH-1:0] rx_d;
    logic                  rx_dv;

    mac_rx #(
        .GMII_WIDTH     (GMII_WIDTH),
        .PAYLOAD_WIDTH  (PAYLOAD_WIDTH),
        .AXIS_DATA_WIDTH(GMII_WIDTH)
    ) i_mac_rx (
        .clk_i              (m_eth.rx_clk),
        .rst_i              (rx_rst_i),
        .rx_dv_i            (rx_dv),
        .rx_d_i             (rx_d),
        .check_destination_i(check_destination_i),
        .payload_bytes_i    (payload_bytes_i),
        .fpga_port_i        (fpga_port_i),
        .fpga_ip_i          (fpga_ip_i),
        .fpga_mac_i         (fpga_mac_i),
        .host_port_i        (host_port_i),
        .host_ip_i          (host_ip_i),
        .host_mac_i         (host_mac_i),
        .crc_err_o          (crc_err_o),
        .m_axis             (m_axis)
    );

    rgmii_tx #(
        .GMII_WIDTH (GMII_WIDTH),
        .RGMII_WIDTH(RGMII_WIDTH),
        .VENDOR     (VENDOR)
    ) i_rgmii_tx (
        .clk_i         (m_eth.tx_clk),
        .gmii_tx_en_i  (tx_en),
        .gmii_txd_i    (tx_d),
        .rgmii_txd_o   (m_eth.txd),
        .rgmii_tx_ctl_o(m_eth.tx_ctl)
    );

    rgmii_rx #(
        .GMII_WIDTH (GMII_WIDTH),
        .RGMII_WIDTH(RGMII_WIDTH),
        .VENDOR     (VENDOR)
    ) i_rgmii_rx (
        .clk_i         (m_eth.rx_clk),
        .rgmii_rx_ctl_i(m_eth.rx_ctl),
        .rgmii_rxd_i   (m_eth.rxd),
        .tx_clk_o      (m_eth.tx_clk),
        .gmii_rx_en_o  (rx_dv),
        .gmii_rxd_o    (rx_d)
    );

endmodule
