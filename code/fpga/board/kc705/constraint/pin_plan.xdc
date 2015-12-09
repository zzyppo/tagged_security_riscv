# on board differential clock, 200MHz
set_property PACKAGE_PIN AD12 [get_ports clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_n]
set_property PACKAGE_PIN AD11 [get_ports clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_n]

# Reset active high SW4.1 User button South
set_property VCCAUX_IO DONTCARE [get_ports {rst_top}]
set_property SLEW FAST [get_ports {rst_top}]
set_property IOSTANDARD LVCMOS15 [get_ports {rst_top}]
set_property LOC AB12 [get_ports {rst_top}]

# UART Pins
set_property PACKAGE_PIN M19 [get_ports rxd]
set_property IOSTANDARD LVCMOS25 [get_ports rxd]
set_property PACKAGE_PIN K24 [get_ports txd]
set_property IOSTANDARD LVCMOS25 [get_ports txd]

# SD/SPI Pins
set_property PACKAGE_PIN AC21 [get_ports spi_cs]
set_property IOSTANDARD LVCMOS25 [get_ports spi_cs]
set_property PACKAGE_PIN AB23 [get_ports spi_sclk]
set_property IOSTANDARD LVCMOS25 [get_ports spi_sclk]
set_property PACKAGE_PIN AB22 [get_ports spi_mosi]
set_property IOSTANDARD LVCMOS25 [get_ports spi_mosi]
set_property PACKAGE_PIN AC20 [get_ports spi_miso]
set_property IOSTANDARD LVCMOS25 [get_ports spi_miso]


# Set DCI_CASCADE for DDR3 interface
set_property slave_banks {32 34} [get_iobanks 33]
