# Project:           ...

**Student**:         Philipp Jantscher

**Advisor**:         Mario Werner, Stefan Mangard

**Project goals**:   Implementation of tagged memory security policies on RISCV

**Project status**:  Started on ... / completed on ... / presentations and posters ...


## Documentation

Build Rocket Core / Creating VIVADO project and synthesis:

-cd to code/
-source set_riscv_env.sh
-export RISCV=$TOP/riscv
-export XILINX_VIVADO=/path_to_xilinx_vivado (e.g /opt/Xilinx/Vivado/2014.4/)
-source your xilinx tools (Vivado 64-Bit)
-cd to fpga/board/kc705

-make verilog : Will compile the rocket sources into verilog sources
-make project : Creates the Vivado project
  Please ignore the follwoing error if occurs: 

  ERROR: [Vivado 12-172] File or Directory 'code/fpga/board/kc705/lowrisc-chip-imp/lowrisc-chip-imp.srcs/sources_1/ip/mig_7series_0/mig_7series_0/example_design/sim/
  ddr3_model.sv' does not exist

  I think this happens because I reduced the MIG version from 2.4  to 2.3 (because i still use the old vivado version).

-make vivado : Opens the Vivasdo project.
-Run synthesis from GUI

## Status

Currently implementing Tag Cache, Linux Boots
