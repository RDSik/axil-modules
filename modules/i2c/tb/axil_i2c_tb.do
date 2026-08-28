vlib work
vmap work

vlog modules/interface/rtl/axil_if.sv

vlog modules/fifo/rtl/async_fifo.sv
vlog modules/fifo/rtl/fifo_wrap.sv
vlog modules/fifo/rtl/rd_ptr_empty.sv
vlog modules/fifo/rtl/sync_fifo.sv
vlog modules/fifo/rtl/wr_ptr_full.sv

vlog modules/common/rtl/ram_sdp.sv
vlog modules/common/rtl/shift_reg.sv
vlog modules/common/rtl/axil_reg_file.sv
vlog modules/common/rtl/axil_reg_file_wrap.sv

vlog modules/i2c/rtl/axil_i2c.sv
vlog modules/i2c/rtl/i2c_pkg.svh

vlog modules/opencores/rtl/i2c_master_bit_ctrl.v
vlog modules/opencores/rtl/i2c_master_byte_ctrl.v
vlog modules/opencores/rtl/i2c_master_defines.v
vlog modules/opencores/rtl/i2c_slave_model.v
vlog modules/opencores/rtl/timescale.v

vlog modules/i2c/tb/axil_i2c_tb.sv

vsim -voptargs="+acc" axil_i2c_tb
add log -r /*

add wave -expand -group TOP      /axil_i2c_tb/i_axil_i2c/*
add wave -expand -group CTRL     /axil_i2c_tb/i_axil_i2c/i_i2c_master_byte_ctrl/*
add wave -expand -group REG_FILE /axil_i2c_tb/i_axil_i2c/i_axil_reg_file/g_sync_mode/i_axil_reg_file/*
add wave -expand -group AXIL     /axil_i2c_tb/i_axil_i2c/s_axil/*

run -all
wave zoom full
