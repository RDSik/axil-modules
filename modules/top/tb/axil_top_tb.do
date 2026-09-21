vlib work
vmap work

vlog  modules/interface/rtl/axi_if.sv
vlog  modules/interface/rtl/axis_if.sv
vlog  modules/interface/rtl/axil_if.sv
vlog  modules/interface/rtl/spi_if.sv
vlog  modules/interface/rtl/eth_if.sv

vlog modules/fifo/rtl/async_fifo.sv
vlog modules/fifo/rtl/axis_fifo.sv
vlog modules/fifo/rtl/fifo_wrap.sv
vlog modules/fifo/rtl/rd_ptr_empty.sv
vlog modules/fifo/rtl/sync_fifo.sv
vlog modules/fifo/rtl/wr_ptr_full.sv

vlog modules/arbiter/rtl/round_robin_arbiter.sv
vlog modules/arbiter/rtl/axil_crossbar.sv

vlog modules/dw_conv/rtl/axis_dw_conv.sv
vlog modules/dw_conv/rtl/axis_dw_conv_wrap.sv

vlog modules/common/rtl/iddr.sv
vlog modules/common/rtl/oddr.sv
vlog modules/common/rtl/crc.sv
vlog modules/common/rtl/ram_sdp.sv
vlog modules/common/rtl/shift_reg.sv
vlog modules/common/rtl/axil_reg_file.sv
vlog modules/common/rtl/axil_reg_file_wrap.sv
vlog modules/common/rtl/axis_reg_slice.sv

vlog  modules/uart/rtl/axil_uart.sv
vlog  modules/uart/rtl/axis_uart_tx.sv
vlog  modules/uart/rtl/axis_uart_rx.sv
vlog  modules/uart/rtl/uart_pkg.svh

vlog  modules/spi/rtl/axil_spi.sv
vlog  modules/spi/rtl/axis_spi_master.sv
vlog  modules/spi/rtl/spi_pkg.svh

vlog modules/opencores/rtl/i2c_master_bit_ctrl.v
vlog modules/opencores/rtl/i2c_master_byte_ctrl.v
vlog modules/opencores/rtl/i2c_master_defines.v
vlog modules/opencores/rtl/timescale.v

vlog  modules/i2c/rtl/axil_i2c.sv
vlog  modules/i2c/rtl/i2c_pkg.svh

vlog  modules/rgmii/rtl/rgmii_pkg.svh
vlog  modules/rgmii/rtl/mac_tx.sv
vlog  modules/rgmii/rtl/eth_header_gen.sv
vlog  modules/rgmii/rtl/mac_rx.sv
vlog  modules/rgmii/rtl/rgmii_rx.sv
vlog  modules/rgmii/rtl/rgmii_tx.sv
vlog  modules/rgmii/rtl/axis_rgmii.sv
vlog  modules/rgmii/rtl/axil_rgmii.sv

vlog modules/top/rtl/top_pkg.svh
vlog modules/top/rtl/axil_top.sv
vlog modules/top/tb/axil_top_tb.sv

vsim -voptargs="+acc" axil_top_tb
add log -r /*

add wave -expand -group CROSSBAR  /axil_top_tb/i_axil_top/i_axil_crossbar/*
add wave -expand -group UART      /axil_top_tb/i_axil_top/i_axil_uart/*
add wave -expand -group SPI       /axil_top_tb/i_axil_top/i_axil_spi/*
add wave -expand -group I2C       /axil_top_tb/i_axil_top/i_axil_i2c/*
add wave -expand -group RGMII     /axil_top_tb/i_axil_top/i_axil_rgmii/*
add wave -expand -group S_AXIS    /axil_top_tb/s_axis/*
add wave -expand -group M_AXIS    /axil_top_tb/m_axis/*

run -all
wave zoom full
