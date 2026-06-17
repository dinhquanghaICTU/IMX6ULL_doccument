# Factory Flashing i.MX6 via USB

## Introduction

For one of our customers building a product based on i.MX6 with a fairly low-volume, we had to design a mechanism to perform the factory flashing of each product. The goal is to be able to take a freshly produced device from the state of a brick to a state where it has a working embedded Linux system flashed on it.

This specific product is using an **eMMC** as its main storage, and our solution only needs a **USB connection** with the platform, which makes it a lot simpler than solutions based on network (TFTP, NFS, etc.).

In order to achieve this goal, we have combined the `imx-usb-loader` tool with the fastboot support in U-Boot and some scripting. Thanks to this combination of a tool, running a single script is sufficient to perform the factory flashing, or even restore an already flashed device back to a known state.

## Overall Flow

The overall flow of our solution, executed by a shell script, is:

1. `imx-usb-loader` pushes over USB a U-Boot bootloader into the i.MX6 RAM, and runs it;
2. This U-Boot automatically enters fastboot mode;
3. Using the fastboot protocol and its support in U-Boot, we send and flash each part of the system:
   - Partition table
   - Bootloader
   - Bootloader environment
   - Root filesystem (which contains the kernel image)

> **Platform:** The SECO uQ7 i.MX6 platform is used for this project.