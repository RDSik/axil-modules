/* verilator lint_off TIMESCALEMOD */
module axis_dw_conv_wrap #(
    parameter int         FIFO_DEPTH    = 128,
    parameter int         CDC_REG_NUM   = 3,
    parameter logic       FIFO_FIRST    = 1,
    parameter logic       ASYNC_MODE_EN = 0,
    parameter logic [1:0] SIGNAL_EN     = '0
) (
    axis_if.master m_axis,
    axis_if.slave  s_axis
);

    logic s_clk_i;
    logic s_arstn_i;
    logic m_clk_i;
    logic m_arstn_i;

    assign s_clk_i   = s_axis.clk_i;
    assign s_arstn_i = s_axis.arstn_i;
    assign m_clk_i   = m_axis.clk_i;
    assign m_arstn_i = m_axis.arstn_i;

    localparam int S_DATA_WIDTH = s_axis.DATA_WIDTH;
    localparam int M_DATA_WIDTH = m_axis.DATA_WIDTH;

    if (ASYNC_MODE_EN) begin : g_async
        if (FIFO_FIRST) begin : g_fast_to_slow
            axis_if #(
                .DATA_WIDTH(S_DATA_WIDTH)
            ) axis (
                .clk_i  (m_clk_i),
                .arstn_i(m_arstn_i)
            );

            axis_fifo #(
                .FIFO_DEPTH   (FIFO_DEPTH),
                .FIFO_WIDTH   (S_DATA_WIDTH),
                .CDC_REG_NUM  (CDC_REG_NUM),
                .SIGNAL_EN    (SIGNAL_EN),
                .ASYNC_MODE_EN(ASYNC_MODE_EN)
            ) i_axis_fifo (
                .s_axis   (s_axis),
                .m_axis   (axis),
                .a_full_o (),
                .a_empty_o()
            );

            axis_dw_conv #(
                .SIGNAL_EN(SIGNAL_EN)
            ) i_axis_dw_conv (
                .m_axis(m_axis),
                .s_axis(axis)
            );
        end else begin : g_slow_to_fast
            axis_if #(
                .DATA_WIDTH(M_DATA_WIDTH)
            ) axis (
                .clk_i  (s_clk_i),
                .arstn_i(s_arstn_i)
            );

            axis_dw_conv #(
                .SIGNAL_EN(SIGNAL_EN)
            ) i_axis_dw_conv (
                .m_axis(axis),
                .s_axis(s_axis)
            );

            axis_fifo #(
                .FIFO_DEPTH   (FIFO_DEPTH),
                .FIFO_WIDTH   (M_DATA_WIDTH),
                .CDC_REG_NUM  (CDC_REG_NUM),
                .SIGNAL_EN    (SIGNAL_EN),
                .ASYNC_MODE_EN(ASYNC_MODE_EN)
            ) i_axis_fifo (
                .s_axis   (axis),
                .m_axis   (m_axis),
                .a_full_o (),
                .a_empty_o()
            );
        end
    end else begin : g_sync
        axis_dw_conv #(
            .SIGNAL_EN(SIGNAL_EN)
        ) i_axis_dw_conv (
            .m_axis(m_axis),
            .s_axis(s_axis)
        );
    end

endmodule
