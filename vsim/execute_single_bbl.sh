./DefaultConfig-sim-debug +vcd +vcd_name=output/bbl.vcd +max-cycles=1000000 +load=/home/zaepo/iaikgit/2015_master_jantscher/code/fpga/board/kc705/bbl/bbl.hex | /home/zaepo/iaikgit/2015_master_jantscher/code/riscv/bin/spike-dasm  >output/bbl.verilator.out && [ $PIPESTATUS -eq 0 ]

