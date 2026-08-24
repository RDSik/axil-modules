/* verilator lint_off TIMESCALEMOD */
`include "../rtl/uart_pkg.svh"

module axil_uart
    import uart_pkg::*;
#(
    parameter int   FIFO_DEPTH      = 128,
    parameter int   AXIL_ADDR_WIDTH = 32,
    parameter int   AXIL_DATA_WIDTH = 32,
    parameter logic ILA_EN          = 0,
    parameter logic ASYNC_MODE_EN   = 0
) (
    input logic clk_i,
    input logic arstn_i,

    input  logic uart_rx_i,
    output logic uart_tx_o,

    axil_if.slave s_axil
);

    uart_regs_t                    rd_regs;
    uart_regs_t                    wr_regs;

    logic       [UART_REG_NUM-1:0] rd_request;
    logic       [UART_REG_NUM-1:0] rd_valid;
    logic       [UART_REG_NUM-1:0] wr_valid;

    logic                          tx_reset;
    logic                          rx_reset;

    assign tx_reset = wr_regs.control.tx_reset;
    assign rx_reset = wr_regs.control.rx_reset;

    axis_if #(
        .DATA_WIDTH(UART_DATA_WIDTH)
    ) fifo_tx (
        .clk_i  (clk_i),
        .arstn_i(~tx_reset)
    );

    axis_if #(
        .DATA_WIDTH(UART_DATA_WIDTH)
    ) fifo_rx (
        .clk_i  (clk_i),
        .arstn_i(~rx_reset)
    );

    axis_if #(
        .DATA_WIDTH(UART_DATA_WIDTH)
    ) uart_tx (
        .clk_i  (clk_i),
        .arstn_i(~tx_reset)
    );

    axis_if #(
        .DATA_WIDTH(UART_DATA_WIDTH)
    ) uart_rx (
        .clk_i  (clk_i),
        .arstn_i(~rx_reset)
    );

    logic parity_err;

    always_comb begin
        rd_valid                     = '1;
        rd_regs                      = wr_regs;

        rd_regs.param.data_width     = UART_DATA_WIDTH;
        rd_regs.param.fifo_depth     = FIFO_DEPTH;
        rd_regs.param.reg_num        = UART_REG_NUM;

        rd_regs.status.rx_fifo_empty = ~fifo_rx.tvalid;
        rd_regs.status.tx_fifo_empty = ~uart_tx.tvalid;
        rd_regs.status.rx_fifo_full  = ~uart_rx.tready;
        rd_regs.status.tx_fifo_full  = ~fifo_tx.tready;
        rd_regs.status.parity_err    = parity_err;

        rd_regs.rx.data              = fifo_rx.tdata;
    end

    assign fifo_tx.tdata  = wr_regs.tx.data;
    assign fifo_tx.tvalid = wr_valid[UART_TX_DATA_REG_POS];
    assign fifo_rx.tready = rd_request[UART_RX_DATA_REG_POS];

    axil_reg_file_wrap #(
        .REG_DATA_WIDTH(AXIL_DATA_WIDTH),
        .REG_ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .REG_NUM       (UART_REG_NUM),
        .reg_t         (uart_regs_t),
        .REG_INIT      (UART_REG_INIT),
        .ILA_EN        (ILA_EN),
        .ASYNC_MODE_EN (ASYNC_MODE_EN)
    ) i_axil_reg_file (
        .clk_i       (clk_i),
        .arstn_i     (arstn_i),
        .s_axil      (s_axil),
        .rd_regs_i   (rd_regs),
        .rd_valid_i  (rd_valid),
        .rd_request_o(rd_request),
        .wr_regs_o   (wr_regs),
        .wr_valid_o  (wr_valid)
    );

    axis_uart_tx #(
        .DATA_WIDTH   (UART_DATA_WIDTH),
        .DIVIDER_WIDTH(UART_DIVIDER_WIDTH)
    ) i_axis_uart_tx (
        .clk_divider_i(wr_regs.clk_divider),
        .parity_odd_i (wr_regs.control.parity_odd),
        .parity_even_i(wr_regs.control.parity_even),
        .uart_tx_o    (uart_tx_o),
        .s_axis       (uart_tx)
    );

    axis_uart_rx #(
        .DATA_WIDTH   (UART_DATA_WIDTH),
        .DIVIDER_WIDTH(UART_DIVIDER_WIDTH)
    ) i_axis_uart_rx (
        .clk_divider_i(wr_regs.clk_divider),
        .parity_odd_i (wr_regs.control.parity_odd),
        .parity_even_i(wr_regs.control.parity_even),
        .uart_rx_i    (uart_rx_i),
        .parity_err_o (parity_err),
        .m_axis       (uart_rx)
    );

    localparam logic FIFO_ASYNC_MODE = 0;
    localparam RAM_STYLE = "distributed";

    axis_fifo #(
        .FIFO_DEPTH   (FIFO_DEPTH),
        .FIFO_WIDTH   (UART_DATA_WIDTH),
        .ASYNC_MODE_EN(FIFO_ASYNC_MODE),
        .SIGNAL_EN    ('0),
        .RAM_STYLE    (RAM_STYLE)
    ) i_axis_fifo_tx (
        .s_axis   (fifo_tx),
        .m_axis   (uart_tx),
        .a_full_o (),
        .a_empty_o()
    );

    axis_fifo #(
        .FIFO_DEPTH   (FIFO_DEPTH),
        .FIFO_WIDTH   (UART_DATA_WIDTH),
        .ASYNC_MODE_EN(FIFO_ASYNC_MODE),
        .SIGNAL_EN    ('0),
        .RAM_STYLE    (RAM_STYLE)
    ) i_axis_fifo_rx (
        .s_axis   (uart_rx),
        .m_axis   (fifo_rx),
        .a_full_o (),
        .a_empty_o()
    );

endmodule
