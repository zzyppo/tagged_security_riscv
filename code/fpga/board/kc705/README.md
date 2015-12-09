lowRISC Xilinx KC705 Board Developement Demo
========================================================

(Not a stand-alone git repo. Please clone https://github.com/lowrisc/lowrisc-chip.git to have this as a submodule of <lowrisc-chip>/fpga/board/kc705)

Requirement:

  **Vivado 2015.3** and **lowRISC develope environment**

How to run the demo:
--------------------------------------------------------

* Generate bit-stream for downloading

        make bitstream

* Run FPGA simulation (extremely slow due to the DDR3 memory controller)

        make simulation

* Open the Vivado GUI

        make vivado

Other Make targets
--------------------------------------------------------

* Generate the FPGA backend Verilog files

        make verilog

* Generate the Vivado project

        make project

* Find out the boot BRAMs' name and position (for updating src/boot.bmm)

        make search-ramb

* Replace the content of boot BRAM with a new src/boot.mem (must update src/boot.bmm first)

        make bit-update
