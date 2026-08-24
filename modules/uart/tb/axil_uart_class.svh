`ifndef AXIL_UART_SVH
`define AXIL_UART_SVH

`include "modules/uart/rtl/uart_pkg.svh"
`include "modules/verification/tb/axil_env.svh"

import uart_pkg::*;

class axil_uart_class #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter logic [ADDR_WIDTH-1:0] BASE_ADDR = 'h200000
);

    localparam int ADDR_OFFSET = DATA_WIDTH / 8;
    localparam int BYTES_NUM = 8;
    localparam int CLK_DIV = 10;

    axil_env #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) env;

    virtual axil_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) s_axil;

    function new(
    virtual axil_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
    ) s_axil);
        this.s_axil = s_axil;
        env         = new(s_axil);
    endfunction

    task automatic uart_read_regs();
        uart_regs_t uart_regs;
        begin
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * UART_CONTROL_REG_POS, uart_regs.control);
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * UART_CONTROL_REG_POS, uart_regs.clk_divider);
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * UART_TX_DATA_REG_POS, uart_regs.tx);
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * UART_RX_DATA_REG_POS, uart_regs.rx);
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * UART_STATUS_REG_POS, uart_regs.status);
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * UART_PARAM_REG_POS, uart_regs.param);

            $display("[%0t][UART]: base_addr     = %0h", $time, BASE_ADDR);
            $display("[%0t][UART]: parity_even   = %0d", $time, uart_regs.control.parity_even);
            $display("[%0t][UART]: parity_odd    = %0d", $time, uart_regs.control.parity_odd);
            $display("[%0t][UART]: tx_reset      = %0d", $time, uart_regs.control.tx_reset);
            $display("[%0t][UART]: rx_reset      = %0d", $time, uart_regs.control.rx_reset);
            $display("[%0t][UART]: clk_divider   = %0d", $time, uart_regs.clk_divider);
            $display("[%0t][UART]: tx_data       = %0h", $time, uart_regs.tx.data);
            $display("[%0t][UART]: rx_data       = %0h", $time, uart_regs.rx.data);
            $display("[%0t][UART]: rx_fifo_empty = %0d", $time, uart_regs.status.rx_fifo_empty);
            $display("[%0t][UART]: tx_fifo_empty = %0d", $time, uart_regs.status.tx_fifo_empty);
            $display("[%0t][UART]: rx_fifo_full  = %0d", $time, uart_regs.status.rx_fifo_full);
            $display("[%0t][UART]: tx_fifo_full  = %0d", $time, uart_regs.status.tx_fifo_full);
            $display("[%0t][UART]: rx_fifo_cnt  = %0d", $time, uart_regs.status.rx_fifo_cnt);
            $display("[%0t][UART]: tx_fifo_cnt   = %0d", $time, uart_regs.status.tx_fifo_cnt);
            $display("[%0t][UART]: parity_err    = %0d", $time, uart_regs.status.parity_err);
            $display("[%0t][UART]: fifo_depth    = %0d", $time, uart_regs.param.fifo_depth);
            $display("[%0t][UART]: data_width    = %0d", $time, uart_regs.param.data_width);
            $display("[%0t][UART]: reg_num       = %0d", $time, uart_regs.param.reg_num);
        end
    endtask

    task automatic uart_start();
        uart_regs_t uart_regs;
        uart_regs             = '0;
        uart_regs.clk_divider = CLK_DIV;
        begin
            env.master_write_reg(BASE_ADDR + ADDR_OFFSET * UART_CLK_DIVIDER_REG_POS, uart_regs.clk_divider);
            env.master_write_reg(BASE_ADDR + ADDR_OFFSET * UART_CONTROL_REG_POS, uart_regs.control);

            for (int i = 0; i < BYTES_NUM; i++) begin
                uart_regs.tx.data = $urandom_range(0, (2 ** UART_DATA_WIDTH) - 1);
                env.master_write_reg(BASE_ADDR + ADDR_OFFSET * UART_TX_DATA_REG_POS, uart_regs.tx);
            end

            do begin
                env.master_read_reg(BASE_ADDR + ADDR_OFFSET * UART_STATUS_REG_POS, uart_regs.status);
            end while (uart_regs.status.rx_fifo_empty);

            uart_read_regs();
        end
    endtask

endclass

`endif  // AXIL_UART_SVH
