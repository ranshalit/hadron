# prepare a new image

steps:
1. run
   sudo ./hadron_bsp_setup.sh --flash nvme
   Note: this is same as Bar script with the only change
   - ( cd "$FLASH_DIR" && sudo "./$REL_FLASH" "$profile")
   + ( cd "$FLASH_DIR" && sudo "./$REL_FLASH" "$profile" && sudo ./flash.sh --qspi-only cti/orin-nano/hadron/base internal)
    becuase qspi was not programmed without this command (only nvme).

2. power cycle the board and login using:
    username: ubuntu
    password:ubuntu

3. in target (use serial) run
   scp bmi160_core.ko ubuntu@192.168.132.100:
   scp bmi160_i2c.ko ubuntu@192.168.132.100:

4.  in target (use serial) run: 
    sudo vi /etc/modules-load.d/modules.conf, and add a line:
    r8168 
    in /etc/modules-load.d/modules.conf

5.  in target (use serial) run:
    RULE='/etc/udev/rules.d/99-bmi160.rules'
    echo 'ACTION=="add", SUBSYSTEM=="i2c", KERNEL=="i2c-[0-9]*", RUN+="/bin/sh -c '"'echo bmi160 0x69 > /sys/bus/i2c/devices/%k/new_device'"'"' | sudo tee "${RULE}" >/dev/null

6. sudo vi /etc/NetworkManager/system-connections/Wired_connection_1 with content:
    
    [connection]
    id=Wired_connection_1
    type=802-3-ethernet
        
    [802-3-ethernet]
    [ipv4] 
    method=manual
    dns=192.168.132.1
    address1=192.168.132.100/24,192.168.132.1
    [ipv6]
    method=auto
    ip6-privacy=2

7.
#Downloads
#opncv 
add in sources.list:
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy main universe multiverse restricted
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-updates main universe multiverse restricted
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-security main universe multiverse restricted
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-backports main universe multiverse restricted

    apt download libopencv-dev:arm64 python3-opencv:arm64
#pip & 
    curl -O https://bootstrap.pypa.io/get-pip.py
    mkdir ~/offline-pip-full
    cd ~/offline-pip-full
    python3 -m pip download pip setuptools wheel --only-binary=:all: --platform manylinux2014_aarch64 --python-version 3.10 --abi cp310

in target:
    cd ~/offline-pip-full
    sudo python3 get-pip.py --no-index --find-links=/home/ubuntu/offline-pip-full/
    or python3 -m pip install --no-index --find-links=/home/ubuntu/offline-pip-full/
    cd pymavlink-arm64/
    python3 -m pip install --no-index --find-links=. pymavlink

# References:
    https://azuredevops.rafael.co.il/Land_and_Naval_Collection/IW/_git/Installer?path=%2Fbmi160%2Finstall_bmi_offline.sh
    UP 7000 Edge datasheet 
    https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmi160-ds000.pdf
    https://developer.download.nvidia.com/assets/embedded/secure/jetson/orin_nano/docs/Jetson-Orin-Nano-DevKit-Carrier-Board-Specification_SP-11324-001_v1.3.pdf?__token__=exp=1753855391~hmac=1fd7796e5d5e2e2b6c6187327f73bca43631976e0087098c975dc96e7f5112f3&t=eyJscyI6ImdzZW8iLCJsc2QiOiJodHRwczovL3d3dy5nb29nbGUuY29tLyJ9 table 3.3 pin header

    UP 7000:
        192.168.132.100
        user: up7000
        pwd: 123

#gpio
gpioinfo
gpiodetect
gpioset gpiochip1 13=1

#extlinux
workaround for camera detection after powercycles:
    add usbcore.autosuspend=-1 in /boot/extlinux/extlinux.conf
    APPEND ${cbootargs} root=PARTUUID=9a61a38a-42b3-433d-a4f4-76b1810d2f98 rw rootwait usbcore.autosuspend=-1 rootfstype=ext4 mminit_loglevel=4 console=ttyTCU0,115200 firmware_class.path=/etc/firmware fbcon=map:0 video=efifb:off console=tty0






# Hadron BSP Installer + Flasher

A one-shot helper script (`hadron_bsp_setup.sh`) that:  

1. **finds** your *Linux_for_Tegra* flash-tree (or lets you point at it);  
2. **installs** the matching Connect Tech **Hadron BSP** *only* if it is not already present;  
3. **flashes** a ready-to-boot image (NVMe *or* eMMC root-fs).  

> **Everything runs on the Ubuntu x86-64 host PC — *not* on the Jetson.**  
> Keep the module on the NVIDIA dev-kit, put it in force-recovery  
> (`lsusb` shows **0955:73xx** or **0955:75xx**), flash, then move the module to the Hadron carrier.

---

## Quick start — NVMe root-fs (recommended)

```bash
#Flash to nvme drive
sudo ./hadron_bsp_setup.sh --flash nvme
```
### Other execution options

| Goal                                        | Command                                                                        |
| ------------------------------------------- | ------------------------------------------------------------------------------ |
| Flash root-fs to **on-module eMMC**         | `sudo ./hadron_bsp_setup.sh --flash emmc`                                      |
| **Dry-run** (show each step, touch nothing) | `sudo ./hadron_bsp_setup.sh --flash nvme --dry-run`                            |
| Use a **specific flash-tree**               | `sudo ./hadron_bsp_setup.sh --flash-dir /path/to/Linux_for_Tegra --flash nvme` |
| Use a pre-downloaded BSP tarball            | `sudo ./hadron_bsp_setup.sh --bsp-file ~/Downloads/CTI-L4T-*.tgz --flash nvme` |


#BMI160
# BMI160‑Jetson

# Device detection:
i2cdetect -r -y 7

# BMI160 pins:
1-3.3v
3-SDA
5-SCL
9-GND

See     https://developer.download.nvidia.com/assets/embedded/secure/jetson/orin_nano/docs/Jetson-Orin-Nano-DevKit-Carrier-Board-Specification_SP-11324-001_v1.3.pdf?__token__=exp=1753855391~hmac=1fd7796e5d5e2e2b6c6187327f73bca43631976e0087098c975dc96e7f5112f3&t=eyJscyI6ImdzZW8iLCJsc2QiOiJodHRwczovL3d3dy5nb29nbGUuY29tLyJ9 table 3.3 pin header

# How to connect the sensor cable:
    Just take care to see in the 40-pin header where are the 1/2 pins, and connect the cable.
    so that the connected pins of sensor (1,3,5,9) are near/close to the first pins edge in the connector. Good Luck!

# Installation:
see script install_bmi160.sh
# Option 1:
    It can be installed in startscript which calls install_bmi160.sh, i.e. modprbe bmi160<>.ko 
    & echo bmi160 0x69 | sudo tee /sys/bus/i2c/devices/i2c-7/new_device 

# Option 2:
    By adding a new udev rule (one time):
    RULE='/etc/udev/rules.d/99-bmi160.rules'
    echo 'ACTION=="add", SUBSYSTEM=="i2c", KERNEL=="i2c-7", RUN+="/bin/sh -c '"'echo bmi160 0x69 > /sys/bus/i2c/devices/%k/new_device'"'"' | sudo tee "${RULE}" >/dev/null
    sudo udevadm control --reload

# Validation:
    see all sensors reading in cat /sys/bus/iio/devices/iio\:device0/    
    buntu@ubuntu:~$ ls /sys/bus/iio/devices/iio\:device0/
        buffer/
        buffer0/
        current_timestamp_clock
        dev
        in_accel_sampling_frequency
        in_accel_sampling_frequency_available
        in_accel_scale
        in_accel_scale_available
        in_accel_x_raw
        in_accel_y_raw
        in_accel_z_raw
        in_anglvel_sampling_frequency
        in_anglvel_sampling_frequency_available
        in_anglvel_scale
        in_anglvel_scale_available
        in_anglvel_x_raw
        in_anglvel_y_raw
        in_anglvel_z_raw
        in_mount_matrix
        name
        power/
        scan_elements/
        subsystem/
        trigger/
        uevent

    e.g.
    cat /sys/bus/iio/devices/iio\:device0/in_accel_x_raw
    cat /sys/bus/iio/devices/iio\:device0/in_accel_y_raw
    cat /sys/bus/iio/devices/iio\:device0/in_accel_z_raw
