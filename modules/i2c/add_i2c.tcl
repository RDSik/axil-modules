set path [file dirname [info script]]

if {$xilinx == 1} {
    set xil_defaultlib "
        $path/rtl/axil_i2c.sv
        $path/../opencores/rtl/i2c_master_bit_ctrl.v
        $path/../opencores/rtl/i2c_master_byte_ctrl.v
        $path/../opencores/rtl/i2c_master_defines.v
        $path/../opencores/rtl/i2c_slave_model.v
        $path/../opencores/rtl/timescale.v
        $path/rtl/i2c_pkg.svh
    "
    add_files -norecurse $xil_defaultlib

    set xil_defaultlib "
        $path/tb/axil_i2c_tb.sv
        $path/tb/axil_i2c_class.svh
    "
    add_files -fileset sim_1 $xil_defaultlib
} elseif {$gowin == 1} {
    add_file $path/rtl/axil_i2c.sv
    add_file $path/../opencores/rtl/i2c_master_bit_ctrl.v
    add_file $path/../opencores/rtl/i2c_master_byte_ctrl.v
    add_file $path/../opencores/rtl/i2c_master_defines.v
    add_file $path/../opencores/rtl/i2c_slave_model.v
    add_file $path/../opencores/rtl/timescale.v
    add_file $path/rtl/i2c_pkg.svh
}
