`ifndef AXIL_I2C_SVH
`define AXIL_I2C_SVH

`include "modules/i2c/rtl/i2c_pkg.svh"
`include "modules/verification/tb/axil_env.svh"

import i2c_pkg::*;

class axil_i2c_class #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter logic [ADDR_WIDTH-1:0] BASE_ADDR = 'h200000
);

    localparam int ADDR_OFFSET = DATA_WIDTH / 8;
    localparam int PRESCALE = 0;
    localparam logic RW = 0;

    logic                                                               [DATA_WIDTH-1:0] wdata;
    logic                                                               [DATA_WIDTH-1:0] rdata;

    axil_env #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))                         env;

    virtual axil_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))                  s_axil;

    function new(
    virtual axil_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
    ) s_axil);
        this.s_axil = s_axil;
        env         = new(s_axil);
    endfunction

    task automatic i2c_read_regs();
        i2c_regs_t i2c_regs;
        begin
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * I2C_CONTROL_REG_POS, i2c_regs.control);
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * I2C_CLK_PRESCALE_REG_POS, i2c_regs.clk);
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * I2C_TX_DATA_REG_POS, i2c_regs.tx);
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * I2C_RX_DATA_REG_POS, i2c_regs.rx);
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * I2C_STATUS_REG_POS, i2c_regs.status);
            env.master_read_reg(BASE_ADDR + ADDR_OFFSET * I2C_PARAM_REG_POS, i2c_regs.param);

            $display("[%0t][I2C]: base_addr     = %0h", $time, BASE_ADDR);
            $display("[%0t][I2C]: core_en       = %0d", $time, i2c_regs.control.core_en);
            $display("[%0t][I2C]: core_rst      = %0d", $time, i2c_regs.control.core_rst);
            $display("[%0t][I2C]: prescale      = %0d", $time, i2c_regs.clk.prescale);
            $display("[%0t][I2C]: tx_data       = %0h", $time, i2c_regs.tx.data);
            $display("[%0t][I2C]: rx_data       = %0h", $time, i2c_regs.rx.data);
            $display("[%0t][I2C]: rx_fifo_empty = %0d", $time, i2c_regs.status.rx_fifo_empty);
            $display("[%0t][I2C]: tx_fifo_empty = %0d", $time, i2c_regs.status.tx_fifo_empty);
            $display("[%0t][I2C]: rx_fifo_full  = %0d", $time, i2c_regs.status.rx_fifo_full);
            $display("[%0t][I2C]: tx_fifo_full  = %0d", $time, i2c_regs.status.tx_fifo_full);
            $display("[%0t][I2C]: busy          = %0d", $time, i2c_regs.status.busy);
            $display("[%0t][I2C]: rx_ackn       = %0d", $time, i2c_regs.status.rx_ackn);
            $display("[%0t][I2C]: fifo_depth    = %0d", $time, i2c_regs.param.fifo_depth);
            $display("[%0t][I2C]: data_width    = %0d", $time, i2c_regs.param.data_width);
            $display("[%0t][I2C]: reg_num       = %0d", $time, i2c_regs.param.reg_num);
        end
    endtask

    task automatic i2c_start();
        i2c_regs_t i2c_regs;
        i2c_regs                  = '0;
        i2c_regs.control.core_en  = 1'b1;
        i2c_regs.control.core_rst = 1'b0;
        i2c_regs.clk.prescale     = PRESCALE;
        begin
            env.master_write_reg(BASE_ADDR + ADDR_OFFSET * I2C_CLK_PRESCALE_REG_POS, i2c_regs.clk.prescale);
            env.master_write_reg(BASE_ADDR + ADDR_OFFSET * I2C_CONTROL_REG_POS, i2c_regs.control);
            i2c_regs.tx.data = {I2C_ADR, RW};
            env.master_write_reg(BASE_ADDR + ADDR_OFFSET * I2C_TX_DATA_REG_POS, i2c_regs.tx);
            i2c_regs.tx.data = 8'hac;
            env.master_write_reg(BASE_ADDR + ADDR_OFFSET * I2C_TX_DATA_REG_POS, i2c_regs.tx);
            i2c_read_regs();
        end
    endtask

endclass

`endif  // AXIL_I2C_SVH
