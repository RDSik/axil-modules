`include "rgmii_pkg.svh"

module mac_tx
    import rgmii_pkg::*;
#(
    parameter int GMII_WIDTH      = 8,
    parameter int PAYLOAD_WIDTH   = 11,
    parameter int AXIS_DATA_WIDTH = 8
) (
    input logic clk_i,
    input logic rst_i,

    output logic                  tx_en_o,
    output logic [GMII_WIDTH-1:0] tx_d_o,

    input logic [PAYLOAD_WIDTH-1:0] payload_bytes_i,

    input logic [15:0] fpga_port_i,
    input logic [31:0] fpga_ip_i,
    input logic [47:0] fpga_mac_i,

    input logic [15:0] host_port_i,
    input logic [31:0] host_ip_i,
    input logic [47:0] host_mac_i,

    axis_if.slave s_axis
);

    typedef enum {
        IDLE,
        PREAMBLE,
        SFD,
        HEADER,
        DATA,
        FCS,
        WAIT
    } state_type_t;

    state_type_t current_state, next_state;

    logic [31:0] state_counter;

    localparam int WAIT_BYTES = 12;

    localparam int HEADER_LENGTH = HEADER_BYTES * 8 / GMII_WIDTH;
    localparam int WAIT_LENGTH = WAIT_BYTES * 8 / GMII_WIDTH;
    localparam int SFD_LENGTH = SFD_BYTES * 8 / GMII_WIDTH;
    localparam int PREAMBLE_LENGTH = PREAMBLE_BYTES * 8 / GMII_WIDTH;
    localparam int FCS_LENGTH = FCS_BYTES * 8 / GMII_WIDTH;

    ethernet_header_t                                  header;
    logic             [$bits(ethernet_header_t)-1 : 0] header_buffer;
    logic             [           AXIS_DATA_WIDTH-1:0] data_buffer;
    logic                                              data_valid;
    logic             [          PREAMBLE_BYTES*8-1:0] preamble_buffer;
    logic             [               SFD_BYTES*8-1:0] sfd_buffer;
    logic             [               FCS_BYTES*8-1:0] fcs;
    logic             [               FCS_BYTES*8-1:0] fcs_buffer;

    logic             [                          31:0] data_length;

    assign data_length = payload_bytes_i * 8 / GMII_WIDTH;

    eth_header_gen #(
        .PAYLOAD_WIDTH(PAYLOAD_WIDTH)
    ) eth_header_gen (
        .clk_i          (clk_i),
        .fpga_port_i    (fpga_port_i),
        .fpga_ip_i      (fpga_ip_i),
        .fpga_mac_i     (fpga_mac_i),
        .host_port_i    (host_port_i),
        .host_ip_i      (host_ip_i),
        .host_mac_i     (host_mac_i),
        .payload_bytes_i(payload_bytes_i),
        .output_header_o(header)
    );

    localparam int FIFO_DEPTH = 2 ** PAYLOAD_WIDTH;

    logic [$clog2(FIFO_DEPTH):0] fifo_count;

    axis_if #(
        .DATA_WIDTH(AXIS_DATA_WIDTH)
    ) m_axis (
        .clk_i  (clk_i),
        .arstn_i(~rst_i)
    );

    axis_fifo #(
        .FIFO_DEPTH   (FIFO_DEPTH),
        .FIFO_WIDTH   (AXIS_DATA_WIDTH),
        .ASYNC_MODE_EN(0),
        .SIGNAL_EN    ('0),
        .RAM_STYLE    ("block")
    ) i_axis_fifo_rx (
        .s_axis    (s_axis),
        .m_axis    (m_axis),
        .data_cnt_o(fifo_count),
        .a_full_o  (),
        .a_empty_o ()
    );

    logic m_axis_tready;
    assign m_axis.tready = m_axis_tready;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            m_axis_tready <= 1'b0;
        end else begin
            if ((current_state == HEADER) && (state_counter == HEADER_LENGTH - 2)) begin
                m_axis_tready <= 1'b1;
            end else if ((current_state == DATA) && (state_counter == data_length - 2)) begin
                m_axis_tready <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state_counter <= '0;
        end else begin
            if (current_state != next_state) begin
                state_counter <= '0;
            end else begin
                state_counter <= state_counter + 'd1;
            end
        end
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (fifo_count >= payload_bytes_i) begin
                    next_state = PREAMBLE;
                end
            end
            PREAMBLE: begin
                if (state_counter == PREAMBLE_LENGTH - 1) begin
                    next_state = SFD;
                end
            end
            SFD: begin
                if (state_counter == SFD_LENGTH - 1) begin
                    next_state = HEADER;
                end
            end
            HEADER: begin
                if (state_counter == HEADER_LENGTH - 1) begin
                    next_state = DATA;
                end
            end
            DATA: begin
                if (state_counter == data_length - 1) begin
                    next_state = FCS;
                end
            end
            FCS: begin
                if (state_counter == FCS_LENGTH - 1) begin
                    next_state = WAIT;
                end
            end
            WAIT: begin
                if (state_counter == WAIT_LENGTH - 1) begin
                    next_state = IDLE;
                end
            end
            default: next_state = current_state;
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    logic [GMII_WIDTH-1:0] tx_data;
    logic                  tx_valid;
    logic                  fcs_en;
    logic                  fcs_rst;

    always_comb begin
        case (current_state)
            IDLE: begin
                tx_valid = 0;
                tx_data  = 0;
                fcs_en   = 0;
                fcs_rst  = 1;
            end
            PREAMBLE: begin
                tx_valid = 1;
                tx_data  = preamble_buffer[GMII_WIDTH-1:0];
                fcs_en   = 0;
                fcs_rst  = 0;
            end
            SFD: begin
                tx_valid = 1;
                tx_data  = sfd_buffer[GMII_WIDTH-1:0];
                fcs_en   = 0;
                fcs_rst  = 0;
            end
            HEADER: begin
                tx_valid = 1;
                tx_data  = header_buffer[GMII_WIDTH-1:0];
                fcs_en   = 1;
                fcs_rst  = 0;
            end
            DATA: begin
                tx_valid = data_valid;
                tx_data  = data_buffer[GMII_WIDTH-1:0];
                fcs_en   = 1;
                fcs_rst  = 0;
            end
            FCS: begin
                tx_valid = 1;
                tx_data  = fcs_buffer[GMII_WIDTH-1:0];
                fcs_en   = 0;
                fcs_rst  = 0;
            end
            WAIT: begin
                tx_valid = 0;
                tx_data  = 0;
                fcs_en   = 0;
                fcs_rst  = 0;
            end
            default: begin
                tx_valid = 0;
                tx_data  = 0;
                fcs_en   = 0;
                fcs_rst  = 0;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            preamble_buffer <= 0;
            sfd_buffer      <= 0;
            fcs_buffer      <= 0;
            header_buffer   <= 0;
            data_buffer     <= 0;
            data_valid      <= 0;
        end else begin
            if (current_state == IDLE) begin
                header_buffer   <= header;
                preamble_buffer <= PREAMBLE_VAL;
                sfd_buffer      <= SFD_VAL;
            end
            if (next_state == FCS && current_state != FCS) begin
                fcs_buffer <= fcs;
            end
            if (next_state == DATA && current_state != DATA) begin
                data_buffer <= m_axis.tdata;
                data_valid  <= m_axis.tvalid;
            end
            if (current_state == HEADER) begin
                header_buffer <= header_buffer >> GMII_WIDTH;
            end
            if (current_state == PREAMBLE) begin
                preamble_buffer <= preamble_buffer >> GMII_WIDTH;
            end
            if (current_state == SFD) begin
                sfd_buffer <= sfd_buffer >> GMII_WIDTH;
            end
            if (current_state == DATA && next_state == DATA) begin
                data_buffer <= m_axis.tdata;
                data_valid  <= m_axis.tvalid;
            end
            if (current_state == FCS) begin
                fcs_buffer <= fcs_buffer >> GMII_WIDTH;
            end
        end
    end

    crc #(
        .DATA_WIDTH(GMII_WIDTH),
        .CRC_WIDTH (FCS_BYTES * 8),
        .LSB_FIRST (1),
        .INVERT_OUT(1),
        .LEFT_SHIFT(0)
    ) i_crc (
        .clk_i (clk_i),
        .rst_i (rst_i || fcs_rst),
        .data_i(tx_data),
        .en_i  (fcs_en),
        .crc_o (fcs)
    );

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            tx_en_o <= 0;
        end else begin
            tx_en_o <= tx_valid;
        end
        tx_d_o <= tx_data;
    end

endmodule
