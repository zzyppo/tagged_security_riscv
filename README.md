# Project:           ...

**Student**:         Philipp Jantscher

**Advisor**:         Mario Werner, Stefan Mangard

**Project goals**:   Implementation of tagged memory security policies on RISCV

**Project status**:  Started on ... / completed on ... / presentations and posters ...


## Documentation

Environment Setup:
-cd to code/
-source set_riscv_env.sh
-export RISCV=$TOP/riscv
-export XILINX_VIVADO=/path_to_xilinx_vivado (e.g /opt/Xilinx/Vivado/2014.4/)
-source your xilinx tools (Vivado 64-Bit)

Build Rocket Core / Creating VIVADO project and synthesis:

-cd to fpga/board/kc705

-make verilog : Will compile the rocket sources into verilog sources
-make project : Creates the Vivado project
  Please ignore the follwoing error if occurs: 

  ERROR: [Vivado 12-172] File or Directory 'code/fpga/board/kc705/lowrisc-chip-imp/lowrisc-chip-imp.srcs/sources_1/ip/mig_7series_0/mig_7series_0/example_design/sim/
  ddr3_model.sv' does not exist

  I think this happens because I reduced the MIG version from 2.4  to 2.3 (because i still use the old vivado version).

-make vivado : Opens the Vivasdo project.
-Run synthesis from GUI

Build Rocket Core / Simulation using Verilator:

-cd to fpga/board/kc705/examples
-make
-cd to $TOP
-cd to vsim
-make verilog : Will compile the rocket sources into verilog sources
-make sim-debug: Will build Verilator simulator and outputs $CONFIG_sim_debug executeable

-./execute_single_{TESTFILE}: Execute single will execute a test file, defined in the shell script

-Alternatively you can use the command ./DefaultConfig-sim-debug +vcd +vcd_name=output {name}.vcd +max-cycles=1000000 +load=$TOP/fpga/board/kc705/examples/{name}.hex | $TOP/riscv/bin/spike-dasm  >output/{name}.verilator.out && [ $PIPESTATUS -eq 0 ]

This will create a .out file, which is the log of the executed testcase and a waveform .vcd file. This file is viewable in gtkwave.

## Status

Tag Cache working, now implementing tag check/propagation unit
