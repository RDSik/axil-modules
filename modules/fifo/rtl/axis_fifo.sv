/* verilator lint_off TIMESCALEMOD */
module axis_fifo #(
    parameter int         FIFO_WIDTH    = 32,
    parameter int         FIFO_DEPTH    = 128,
    parameter int         PIPE_STAGE    = 5,
    parameter int         CDC_REG_NUM   = 2,
    parameter logic       ASYNC_MODE_EN = 0,
    parameter logic [1:0] SIGNAL_EN     = '0,
    parameter             RAM_STYLE     = "block"
) (
    axis_if.slave  s_axis,
    axis_if.master m_axis,

    output logic a_full_o,
    output logic a_empty_o,

    output logic [$clog2(FIFO_DEPTH):0] data_cnt_o,

    output logic [$clog2(FIFO_DEPTH):0] wr_data_cnt_o,
    output logic [$clog2(FIFO_DEPTH):0] rd_data_cnt_o
);

    localparam int FULL_WIDTH = FIFO_WIDTH + (SIGNAL_EN[0] * 1) + (SIGNAL_EN[1] * FIFO_WIDTH / 8);

    logic [FULL_WIDTH-1:0] wr_data;
    logic [FULL_WIDTH-1:0] rd_data;
    logic                  pop;
    logic                  push;
    logic                  empty;
    logic                  full;

    if (SIGNAL_EN[0] & SIGNAL_EN[1]) begin : g_all_enable
        assign wr_data = {s_axis.tlast, s_axis.tkeep, s_axis.tdata};
        assign {m_axis.tlast, m_axis.tkeep, m_axis.tdata} = rd_data;
    end else if (SIGNAL_EN[0]) begin : g_tlast_en
        assign wr_data = {s_axis.tlast, s_axis.tdata};
        assign {m_axis.tlast, m_axis.tdata} = rd_data;
    end else if (SIGNAL_EN[1]) begin : g_tkeep_en
        assign wr_data = {s_axis.tkeep, s_axis.tdata};
        assign {m_axis.tkeep, m_axis.tdata} = rd_data;
    end else begin : g_all_disable
        assign wr_data = s_axis.tdata;
        assign m_axis.tdata = rd_data;
    end

    assign s_axis.tready = ~full;
    assign m_axis.tvalid = ~empty;

    assign push = s_axis.tvalid & s_axis.tready;
    assign pop = m_axis.tvalid & m_axis.tready;

    if (ASYNC_MODE_EN) begin : g_async_fifo
        async_fifo #(
            .FIFO_WIDTH (FULL_WIDTH),
            .FIFO_DEPTH (FIFO_DEPTH),
            .PIPE_STAGE (PIPE_STAGE),
            .CDC_REG_NUM(CDC_REG_NUM),
            .RAM_STYLE  ("distributed")
        ) i_async_fifo (
            .wr_clk_i     (s_axis.clk_i),
            .wr_rst_i     (~s_axis.arstn_i),
            .wr_data_i    (wr_data),
            .rd_clk_i     (m_axis.clk_i),
            .rd_rst_i     (~m_axis.arstn_i),
            .rd_data_o    (rd_data),
            .push_i       (push),
            .pop_i        (pop),
            .empty_o      (empty),
            .full_o       (full),
            .a_empty_o    (a_empty_o),
            .a_full_o     (a_full_o),
            .wr_data_cnt_o(wr_data_cnt_o),
            .rd_data_cnt_o(rd_data_cnt_o)
        );

        assign data_cnt_o = '0;
    end else begin : g_sync_fifo
        sync_fifo #(
            .FIFO_WIDTH(FULL_WIDTH),
            .FIFO_DEPTH(FIFO_DEPTH),
            .PIPE_STAGE(PIPE_STAGE),
            .RAM_STYLE (RAM_STYLE)
        ) i_sync_fifo (
            .clk_i     (s_axis.clk_i),
            .rst_i     (~s_axis.arstn_i),
            .data_i    (wr_data),
            .data_o    (rd_data),
            .push_i    (push),
            .pop_i     (pop),
            .empty_o   (empty),
            .full_o    (full),
            .a_empty_o (a_empty_o),
            .a_full_o  (a_full_o),
            .data_cnt_o(data_cnt_o)
        );

        assign wr_data_cnt_o = data_cnt_o;
        assign rd_data_cnt_o = data_cnt_o;
    end

endmodule
