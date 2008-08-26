#retina driver for linux, martin ebner, igi, tu graz, austria
#this script builds and reloads the linux driver

cd drivers/driverRetinaLinux/
#remove module, if present
if lsmod|grep retina;
then sudo rmmod retina.ko;
fi;
#when changing kernels, a clean build is needed
rm *.ko *.o 
#build kernel module
make
#insert retina driver module
sudo insmod retina.ko
#view kernel messages
dmesg | tail
cd ../..
sleep 1
#enable access to driver file for all
sudo chmod 606 /dev/retina0
echo retina driver module built and restarted.
