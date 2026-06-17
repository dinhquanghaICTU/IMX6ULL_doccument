# Boot Script Index

Thu muc nay gom tai lieu va source phuc vu flow boot/flash i.MX6/i.MX6ULL qua USB.

## Duong dan thu muc

```text
C:\ha\tailieuhoctap\thuctap\DOC_IMX6UL\My_doc\boot_script
```

## Tai lieu chinh

- [introduction.md](introduction.md): Tong quan flow factory flashing i.MX6 qua USB.
- [imx_usb_loader.md](imx_usb_loader.md): Giai thich cong cu imx-usb-loader va SDP.
- [Fastboot.md](Fastboot.md): Giai thich fastboot trong flow flash.

## Thu muc con

- [imx_loader/](imx_loader/): Source va huong dan su dung imx_loader.
- [imx_loader/step_use.md](imx_loader/step_use.md): Cach build/chay `imx_usb` va `imx_uart`.
- [imx_loader/imx_usb_loader/](imx_loader/imx_usb_loader/): Source code imx_usb_loader.
- [imx_loader/imx_usb_loader/msvc/](imx_loader/imx_usb_loader/msvc/): Project Visual Studio de build `imx_usb.exe` va `imx_uart.exe`.
- [imx_loader/imx_usb_loader/tests/](imx_loader/imx_usb_loader/tests/): Test/config mau cua imx_usb_loader.

## File config quan trong

- [imx_loader/imx_usb_loader/imx_usb.conf](imx_loader/imx_usb_loader/imx_usb.conf): Map USB VID/PID sang file config chip.
- [imx_loader/imx_usb_loader/mx6ull_usb_work.conf](imx_loader/imx_usb_loader/mx6ull_usb_work.conf): Config cho i.MX6ULL.
- [imx_loader/imx_usb_loader/mx6_usb_work.conf](imx_loader/imx_usb_loader/mx6_usb_work.conf): Config cho mot so dong i.MX6.

## Cach chay nhanh

```powershell
cd C:\ha\tailieuhoctap\thuctap\DOC_IMX6UL\My_doc\boot_script\imx_loader\imx_usb_loader
.\imx_usb.exe -c . C:\path\to\u-boot.imx
```

Neu U-Boot vao fastboot mode:

```powershell
fastboot devices
```
