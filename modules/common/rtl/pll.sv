module pll #(
    parameter real CLK_FREQ    = 50*10**6,
    parameter real CLK_MULT    = 5,
    parameter real CLK0_DIVIDE = 1,
    parameter real CLK1_DIVIDE = 1,
    parameter real CLK2_DIVIDE = 1,
    parameter real CLK3_DIVIDE = 1,
    parameter real CLK4_DIVIDE = 1,
    parameter real CLK5_DIVIDE = 1
) (
    input logic clk_i,
    input logic rst_i,

    output logic clk0_o,
    output logic clk1_o,
    output logic clk2_o,
    output logic clk3_o,
    output logic clk4_o,
    output logic clk5_o,

    output logic locked_o
);

    localparam real CLK_PERIOD = 10 ** 9 / CLK_FREQ;

    logic clk_fbin;
    logic clk_fbout;

    logic clk0_out;
    logic clk1_out;
    logic clk2_out;
    logic clk3_out;
    logic clk4_out;
    logic clk5_out;

    PLLE2_BASE #(
        .BANDWIDTH         ("OPTIMIZED"),  // Jitter programming (OPTIMIZED, HIGH, LOW)
        .REF_JITTER1       (0.0),          // Reference input jitter in UI (0.000-0.999).
        .STARTUP_WAIT      ("FALSE"),      // Delays DONE until MMCM is locked (FALSE, TRUE)
        .DIVCLK_DIVIDE     (1),            // Master division value (1-106)
        .CLKFBOUT_MULT     (CLK_MULT),     // Multiply value for all CLKOUT (2.000-64.000).
        .CLKFBOUT_PHASE    (0.000),        // Phase offset in degrees of CLKFB (-360.000-360.000).
        // CLKIN_PERIOD: Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
        .CLKIN1_PERIOD     (CLK_PERIOD),
        // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for CLKOUT (1-128)
        .CLKOUT0_DIVIDE    (CLK0_DIVIDE),
        .CLKOUT1_DIVIDE    (CLK1_DIVIDE),
        .CLKOUT2_DIVIDE    (CLK2_DIVIDE),
        .CLKOUT3_DIVIDE    (CLK3_DIVIDE),
        .CLKOUT4_DIVIDE    (CLK4_DIVIDE),
        .CLKOUT5_DIVIDE    (CLK5_DIVIDE),
        // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for CLKOUT outputs (0.01-0.99).
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT1_DUTY_CYCLE(0.500),
        .CLKOUT2_DUTY_CYCLE(0.500),
        .CLKOUT3_DUTY_CYCLE(0.500),
        .CLKOUT4_DUTY_CYCLE(0.500),
        .CLKOUT5_DUTY_CYCLE(0.500),
        // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for CLKOUT outputs (-360.000-360.000).
        .CLKOUT0_PHASE     (0.000),
        .CLKOUT1_PHASE     (0.000),
        .CLKOUT2_PHASE     (0.000),
        .CLKOUT3_PHASE     (0.000),
        .CLKOUT4_PHASE     (0.000),
        .CLKOUT5_PHASE     (0.000)
    ) i_pll (
        .CLKOUT0 (clk0_out),   // 1-bit output: CLKOUT0
        .CLKOUT1 (clk1_out),   // 1-bit output: CLKOUT1
        .CLKOUT2 (clk2_out),   // 1-bit output: CLKOUT2
        .CLKOUT3 (clk3_out),   // 1-bit output: CLKOUT3
        .CLKOUT4 (clk4_out),   // 1-bit output: CLKOUT4
        .CLKOUT5 (clk5_out),   // 1-bit output: CLKOUT5
        // Feedback Clocks: 1-bit (each) output: Clock feedback ports
        .CLKFBOUT(clk_fbout),  // 1-bit output: Feedback clock
        // Status Ports: 1-bit (each) output: MMCM status ports
        .LOCKED  (locked_o),   // 1-bit output: LOCK
        // Clock Inputs: 1-bit (each) input: Clock inputs
        .CLKIN1  (clk_i),      // 1-bit input: Clock
        // Control Ports: 1-bit (each) input: MMCM control ports
        .PWRDWN  ('0),         // 1-bit input: Power-down
        .RST     (rst_i),      // 1-bit input: Reset
        // Feedback Clocks: 1-bit (each) input: Clock feedback ports
        .CLKFBIN (clk_fbin)    // 1-bit input: Feedback clock
    );

    BUFG i_bufg_fbin (
        .I(clk_fbout),  // 1-bit input: Clock input
        .O(clk_fbin)    // 1-bit output: Clock output
    );

    BUFG i_clk0_out (
        .I(clk0_out),  // 1-bit input: Clock input
        .O(clk0_o)     // 1-bit output: Clock output
    );

    BUFG i_clk1_out (
        .I(clk1_out),  // 1-bit input: Clock input
        .O(clk1_o)     // 1-bit output: Clock output
    );

    BUFG i_clk2_out (
        .I(clk2_out),  // 1-bit input: Clock input
        .O(clk2_o)     // 1-bit output: Clock output
    );

    BUFG i_clk3_out (
        .I(clk3_out),  // 1-bit input: Clock input
        .O(clk3_o)     // 1-bit output: Clock output
    );

    BUFG i_clk4_out (
        .I(clk4_out),  // 1-bit input: Clock input
        .O(clk4_o)     // 1-bit output: Clock output
    );

    BUFG i_clk5_out (
        .I(clk5_out),  // 1-bit input: Clock input
        .O(clk5_o)     // 1-bit output: Clock output
    );

endmodule
