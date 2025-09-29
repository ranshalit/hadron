#!/bin/bash
sudo apt update
sudo apt install build-essential bc \
  libncurses5-dev libssl-dev \
  bison flex \
  libelf-dev 


echo "Download kernel for R36.4.4 jetpack"
#As of JetPack 6.0 (or 6.0.1), the L4T (Linux for Tegra) version used is R36.4.4
wget https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.4/sources/public_sources.tbz2
sudo tar -xvf public_sources.tbz2

cd Linux_for_Tegra/source/
sudo tar -xvf kernel_src.tbz2
cd kernel/kernel-jammy-src
sudo chmod 777 . -R 

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export KERNEL_DIR=$(pwd)

#build BMI160 I2C module
echo "Build BMI160"
make ARCH=arm64 tegra_prod_defconfig

# Configure BMI160 options as modules before olddefconfig
echo "Configure kernel with BMU160 I2C module"
scripts/config --module CONFIG_BMI160
scripts/config --module CONFIG_BMI160_I2C
scripts/config --disable CONFIG_BMI160_SPI

make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- prepare
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules_prepare


make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KCFLAGS="-fno-stack-protector" M=drivers/iio/imu/bmi160 modules
sudo modprobe bmi160_core
echo "Copy drivers/iio/imu/bmi160/ bmi160_core.ko, bmi160_i2c.ko to target in /lib/modules/$(uname -r)/kernel/drivers/iio/imu/bmi160"
echo "Then:"
echo "sudo modprobe bmi160_core"
echo "sudo modprobe bmi160_i2c"
echo "echo bmi160 0x69 | sudo tee /sys/bus/i2c/devices/i2c-7/new_device"
echo "Verify device functionality with (for example): cat /sys/bus/iio/devices/iio\:device0/in_accel_x_raw"


