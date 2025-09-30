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

6. It is ready





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


#### Problems? 
contact `barif@rafael.co.il`