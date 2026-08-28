`timescale 1ns / 1ps

`include "axil_i2c_class.svh"

module axil_i2c_tb ();

    localparam int FIFO_DEPTH = 128;
    localparam int AXIL_ADDR_WIDTH = 32;
    localparam int AXIL_DATA_WIDTH = 32;

    localparam logic [AXIL_ADDR_WIDTH-1:0] BASE_ADDR = 'h200000;

    localparam int WAT_CYCLES = 250;
    localparam int CLK_PER_NS = 2;
    localparam int RESET_DELAY = 10;

    logic clk_i;
    logic arstn_i;

    wire  scl;
    logic scl_pad_o;
    logic scl_padoen_o;

    wire  sda;
    logic sda_pad_o;
    logic sda_padoen_o;

    axil_if #(
        .ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .DATA_WIDTH(AXIL_DATA_WIDTH)
    ) s_axil (
        .clk_i  (clk_i),
        .arstn_i(arstn_i)
    );

    initial begin
        arstn_i = 1'b0;
        repeat (RESET_DELAY) @(posedge clk_i);
        arstn_i = 1'b1;
        $display("Reset done in: %0t ns\n.", $time());
    end

    initial begin
        clk_i = 1'b0;
        forever begin
            #(CLK_PER_NS / 2) clk_i = ~clk_i;
        end
    end

    initial begin
        axil_i2c_class #(
            .DATA_WIDTH(AXIL_DATA_WIDTH),
            .ADDR_WIDTH(AXIL_ADDR_WIDTH),
            .BASE_ADDR (BASE_ADDR)
        ) i2c;
        i2c = new(s_axil);
        i2c.i2c_start();
        #WAT_CYCLES;
        $stop;
    end

    initial begin
        $dumpfile("axil_i2c_tb.vcd");
        $dumpvars(0, axil_i2c_tb);
    end

    axil_i2c #(
        .FIFO_DEPTH     (FIFO_DEPTH),
        .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH),
        .AXIL_ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .ILA_EN         (0),
        .ASYNC_MODE_EN  (0)
    ) i_axil_i2c (
        .clk_i       (clk_i),
        .arstn_i     (arstn_i),
        .scl_pad_i   (scl),
        .scl_pad_o   (scl_pad_o),
        .scl_padoen_o(scl_padoen_o),
        .sda_pad_i   (sda),
        .sda_pad_o   (sda_pad_o),
        .sda_padoen_o(sda_padoen_o),
        .s_axil      (s_axil)
    );

    assign scl = scl_padoen_o ? 1'bz : scl_pad_o;
    assign sda = sda_padoen_o ? 1'bz : sda_pad_o;

    i2c_slave_model #(
        .I2C_ADR(I2C_ADR)
    ) i_i2c_slave_model (
        .scl(scl),
        .sda(sda)
    );

endmodule
