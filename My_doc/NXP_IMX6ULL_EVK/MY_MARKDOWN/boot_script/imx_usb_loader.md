# imx-usb-loader

[imx-usb-loader](https://github.com/boundarydevices/imx_usb_loader) is a tool written by Boundary Devices that leverages the **Serial Download Protocol (SDP)** available in Freescale i.MX5/i.MX6 processors.

Implemented in the ROM code of the Freescale SoCs, this protocol allows to send some code over USB or UART to a Freescale processor, even on a platform that has nothing flashed (no bootloader, no operating system). It is therefore a very handy tool to:

- Recover i.MX6 platforms, or
- Serve as an initial step for factory flashing: you can send a U-Boot image over USB and have it run on your platform.

This tool already existed; we only created a [package](https://git.buildroot.net/buildroot/commit/package/imx-usb-loader?id=059ab7f025c300db1d6ce175974c69444b1d478e) for it in the [Buildroot](http://buildroot.org/) build system, since Buildroot is used for this particular project.