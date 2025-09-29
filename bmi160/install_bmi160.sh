#!/bin/bash

#do it only one times
sudo mkdir /lib/modules/$(uname -r)/kernel/drivers/iio/imu/bmi160
sudo cp bmi160_core.ko /lib/modules/$(uname -r)/kernel/drivers/iio/imu/bmi160
sudo cp bmi160_i2c.ko /lib/modules/$(uname -r)/kernel/drivers/iio/imu/bmi160
sudo depmod -a

#every boot:

#option #1 startup script:
sudo modprobe bmi160_core
sudo modprobe bmi160_i2c
echo bmi160 0x69 | sudo tee /sys/bus/i2c/devices/i2c-7/new_device

#option #2 use udev rule:
RULE='/etc/udev/rules.d/99-bmi160.rules'
echo 'ACTION=="add", SUBSYSTEM=="i2c", KERNEL=="i2c-[0-9]*", RUN+="/bin/sh -c '"'echo bmi160 0x69 > /sys/bus/i2c/devices/%k/new_device'"'"' | sudo tee "${RULE}" >/dev/null
sudo udevadm control --reload
