/* verilator lint_off TIMESCALEMOD */
module axis_dw_conv #(
    parameter logic [1:0] SIGNAL_EN = '0
) (
    axis_if.master m_axis,
    axis_if.slave  s_axis
);

    logic clk_i;
    logic arstn_i;

    assign clk_i   = s_axis.clk_i;
    assign arstn_i = s_axis.arstn_i;

    localparam int S_DATA_WIDTH = s_axis.DATA_WIDTH;
    localparam int M_DATA_WIDTH = m_axis.DATA_WIDTH;

    localparam int S_KEEP_WIDTH = s_axis.KEEP_WIDTH;
    localparam int M_KEEP_WIDTH = m_axis.KEEP_WIDTH;

    logic s_handshake;
    logic m_handshake;

    assign s_handshake = s_axis.tvalid & s_axis.tready;
    assign m_handshake = m_axis.tvalid & m_axis.tready;

    if (S_DATA_WIDTH > M_DATA_WIDTH) begin : g_down_size
        localparam int RATIO = S_DATA_WIDTH / M_DATA_WIDTH;

        logic [$clog2(RATIO)-1:0]                   cnt;
        logic                                       cnt_done;
        logic                                       busy;
        logic                                       m_axis_tlast;
        logic [        RATIO-1:0][M_DATA_WIDTH-1:0] m_axis_tdata;
        logic [        RATIO-1:0][M_KEEP_WIDTH-1:0] m_axis_tkeep;

        assign cnt_done = (cnt == RATIO - 1);

        always_ff @(posedge clk_i or negedge arstn_i) begin
            if (~arstn_i) begin
                cnt <= '0;
            end else if (m_handshake) begin
                if (cnt_done) begin
                    cnt <= '0;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
        end

        always_ff @(posedge clk_i or negedge arstn_i) begin
            if (~arstn_i) begin
                busy <= 1'b0;
            end else begin
                if (s_handshake) begin
                    busy <= 1'b1;
                end else if (m_handshake & cnt_done) begin
                    busy <= 1'b0;
                end
            end
        end

        if (SIGNAL_EN[0]) begin : g_tlast_en
            always_ff @(posedge clk_i or negedge arstn_i) begin
                if (~arstn_i) begin
                    m_axis_tlast <= '0;
                end else if (s_handshake) begin
                    m_axis_tlast <= s_axis.tlast;
                end
            end
        end else begin : g_tlast_disable
            assign m_axis_tlast = '0;
        end

        if (SIGNAL_EN[1]) begin : g_tkeep_en
            always_ff @(posedge clk_i or negedge arstn_i) begin
                if (~arstn_i) begin
                    m_axis_tkeep <= '0;
                end else if (s_handshake) begin
                    m_axis_tkeep <= s_axis.tkeep;
                end
            end
        end else begin : g_keep_disable
            assign m_axis_tkeep = '0;
        end

        always_ff @(posedge clk_i or negedge arstn_i) begin
            if (~arstn_i) begin
                m_axis_tdata <= '0;
            end else if (s_handshake) begin
                m_axis_tdata <= s_axis.tdata;
            end
        end

        assign m_axis.tdata  = m_axis_tdata[cnt];
        assign m_axis.tlast  = m_axis_tlast & cnt_done;
        assign m_axis.tkeep  = m_axis_tkeep[cnt];
        assign m_axis.tvalid = busy;
        assign s_axis.tready = ~busy;
    end else if (S_DATA_WIDTH < M_DATA_WIDTH) begin : g_up_size

        localparam int RATIO = M_DATA_WIDTH / S_DATA_WIDTH;

        logic [$clog2(RATIO)-1:0]                   cnt;
        logic                                       cnt_done;
        logic                                       done;
        logic                                       flush;
        logic                                       m_axis_tlast;
        logic [        RATIO-1:0][S_DATA_WIDTH-1:0] m_axis_tdata;
        logic [        RATIO-1:0][S_KEEP_WIDTH-1:0] m_axis_tkeep;

        assign flush    = cnt_done | (TLAST_EN & s_axis.tlast);
        assign cnt_done = (cnt == RATIO - 1);

        always_ff @(posedge clk_i or negedge arstn_i) begin
            if (~arstn_i) begin
                cnt <= '0;
            end else if (s_handshake) begin
                if (flush) begin
                    cnt <= '0;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
        end

        always_ff @(posedge clk_i or negedge arstn_i) begin
            if (~arstn_i) begin
                done <= 1'b0;
            end else begin
                if (m_handshake) begin
                    done <= 1'b0;
                end else if (s_handshake & flush) begin
                    done <= 1'b1;
                end
            end
        end

        if (SIGNAL_EN[0]) begin : g_tlast_en
            always_ff @(posedge clk_i or negedge arstn_i) begin
                if (~arstn_i) begin
                    m_axis_tlast <= '0;
                end else begin
                    if (m_handshake) begin
                        m_axis_tlast <= '0;
                    end else if (s_handshake & ~m_axis_tlast) begin
                        m_axis_tlast <= s_axis.tlast;
                    end
                end
            end
        end else begin : g_tlast_disable
            assign m_axis_tlast = '0;
        end

        if (SIGNAL_EN[1]) begin : g_tkeep_en
            always_ff @(posedge clk_i or negedge arstn_i) begin
                if (~arstn_i) begin
                    m_axis_tkeep <= '0;
                end else begin
                    if (m_handshake) begin
                        m_axis_tkeep <= '0;
                    end else if (s_handshake) begin
                        m_axis_tkeep[cnt] <= s_axis.tkeep;
                    end
                end
            end
        end else begin : g_tkeep_disable
            assign m_axis_tkeep = '0;
        end

        always_ff @(posedge clk_i or negedge arstn_i) begin
            if (~arstn_i) begin
                m_axis_tdata <= '0;
            end else if (s_handshake) begin
                m_axis_tdata[cnt] <= s_axis.tdata;
            end
        end

        assign m_axis.tdata  = m_axis_tdata;
        assign m_axis.tlast  = m_axis_tlast & done;
        assign m_axis.tkeep  = m_axis_tkeep;
        assign m_axis.tvalid = done;
        assign s_axis.tready = ~done;
    end else begin : g_bypass
        assign m_axis.tvalid = s_axis.tvalid;
        assign m_axis.tdata  = s_axis.tdata;
        assign s_axis.tready = m_axis.tready;
        assign m_axis.tlast  = s_axis.tlast;
        assign m_axis.tkeep  = s_axis.tkeep;
    end

endmodule
