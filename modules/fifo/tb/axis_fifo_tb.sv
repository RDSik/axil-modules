`timescale 1ns / 1ps

`include "../../verification/tb/test_pkg.svh"

module axis_fifo_tb ();

    import test_pkg::*;

    localparam int FIFO_WIDTH = 16;
    localparam int FIFO_DEPTH = 4;
    localparam int CDC_REG_NUM = 3;
    localparam int PIPE_STAGE = 3;
    localparam logic ASYNC_MODE_EN = 0;
    localparam logic [1:0] SIGNAL_EN = 2'b01;
    localparam RAM_STYLE = "block";

    localparam int M_CLK_PER = 2;
    localparam int S_CLK_PER = 2;
    localparam int M_RESET_DELAY = 10;
    localparam int S_RESET_DELAY = 10;

    logic s_axis_clk;
    logic m_axis_clk;
    logic s_axis_arstn;
    logic m_axis_arstn;
    logic a_full;
    logic a_empty;

    axis_if #(
        .DATA_WIDTH(FIFO_WIDTH)
    ) s_axis (
        .clk_i  (s_axis_clk),
        .arstn_i(s_axis_arstn)
    );

    axis_if #(
        .DATA_WIDTH(FIFO_WIDTH)
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
            .S_DATA_WIDTH(FIFO_WIDTH),
            .M_DATA_WIDTH(FIFO_WIDTH),
            .TLAST_EN    (SIGNAL_EN[0])
        ) env;
        env = new(s_axis, m_axis);
        env.run();
    end

    axis_fifo #(
        .FIFO_DEPTH   (FIFO_DEPTH),
        .FIFO_WIDTH   (FIFO_WIDTH),
        .PIPE_STAGE   (PIPE_STAGE),
        .ASYNC_MODE_EN(ASYNC_MODE_EN),
        .CDC_REG_NUM  (CDC_REG_NUM),
        .RAM_STYLE    (RAM_STYLE),
        .SIGNAL_EN    (SIGNAL_EN)
    ) dut (
        .s_axis   (m_axis),
        .m_axis   (s_axis),
        .a_full_o (a_full),
        .a_empty_o(a_empty)
    );

endmodule
