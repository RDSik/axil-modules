`timescale 1ns / 1ps

`include "../../verification/tb/test_pkg.svh"

module axis_dw_conv_tb ();

    import test_pkg::*;

    localparam int S_DATA_WIDTH = 8;
    localparam int M_DATA_WIDTH = 32;
    localparam int RESET_DELAY = 10;
    localparam int CLK_PER_NS = 2;
    localparam int FIFO_DEPTH = 16;
    localparam int CDC_REG_NUM = 3;
    localparam logic ASYNC_MODE_EN = 1;
    localparam logic [1:0] SIGNAL_EN = 2'b01;

    localparam int M_CLK_PER = 2;
    localparam int S_CLK_PER = 4;
    localparam int M_RESET_DELAY = 10;
    localparam int S_RESET_DELAY = 10;

    localparam logic FIFO_FIRST = (S_CLK_PER > M_CLK_PER);

    logic s_axis_clk;
    logic m_axis_clk;
    logic s_axis_arstn;
    logic m_axis_arstn;

    axis_if #(
        .DATA_WIDTH(S_DATA_WIDTH)
    ) s_axis (
        .clk_i  (s_axis_clk),
        .arstn_i(s_axis_arstn)
    );

    axis_if #(
        .DATA_WIDTH(M_DATA_WIDTH)
    ) m_axis (
        .clk_i  (m_axis_clk),
        .arstn_i(m_axis_arstn)
    );

    initial begin
        s_axis_arstn = 1'b0;
        repeat (S_RESET_DELAY) @(posedge s_axis_clk);
        s_axis_arstn = 1'b1;
        $display("Master reset done in: %0t ns\n.", $time());
    end

    initial begin
        s_axis_clk = 1'b0;
        forever begin
            #(S_CLK_PER / 2) s_axis_clk = ~s_axis_clk;
        end
    end

    initial begin
        m_axis_arstn = 1'b0;
        repeat (M_RESET_DELAY) @(posedge m_axis_clk);
        m_axis_arstn = 1'b1;
        $display("Slave reset done in: %0t ns\n.", $time());
    end

    initial begin
        m_axis_clk = 1'b0;
        forever begin
            #(M_CLK_PER / 2) m_axis_clk = ~m_axis_clk;
        end
    end

    initial begin
        env_base #(
            .S_DATA_WIDTH(M_DATA_WIDTH),
            .M_DATA_WIDTH(S_DATA_WIDTH),
            .TLAST_EN    (SIGNAL_EN[0])
        ) env;
        env = new(s_axis, m_axis);
        env.run();
    end

    initial begin
        $dumpfile("axis_dw_conv_tb.vcd");
        $dumpvars(0, axis_dw_conv_tb);
    end

    axis_dw_conv_wrap #(
        .FIFO_DEPTH   (FIFO_DEPTH),
        .CDC_REG_NUM  (CDC_REG_NUM),
        .FIFO_FIRST   (FIFO_FIRST),
        .ASYNC_MODE_EN(ASYNC_MODE_EN),
        .SIGNAL_EN    (SIGNAL_EN)
    ) dut (
        .m_axis(s_axis),
        .s_axis(m_axis)
    );

endmodule
