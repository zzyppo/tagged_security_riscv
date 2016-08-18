CODE_DIR=$TOP
TARGET_DIR="/home/zaepo/Dropbox/VMWare share/SD Kintex/new_stuff"
echo $TARGET_DIR
echo "Build Linux Test programs" 
cd "${CODE_DIR}"/fpga/board/kc705/examples/
make linux
echo "Opening Ramdisk and copy .linux programs into bin.. and copy ramdisk to shared folder"
cd "${CODE_DIR}"/linux_ramdisk
./mount_root.sh
sudo cp "${CODE_DIR}"/fpga/board/kc705/examples/*.linux mnt/bin/
echo "Copying support files to ramdisk..."
sudo cp Support_Test_Files/* mnt/bin/
sudo umount mnt/
cp root.bin "${TARGET_DIR}"
echo "Building Linux and copy to shared folder"
cd  "${CODE_DIR}"/riscv-tools/linux-3.14.41
make ARCH=riscv defconfig
make ARCH=riscv -j vmlinux
cp vmlinux "${TARGET_DIR}"
echo "Build BBL and copy to shared folder"
cd  "${CODE_DIR}"/fpga/board/kc705
make bbl
cp bbl/bbl "${TARGET_DIR}"/boot
