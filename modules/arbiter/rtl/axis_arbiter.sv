/* verilator lint_off TIMESCALEMOD */
module axis_arbiter #(
    parameter int unsigned MASTER_NUM = 4
) (
    axis_if.slave  s_axis[MASTER_NUM-1:0],
    axis_if.master m_axis
);

    localparam int DATA_WIDTH = s_axis.DATA_WIDTH;
    localparam int DEST_WIDTH = $clog2(MASTER_NUM);

    logic clk_i;arstn_i
    logic arstn_i;

    assign clk_i   = s_axis.clk_i;
    assign arstn_i = s_axis.arstn_i;

    logic [MASTER_NUM-1:0][DATA_WIDTH-1:0] s_axis_tdata_reg;
    logic [MASTER_NUM-1:0]                 s_axis_tvalid_reg;
    logic [MASTER_NUM-1:0]                 s_axis_tlast_reg;
    logic                                  m_axis_tready;
    logic [MASTER_NUM-1:0]                 grant;

    assign m_axis_tready = m_axis_tready_i | ~m_axis_tvalid_o;

    for (genvar i = 0; i < MASTER_NUM; i++) begin : g_stages
        logic free_reg;
        assign free_reg           = ~s_axis_tvalid_reg[i] | (m_axis_tready & grant[i]);
        assign s_axis_tready_o[i] = free_reg;

        always_ff @(posedge clk_i or negedge arstn_i) begin
            if (~arstn_i) begin
                s_axis_tvalid_reg[i] <= 1'b0;
            end else if (free_reg) begin
                s_axis_tvalid_reg[i] <= s_axis_tvalid_i[i];
            end

            if (free_reg) begin
                s_axis_tdata_reg[i] <= s_axis_tdata_i[i];
                s_axis_tlast_reg[i] <= s_axis_tlast_i[i];
            end
        end
    end

    logic                          ack;
    logic                          grant_valid;
    logic [$clog2(MASTER_NUM)-1:0] grant_indx;

    assign ack = m_axis_tready & grant_valid & s_axis_tlast_reg[grant_indx];

    round_robin_arbiter #(
        .MASTER_NUM(MASTER_NUM)
    ) i_round_robin_arbiter (
        .clk_i        (clk_i),
        .srst_i       (~arstn_i),
        .ack_i        (ack),
        .req_i        (s_axis_tvalid_reg),
        .grant_valid_o(grant_valid),
        .grant_o      (grant),
        .indx_o       (grant_indx)
    );

    logic [DATA_WIDTH-1:0] m_axis_tdata_reg;
    logic [DEST_WIDTH-1:0] m_axis_tdest_reg;
    logic                  m_axis_tvalid_reg;
    logic                  m_axis_tlast_reg;

    always_ff @(posedge clk_i or negedge arstn_i) begin
            if (~arstn_i) begin
            m_axis_tvalid_reg <= 1'b0;
        end else if (m_axis_tready) begin
            m_axis_tvalid_reg <= grant_valid;
        end

        if (m_axis_tready & grant_valid) begin
            m_axis_tdata_reg <= s_axis_tdata_reg[grant_indx];
            m_axis_tdest_reg <= DEST_WIDTH'(grant_indx);
            m_axis_tlast_reg <= s_axis_tlast_reg[grant_indx];
        end
    end

    assign m_axis_tdata_o  = m_axis_tdata_reg;
    assign m_axis_tdest_o  = m_axis_tdest_reg;
    assign m_axis_tlast_o  = m_axis_tlast_reg;
    assign m_axis_tvalid_o = m_axis_tvalid_reg;

endmodule

