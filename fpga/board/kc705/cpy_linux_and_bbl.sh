echo "Build Linux Test programs" 
cd examples/
make linux
echo "Opening Ramdisk and copy .linux programs into bin.. and copy ramdisk to shared folder"
cd /home/zaepo/iaikgit/2015_master_jantscher/code/linux_ramdisk
./mount_root.sh
sudo cp /home/zaepo/iaikgit/2015_master_jantscher/code/fpga/board/kc705/examples/*.linux mnt/bin/
echo "Copying support files to ramdisk..."
sudo cp SUpport\ Test\ Files/* mnt/bin/
sudo umount mnt/
cp root.bin /home/zaepo/Dropbox/VMWare\ share/SD\ Kintex/modified\ ramdisk/
echo "Building Linux and copy to shared folder"
cd  /home/zaepo/iaikgit/2015_master_jantscher/code/riscv-tools/linux-3.14.41
make ARCH=riscv defconfig
make ARCH=riscv -j vmlinux
cp vmlinux /home/zaepo/Dropbox/VMWare\ share/SD\ Kintex/modified\ linux/
echo "Build BBL and copy to shared folder"
cd  /home/zaepo/iaikgit/2015_master_jantscher/code/fpga/board/kc705
make bbl
cp bbl/bbl /home/zaepo/Dropbox/VMWare\ share/SD\ Kintex/modified\ boot/boot
