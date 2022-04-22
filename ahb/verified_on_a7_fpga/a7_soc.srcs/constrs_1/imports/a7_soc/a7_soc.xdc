## This file is a general .xdc for the A7-100T

############## NET - IOSTANDARD ######################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
#############SPI Configurate Setting##################
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]

## Clock signal
create_clock -period 20.000 -name sys_clk_i [get_ports sys_clk_i]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sys_clk_i]
set_property PACKAGE_PIN R4 [get_ports sys_clk_i]
set_property IOSTANDARD LVCMOS15 [get_ports sys_clk_i]


set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS15} [get_ports sys_rstn_i]

# asynchronous reset
# set_false_path -from [get_ports sys_rstn_i]


##LEDs
set_property -dict {PACKAGE_PIN V9 IOSTANDARD LVCMOS15} [get_ports {leds[0]}]
set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS15} [get_ports {leds[1]}]
set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS15} [get_ports {leds[2]}]
set_property -dict {PACKAGE_PIN W7 IOSTANDARD LVCMOS15} [get_ports {leds[3]}]

##UART
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports uart_tx]

create_clock -period 200.000 -name jtag_idcode_clk -waveform {0.000 100.000} [get_pins a7_soc_inst/inst_debug/inst_dtm/inst_jtag_tap/tap_idcode/TCK]
create_clock -period 200.000 -name jtag_dtmcs_clk -waveform {0.000 100.000} [get_pins a7_soc_inst/inst_debug/inst_dtm/inst_jtag_tap/tap_dtmcs/TCK]
create_clock -period 200.000 -name jtag_dmi_clk -waveform {0.000 100.000} [get_pins a7_soc_inst/inst_debug/inst_dtm/inst_jtag_tap/tap_dmi/TCK]

set_clock_groups -asynchronous -group sys_clk_i -group jtag_dmi_clk
set_clock_groups -logically_exclusive -group jtag_idcode_clk -group jtag_dtmcs_clk -group jtag_dmi_clk

