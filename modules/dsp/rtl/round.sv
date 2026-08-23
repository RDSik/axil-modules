/* verilator lint_off TIMESCALEMOD */

// Convergent Rounding (LSB Correction Technique)
// 3 latency and CH_NUM optional dsp

module round #(
    parameter logic ROUND_TYPE     = 1,     // 1 - even, 0 - odd
    parameter int   CH_NUM         = 2,
    parameter int   IN_DATA_WIDTH  = 32,
    parameter int   OUT_DATA_WIDTH = 16,
    parameter       USE_DSP        = "yes"
) (
    input logic clk_i,
    input logic rst_i,

    input logic [CH_NUM-1:0][IN_DATA_WIDTH-1:0] tdata_i,
    input logic                                 tvalid_i,

    output logic [CH_NUM-1:0][OUT_DATA_WIDTH-1:0] tdata_o,
    output logic                                  tvalid_o
);

    if (IN_DATA_WIDTH == OUT_DATA_WIDTH) begin : g_equal
        assign tdata_o  = tdata_i;
        assign tvalid_o = tvalid_i;
    end else begin : g_round
        localparam int FRAC_WIDTH = IN_DATA_WIDTH - OUT_DATA_WIDTH;

        for (genvar i = 0; i < CH_NUM; i++) begin : g_ch
            logic [FRAC_WIDTH-1:0] add;
            assign add = (ROUND_TYPE) ? {1'b1, {{FRAC_WIDTH - 1} {1'b0}}} : {1'b0, {{FRAC_WIDTH - 1} {1'b1}}};

            logic [FRAC_WIDTH-1:0] pattern;
            assign pattern = (ROUND_TYPE) ? {FRAC_WIDTH{1'b0}} : {FRAC_WIDTH{1'b1}};

            (* use_dsp = USE_DSP *) logic signed [IN_DATA_WIDTH-1:0] sum_reg;
            logic signed [IN_DATA_WIDTH-1:0] sum;
            logic signed [IN_DATA_WIDTH-1:0] data_in;
            logic                            pattern_detect;

            assign sum = data_in + {{OUT_DATA_WIDTH{1'b0}}, add}; // pre-adder

            always_ff @(posedge clk_i) begin // dsp
                data_in        <= signed'(tdata_i[i]); // input reg
                sum_reg        <= sum; // pre-adder reg
                pattern_detect <= (sum[FRAC_WIDTH-1:0] == pattern); // pattern_detect
            end

            logic signed [OUT_DATA_WIDTH-1:0] data_out;

            always_ff @(posedge clk_i) begin
                if (pattern_detect) begin
                    data_out <= {sum_reg[IN_DATA_WIDTH-1:FRAC_WIDTH+1], ~ROUND_TYPE};
                end else begin
                    data_out <= sum_reg[IN_DATA_WIDTH-1:FRAC_WIDTH];
                end
            end

            assign tdata_o[i] = data_out;
        end

        localparam int ROUND_LATENCY = 3;

        shift_reg #(
            .DATA_WIDTH($bits(tvalid_i)),
            .DELAY     (ROUND_LATENCY),
            .RESET_EN  (1),
            .SRL_STYLE ("register")
        ) i_shift_reg (
            .clk_i (clk_i),
            .rst_i (rst_i),
            .en_i  (1'b1),
            .data_i(tvalid_i),
            .data_o(tvalid_o)
        );
    end

endmodule
