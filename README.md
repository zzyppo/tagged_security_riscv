# Project:           Tagged Security on RISC-V 

**Student**:         Philipp Jantscher

**Advisor**:         Stefan Mangard, Mario Werner

**Project goals**:   Implementation of tagged memory security policies on RISC-V (lowRISC)

**Project status**:  Started on 10.2015 / completed on 08.2016


## Documentation

The project base is the lowRISC untethered (0.2) release (https://github.com/lowRISC/lowrisc-chip). -> Change to branch untether-v0.2.
Most readme files are therefore taken from this implementation and also the tutorials apply to this implementation. 
Tutorial for the untethered lowRISC release : http://www.lowrisc.org/docs/untether-v0.2/

 Environment Setup:

    -cd to code/
    -source set_riscv_env.sh
    -export RISCV=$TOP/riscv
    -export XILINX_VIVADO=/path_to_xilinx_vivado (e.g /opt/Xilinx/Vivado/2014.4/)
    -source your xilinx tools (Vivado 64-Bit)

 Build testcases and example programs:

    -cd to fpga/board/kc705/examples
    -make -> Compiles standalone applications
    -make linux -> Compiles linux applications

Build Rocket Core / Creating VIVADO project and synthesis:

    -cd to fpga/board/kc705
    -make verilog : Will compile the rocket Chisel sources into verilog sources
    -make project : Creates the Vivado project
    -make vivado : Opens the Vivado project.
    -Run synthesis from GUI
    -make %TESTCASE% -> This is used to copy the given testcase into BRAM (e.g. boot). 
 
 -make %TESTCASE% can be also used alternatively instead of the previous steps (everything will be executed automatically).

Build Rocket Core / Simulation using Verilator:

    -cd to fpga/board/kc705/examples
    -make
    -cd to $TOP
    -cd to vsim
    -make verilog : Will compile the rocket sources into verilog sources
    -make sim-debug: Will build Verilator simulator and outputs $CONFIG_sim_debug executeable
    -./execute_single_{TESTFILE}: Execute single will execute a test file, defined in the shell script

Alternatively you can use the command 

    ./DefaultConfig-sim-debug +vcd +vcd_name=output {name}.vcd +max-cycles=1000000 +load=$TOP/fpga/board/kc705/examples/{name}.hex |  $TOP/riscv/bin/spike-dasm  >output/{name}.verilator.out && [ $PIPESTATUS -eq 0 ]

-> This will create a .out file, which is the log of the executed testcase and a waveform .vcd file. This file is viewable in gtkwave.

Donwload and build Linux:

First the linux source code has to be downoaded from a seperate GitHub repository (https://github.com/zzyppo/riscv-linux/tree/linux3.13.41). 

    -cd to code/riscv-tools
    -curl -L https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.14.41.tar.xz | tar -xJ
    -cd linux-3.14.41
    -git init
    -git remote add origin git@github.com:zzyppo/riscv-linux.git
    -git fetch
    -git checkout -f -t origin/linux3.13.41 

Then the kernel is compiled.

    -make ARCH=riscv defconfig
    -make ARCH=riscv -j vmlinux

Running Linux with BBL and create SD card:

First, the Kintex-7 UART and JTAG interface needs to be connected to the PC. Setup a UART terminal and set up 115200 baud and odd parity.

The compilation of Linux, the BBL and the corresponding test files, which shall be copied on the ramdisk,
can be automated using the script cpy_linux_and_bbl.sh.

    -cd to fpga/board/kc705
    -Open the script and change the variable TARGET_DIR to the corresponding target folder (or directly the SD card).
    -./cpy_linux_and_bbl.sh

This will compile all neccessary files and copy root.bin, vmlinux and boot (BBL) to the destination folder. This three files need to be copied to the SD card.
All .linux test files will be copied to root.bin/bin and are available when linux is booted.

Then the chip is synthesized and the first stage bootloader is copied to the bitstream file.

    -make boot (Compile the first stage bootloader and copy in BRAM in file /code/fpga/board/kc705/lowrisc-chip-imp/lowrisc-chip-imp.runs/impl_1/chip_top_new.bit)
    -make vivado
    -Change to Hardware Manager
    -Open target / Auto Connect
    -Program Device with chip_top_new.bit
    -The UART Terminal now should display the bootprocess and later execute Linux

ROP test:
This testcase allows to verify the functionality of the return address protection policy.
The program is called rop_attack.linux

    -Within linux change to the /bin directory.
    -Several types of  parameters are possible for the testcase.
    1)./rop_attack.linux -> The tag check is enabled.
    2)./rop_attack.lunux off -> The check is disabled

    -Select the attack mode (0: full retrun address overwrite, 1: partial byte store on return address, 2: partial copy of return address)

JOP test:
This testcase allows to verify the functionality of the function pointer protection policy.
The program is called jop_attack.linux

    -Within linux change to the /bin directory
    -Several types of input are and parameters are possible for the testcase.
    1)./jop_attack.linux -> The check is enabled and a string is read from the UART interface while program execution.
    2)./jop_attack.linux off -> The check is disabled and a string is read from the UART interface while program execution.
    3)./jop_attack.linux some_string-> The check is enabled and a string is passed as argument
    4)./jop_attack.linux off some_string-> The check is disabled and a string is passed as argument

The function pointer will be overwritten with the given string and a trap occurs if the jump shall be performed and the check is enabled.

## Status

Tagged Security Policies working, Linux is booting, testcases provided
