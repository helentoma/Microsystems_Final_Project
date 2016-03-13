vcom -2008 ./ram.vhd
vcom -2008 ./cpu.vhd
vcom -2008 ./coproc.vhd
vcom -2008 ./top.vhd

vsim work.top

add wave -label SDA sim:/top/CPU0/SDA
add wave -label SCL sim:/top/CPU0/SCL

add wave -height 36 -divider CPU

add wave -label DCLK sim:/top/CPU0/I2C_DCLK
add wave -label GO sim:/top/CPU0/I2C_GO
add wave -label RDY sim:/top/CPU0/I2C_RDY
add wave -label ST sim:/top/CPU0/I2C_ST
add wave -radix binary -label I2C_REG(r) sim:/top/CPU0/I2C_REG(r)
add wave -label c sim:/top/CPU0/c

add wave -height 36 -divider CoProc

add wave -label START sim:/top/CP0/I2C_START
add wave -label STOP sim:/top/CP0/I2C_STOP
add wave -label RDY sim:/top/CP0/I2C_RDY
add wave -label ADDR sim:/top/CP0/I2C_ADDR
add wave -label ST sim:/top/CP0/I2C_ST
add wave -radix binary -label I2C_REG(r) sim:/top/CP0/I2C_REG(r)
add wave -label c sim:/top/CP0/c




