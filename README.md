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