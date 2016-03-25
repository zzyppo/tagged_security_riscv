cd  /home/zaepo/iaikgit/2015_master_jantscher/code/riscv-tools/linux-3.14.41
make ARCH=riscv defconfig
make ARCH=riscv -j vmlinux
cp vmlinux /home/zaepo/Dropbox/VMWare\ share/SD\ Kintex/modified\ linux/
cd  /home/zaepo/iaikgit/2015_master_jantscher/code/fpga/board/kc705
make bbl
cp bbl/bbl /home/zaepo/Dropbox/VMWare\ share/SD\ Kintex/modified\ boot/boot
