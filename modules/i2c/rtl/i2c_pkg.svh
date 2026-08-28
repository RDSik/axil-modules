`ifndef I2C_PKG_SVH
`define I2C_PKG_SVH

package i2c_pkg;

    localparam logic [6:0] I2C_ADR = 7'ha;
    localparam int I2C_PRESCALE_WIDTH = 16;
    localparam int I2C_DATA_WIDTH = 8;

    typedef struct packed {
        logic [7:0] rsrvd;
        logic [7:0] fifo_depth;
        logic [7:0] reg_num;
        logic [7:0] data_width;
    } i2c_param_reg_t;

    typedef struct packed {
        logic [25:0] rsrvd;
        logic        rx_fifo_empty;
        logic        tx_fifo_empty;
        logic        rx_fifo_full;
        logic        tx_fifo_full;
        logic        rx_ackn;
        logic        busy;
    } i2c_status_reg_t;

    typedef struct packed {
        logic [15:0]                   rsrvd;
        logic [I2C_PRESCALE_WIDTH-1:0] prescale;
    } i2c_clk_prescale_reg_t;

    typedef struct packed {
        logic [29:0] rsrvd;
        logic        core_en;
        logic        core_rst;
    } i2c_control_reg_t;

    typedef struct packed {
        logic [23:0]               rsrvd;
        logic [I2C_DATA_WIDTH-1:0] data;
    } i2c_data_reg_t;

    typedef struct packed {
        i2c_param_reg_t        param;
        i2c_status_reg_t       status;
        i2c_data_reg_t         rx;
        i2c_data_reg_t         tx;
        i2c_clk_prescale_reg_t clk;
        i2c_control_reg_t      control;
    } i2c_regs_t;

    localparam int I2C_CONTROL_REG_POS = 0;
    localparam int I2C_CLK_PRESCALE_REG_POS = I2C_CONTROL_REG_POS + $bits(i2c_control_reg_t) / 32;
    localparam int I2C_TX_DATA_REG_POS = I2C_CLK_PRESCALE_REG_POS + $bits(
        i2c_clk_prescale_reg_t
    ) / 32;
    localparam int I2C_RX_DATA_REG_POS = I2C_TX_DATA_REG_POS + $bits(i2c_data_reg_t) / 32;
    localparam int I2C_STATUS_REG_POS = I2C_RX_DATA_REG_POS + $bits(i2c_data_reg_t) / 32;
    localparam int I2C_PARAM_REG_POS = I2C_STATUS_REG_POS + $bits(i2c_status_reg_t) / 32;

    localparam int I2C_REG_NUM = $bits(i2c_regs_t) / 32;

    localparam i2c_regs_t I2C_REG_INIT = '{control : '{core_rst: 1'b1, default: '0}, default: '0};

endpackage

`endif  // I2C_PKG_SVH
