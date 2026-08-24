`ifndef RGMII_PKG_SVH
`define RGMII_PKG_SVH

package rgmii_pkg;

    typedef struct packed {
        logic [1:0][7:0] udp_checksum;
        logic [1:0][7:0] length;
        logic [1:0][7:0] port_destination;
        logic [1:0][7:0] port_source;
    } udp_header_t;

    typedef struct packed {
        udp_header_t     udp;
        logic [3:0][7:0] ip_destination;
        logic [3:0][7:0] ip_source;
        logic [1:0][7:0] header_checksum;
        logic [7:0]      protocol;
        logic [7:0]      time_to_live;
        logic [1:0][7:0] flags_fragment_offset;
        logic [1:0][7:0] identification;
        logic [1:0][7:0] total_length;
        logic [7:0]      tos;
        logic [7:0]      version_ihl;
    } ipv4_header_t;

    typedef struct packed {
        ipv4_header_t ipv4;
        logic [1:0][7:0] eth_type_length;
        logic [5:0][7:0] mac_source;
        logic [5:0][7:0] mac_destination;
    } ethernet_header_t;

    localparam logic [15:0] UDP_HEADER_BYTES = $bits(udp_header_t) / 8;
    localparam logic [15:0] IPV4_HEADER_BYTES = $bits(ipv4_header_t) / 8;
    localparam int HEADER_BYTES = $bits(ethernet_header_t) / 8;
    localparam int SFD_BYTES = 1;
    localparam int PREAMBLE_BYTES = 7;
    localparam int FCS_BYTES = 4;

    localparam logic [55:0] PREAMBLE_VAL = 56'h55555555555555;
    localparam logic [7:0] SFD_VAL = 8'hd5;

    typedef struct packed {
        logic [7:0]  rsrvd;
        logic [7:0]  reg_num;
        logic [15:0] fifo_depth;
    } rgmii_param_t;

    typedef struct packed {
        logic [30:0] rsrvd;
        logic        crc_err;
    } rgmii_status_t;

    typedef struct packed {
        logic [12:0] rsrvd;
        logic [15:0] payload_bytes;
        logic        check_destination;
        logic        rx_reset;
        logic        tx_reset;
    } rgmii_control_t;

    typedef struct packed {
        logic [15:0] fpga;
        logic [15:0] host;
    } rgmii_port_t;

    typedef struct packed {
        logic [31:0] fpga;
        logic [31:0] host;
    } rgmii_ip_t;

    typedef struct packed {
        logic [7:0][7:0] fpga;
        logic [7:0][7:0] host;
    } rgmii_mac_t;

    typedef struct packed {
        rgmii_param_t   param;
        rgmii_status_t  status;
        rgmii_mac_t     mac;
        rgmii_ip_t      ip;
        rgmii_port_t    port;
        rgmii_control_t control;
    } rgmii_reg_t;

    localparam int RGMII_REG_NUM = $bits(rgmii_reg_t) / 32;

    localparam int RGMII_CONTROL_REG_POS = 0;
    localparam int RGMII_PORT_REG_POS = RGMII_CONTROL_REG_POS + $bits(rgmii_control_t) / 32;
    localparam int RGMII_HOST_IP_REG_POS = RGMII_PORT_REG_POS + $bits(rgmii_port_t) / 32;
    localparam int RGMII_FPGA_IP_REG_POS = RGMII_HOST_IP_REG_POS + 1;
    localparam int RGMII_HOST_MAC_REG_POS = RGMII_HOST_IP_REG_POS + $bits(rgmii_ip_t) / 32;
    localparam int RGMII_FPGA_MAC_REG_POS = RGMII_HOST_MAC_REG_POS + 2;
    localparam int RGMII_STATUS_REG_POS = RGMII_HOST_MAC_REG_POS + $bits(rgmii_mac_t) / 32;
    localparam int RGMII_PARAM_REG_POS = RGMII_STATUS_REG_POS + $bits(rgmii_status_t) / 32;

    localparam rgmii_reg_t RGMII_REG_INIT = '{control : '{tx_reset: 1'b1, rx_reset: 1'b1, default: '0}, default: '0};

    typedef struct packed {
        rgmii_mac_t     mac;
        rgmii_ip_t      ip;
        rgmii_port_t    port;
        rgmii_control_t control;
    } rgmii_config_t;

    localparam int CONFIG_REG_NUM = $bits(rgmii_config_t) / 32;

endpackage

`endif  // RGMII_PKG_SVH
