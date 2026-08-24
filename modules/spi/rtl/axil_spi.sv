/* verilator lint_off TIMESCALEMOD */
`include "../rtl/spi_pkg.svh"

module axil_spi
    import spi_pkg::*;
#(
    parameter int   FIFO_DEPTH      = 128,
    parameter int   AXIL_ADDR_WIDTH = 32,
    parameter int   AXIL_DATA_WIDTH = 32,
    parameter int   SLAVE_NUM       = 1,
    parameter logic ILA_EN          = 0,
    parameter logic ASYNC_MODE_EN   = 0
) (
    input logic clk_i,
    input logic arstn_i,

    axil_if.slave s_axil,

    spi_if.master m_spi
);

    spi_regs_t                          rd_regs;
    spi_regs_t                          wr_regs;

    logic      [       SPI_REG_NUM-1:0] rd_request;
    logic      [       SPI_REG_NUM-1:0] rd_valid;
    logic      [       SPI_REG_NUM-1:0] wr_valid;

    logic      [$clog2(FIFO_DEPTH)-1:0] tx_cnt;
    logic      [$clog2(FIFO_DEPTH)-1:0] rx_cnt;

    logic                               reset;
    assign reset = wr_regs.control.reset;

    axis_if #(
        .DATA_WIDTH(SPI_DATA_WIDTH)
    ) fifo_tx (
        .clk_i  (clk_i),
        .arstn_i(~reset)
    );

    axis_if #(
        .DATA_WIDTH(SPI_DATA_WIDTH)
    ) fifo_rx (
        .clk_i  (clk_i),
        .arstn_i(~reset)
    );

    axis_if #(
        .DATA_WIDTH(SPI_DATA_WIDTH)
    ) spi_tx (
        .clk_i  (clk_i),
        .arstn_i(~reset)
    );

    axis_if #(
        .DATA_WIDTH(SPI_DATA_WIDTH)
    ) spi_rx (
        .clk_i  (clk_i),
        .arstn_i(~reset)
    );

    always_comb begin
        rd_valid                     = '1;
        rd_regs                      = wr_regs;

        rd_regs.param.data_width     = SPI_DATA_WIDTH;
        rd_regs.param.fifo_depth     = FIFO_DEPTH;
        rd_regs.param.reg_num        = SPI_REG_NUM;

        rd_regs.status.rx_fifo_empty = ~fifo_rx.tvalid;
        rd_regs.status.tx_fifo_empty = ~spi_tx.tvalid;
        rd_regs.status.rx_fifo_full  = ~spi_rx.tready;
        rd_regs.status.tx_fifo_full  = ~fifo_tx.tready;
        rd_regs.status.rx_fifo_cnt   = rx_cnt;
        rd_regs.status.tx_fifo_cnt   = tx_cnt;

        rd_regs.rx.data              = fifo_rx.tdata;
    end

    logic tx_handshake;
    assign tx_handshake = fifo_tx.tvalid & fifo_tx.tready;

    logic tx_last;

    cnt #(
        .CNT_WIDTH($clog2(FIFO_DEPTH))
    ) i_cnt (
        .clk_i     (clk_i),
        .rst_i     (reset),
        .en_i      (tx_handshake),
        .max_val_i (wr_regs.control.bytes_num),
        .cnt_last_o(tx_last)
    );

    assign fifo_tx.tlast  = tx_last;
    assign fifo_tx.tdata  = wr_regs.tx.data;
    assign fifo_tx.tvalid = wr_valid[SPI_TX_DATA_REG_POS];
    assign fifo_rx.tready = rd_request[SPI_RX_DATA_REG_POS];

    axil_reg_file_wrap #(
        .REG_DATA_WIDTH(AXIL_DATA_WIDTH),
        .REG_ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .REG_NUM       (SPI_REG_NUM),
        .reg_t         (spi_regs_t),
        .REG_INIT      (SPI_REG_INIT),
        .ILA_EN        (ILA_EN),
        .ASYNC_MODE_EN (ASYNC_MODE_EN)
    ) i_axil_reg_file (
        .clk_i       (clk_i),
        .arstn_i     (arstn_i),
        .s_axil      (s_axil),
        .rd_regs_i   (rd_regs),
        .rd_valid_i  (rd_valid),
        .wr_regs_o   (wr_regs),
        .rd_request_o(rd_request),
        .wr_valid_o  (wr_valid)
    );

    axis_spi_master #(
        .DATA_WIDTH   (SPI_DATA_WIDTH),
        .SLAVE_NUM    (SLAVE_NUM),
        .DIVIDER_WIDTH(SPI_DIVIDER_WIDTH),
        .WAIT_WIDTH   (SPI_WAIT_WIDTH)
    ) i_axis_spi_master (
        .select_i     (wr_regs.slave.select),
        .cpol_i       (wr_regs.control.cpol),
        .cpha_i       (wr_regs.control.cpha),
        .clk_divider_i(wr_regs.clk_divider),
        .wait_time_i  (wr_regs.wait_time),
        .m_axis       (spi_rx),
        .s_axis       (spi_tx),
        .m_spi        (m_spi)
    );

    localparam logic [1:0] SIGNAL_EN = 2'b01;
    localparam logic FIFO_ASYNC_MODE = 0;
    localparam RAM_STYLE = "distributed";

    axis_fifo #(
        .FIFO_DEPTH   (FIFO_DEPTH),
        .FIFO_WIDTH   (SPI_DATA_WIDTH),
        .ASYNC_MODE_EN(FIFO_ASYNC_MODE),
        .SIGNAL_EN    (SIGNAL_EN),
        .RAM_STYLE    (RAM_STYLE)
    ) i_axis_fifo_tx (
        .s_axis    (fifo_tx),
        .m_axis    (spi_tx),
        .data_cnt_o(tx_cnt),
        .a_full_o  (),
        .a_empty_o ()
    );

    axis_fifo #(
        .FIFO_DEPTH   (FIFO_DEPTH),
        .FIFO_WIDTH   (SPI_DATA_WIDTH),
        .ASYNC_MODE_EN(FIFO_ASYNC_MODE),
        .SIGNAL_EN    (SIGNAL_EN),
        .RAM_STYLE    (RAM_STYLE)
    ) i_axis_fifo_rx (
        .s_axis    (spi_rx),
        .m_axis    (fifo_rx),
        .data_cnt_o(rx_cnt),
        .a_full_o  (),
        .a_empty_o ()
    );

endmodule
