# Tối ưu thời gian boot cho OKMX6ULL-S eMMC

## 1. Mục tiêu và phạm vi

Tài liệu này ghi lại các thay đổi đã thực hiện trong ngày 01–02/07/2026 để tối ưu quá trình boot của board OKMX6ULL-S eMMC sử dụng NXP i.MX6ULL và Yocto Kirkstone.

Mục tiêu ban đầu:

- Giảm thời gian từ lúc cấp nguồn đến khi Linux xuất hiện màn hình đăng nhập.
- Hướng tới thời gian boot khoảng 15 giây trên board thật.
- Chỉ giữ các chức năng cần thiết: UART, Ethernet, Wi-Fi, SSH, MQTT và OTA A/B.
- Giảm kích thước U-Boot và root filesystem.
- Không phá vỡ cơ chế OTA, `fw_setenv`, Wi-Fi và đường debug UART.

> **Lưu ý:** mốc 15 giây chưa được xác nhận bằng số liệu `systemd-analyze` trên board sau tất cả thay đổi. Các tối ưu đã build thành công, nhưng kết quả cuối phải đo lại trên phần cứng thật.

Workspace Yocto chính:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull
```

Layer tùy chỉnh:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull
```

## 2. Tối ưu U-Boot

### 2.1. Bỏ thời gian chờ autoboot

File đã sửa:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-bsp/u-boot/files/okmx6ull_s_emmc_defconfig
```

Thay đổi:

```config
CONFIG_BOOTDELAY=0
```

Defconfig gốc của NXP sử dụng `CONFIG_BOOTDELAY=3`. Việc đặt về `0` bỏ ba giây đếm ngược trước khi chạy `bootcmd`.

Lý do lựa chọn:

- Thiết bị production phải tự boot ngay.
- UART vẫn được giữ để debug sau khi Linux chạy.
- Không cần người dùng dừng autoboot trong hoạt động bình thường.

### 2.2. Bỏ thao tác LED và `mmc dev` bị lặp

Boot command cũ có nháy LED và gọi `mmc dev` hai lần. Boot command hiện tại:

```config
CONFIG_BOOTCOMMAND="run findfdt; mmc dev ${mmcdev}; if mmc rescan; then if run loadbootscript; then run bootscript; else if run loadimage; then run mmcboot; else run netboot; fi; fi; else run netboot; fi"
```

Thay đổi chính:

- Bỏ `ledblink 3 100` khỏi đường boot bình thường.
- Chỉ gọi `mmc dev ${mmcdev}` một lần.
- Giữ `loadbootscript` để cơ chế OTA tiếp tục sử dụng `boot.scr`.

Lý do lựa chọn:

- Nháy LED tạo thêm delay không cần thiết.
- Gọi chọn cùng một MMC device hai lần không đem lại lợi ích khi eMMC hoạt động ổn định.

### 2.3. Không bắt giữ nút ON/OFF 5 giây mới được boot

Các file liên quan:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-bsp/u-boot/files/command_button_jump_kernel.c
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-bsp/u-boot/files/0001-mx6ull-set-onoff-hold-time-to-10-seconds.patch
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-bsp/u-boot/u-boot-imx_%.bbappend
```

Command `waitpwrkey` từng được thử trong `CONFIG_BOOTCOMMAND` với thời gian giữ 5000 ms. Hàm này còn lặp vô hạn cho tới khi người dùng giữ nút đủ lâu, vì vậy nó là nút thắt rất lớn và đã được loại khỏi đường boot tự động.

Lý do lựa chọn:

- Thiết bị phải boot ngay khi cấp nguồn.
- Nút nguồn chỉ phù hợp làm recovery hoặc thao tác đặc biệt, không nên chặn boot bình thường.

### 2.4. Tắt các command và driver U-Boot không dùng

Các cấu hình đã tắt bằng cú pháp Kconfig chuẩn:

```config
# CONFIG_SUPPORT_RAW_INITRD is not set
# CONFIG_CMD_MEMTEST is not set
# CONFIG_CMD_I2C is not set
# CONFIG_CMD_SF is not set
# CONFIG_CMD_USB is not set
# CONFIG_CMD_DHCP is not set
# CONFIG_CMD_PING is not set
# CONFIG_CMD_NET is not set
# CONFIG_CMD_FS_GENERIC is not set
# CONFIG_MTD is not set
# CONFIG_DM_SPI_FLASH is not set
# CONFIG_SPI_FLASH_STMICRO is not set
# CONFIG_FSL_QSPI is not set
# CONFIG_DM_VIDEO is not set
# CONFIG_VIDEO_LOGO is not set
# CONFIG_VIDEO_MXS is not set
# CONFIG_USB_GADGET is not set
# CONFIG_USB_GADGET_DOWNLOAD is not set
# CONFIG_CI_UDC is not set
# CONFIG_CMD_FASTBOOT is not set
# CONFIG_USB_FUNCTION_FASTBOOT is not set
# CONFIG_FASTBOOT_UUU_SUPPORT is not set
# CONFIG_FASTBOOT is not set
# CONFIG_FASTBOOT_FLASH is not set
# CONFIG_ARCH_MISC_INIT is not set
# CONFIG_DM_RNG is not set
# CONFIG_CMD_RNG is not set
# CONFIG_FSL_DCP_RNG is not set
```

Lý do lựa chọn:

- Kernel được boot trực tiếp bằng `bootz`; không dùng raw initrd.
- Kernel và DTB được đọc từ FAT trên eMMC; không cần SPI NOR, MTD hoặc QSPI.
- Không dùng video/splash U-Boot.
- Không dùng Fastboot/UUU trong bản U-Boot tối ưu hiện tại.
- Mạng được sử dụng sau khi Linux chạy, không cần DHCP/ping trong U-Boot.

Tác động:

- Giảm kích thước `u-boot.bin` và số code path có thể chạy/probe.
- Giảm bề mặt tấn công của U-Boot.
- Mất các command tương ứng trong U-Boot console.
- Mất đường recovery Fastboot/UUU trong build này.

### 2.5. Các cấu hình bắt buộc phải giữ

```config
CONFIG_CMD_MMC=y
CONFIG_CMD_FAT=y
CONFIG_FSL_USDHC=y
CONFIG_ENV_IS_IN_MMC=y
CONFIG_SYS_MMC_ENV_DEV=1
CONFIG_MXC_UART=y
CONFIG_OF_CONTROL=y
CONFIG_HUSH_PARSER=y
CONFIG_CMD_BOOTZ=y
```

Nhóm SPI sau cũng phải giữ:

```config
CONFIG_DM_74X164=y
CONFIG_SPI=y
CONFIG_DM_SPI=y
CONFIG_SOFT_SPI=y
```

Lý do: GPIO expander 74HC595/74x164 của device tree hoạt động qua `spi-gpio`. Khi tắt `CONFIG_DM_SPI`, linker đã báo thiếu:

```text
dm_spi_claim_bus
dm_spi_xfer
dm_spi_release_bus
```

Vì GPIO expander còn được dùng để điều khiển nguồn/reset ngoại vi, trong đó có nguồn Wi-Fi, không được tắt `DM_74X164` chỉ để giảm kích thước.

### 2.6. Chuẩn hóa cú pháp tắt Kconfig

Cú pháp sai trước đây:

```config
# CONFIG_CMD_USB=y
#CONFIG_CI_UDC=y
```

Hai dòng trên chỉ là comment thông thường và không đảm bảo Kconfig tắt symbol.

Cú pháp đúng:

```config
# CONFIG_CMD_USB is not set
# CONFIG_CI_UDC is not set
```

Sau khi chuẩn hóa, `u-boot-imx` đã build thành công và `.config` cuối được kiểm tra tại:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/build/okmx6ull_s_emmc_defconfig/.config
```

Defconfig gốc để đối chiếu:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/configs/mx6ull_14x14_evk_emmc_defconfig
```

Không sửa trực tiếp file trong `tmp/work`, vì BitBake có thể xóa và tạo lại nó.

## 3. Tối ưu `boot.scr` và cơ chế OTA

File nguồn:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-bsp/ota-boot-script/files/boot.cmd
```

Recipe tạo `boot.scr`:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-bsp/ota-boot-script/ota-boot-script.bb
```

### 3.1. Không `saveenv` trên mọi lần boot bình thường

Logic cũ:

```sh
else
    setenv ota_try 0
    saveenv
fi
```

Logic mới:

```sh
else
    if test "${ota_try}" != "0"; then
        setenv ota_try 0
        saveenv
    fi
fi
```

Lý do lựa chọn:

- `saveenv` ghi dữ liệu xuống eMMC.
- Nếu `ota_try` đã bằng `0`, ghi lại cùng giá trị là không cần thiết.
- Bỏ lần ghi dư giúp giảm một phần thời gian U-Boot và giảm hao mòn eMMC.
- Khi đang có OTA pending, việc tăng `ota_try` và `saveenv` vẫn được giữ để rollback hoạt động đúng.

### 3.2. Giảm log kernel trên UART

Bootargs mới thêm:

```text
quiet loglevel=3
```

Đoạn hoàn chỉnh:

```sh
setenv bootargs console=${console},${baudrate} root=${ota_root} rootwait rw quiet loglevel=3 ota.slot=${rootfs_slot} ota.kernel_slot=${kernel_slot} ota.rootfs_slot=${rootfs_slot} panic=5
```

Lý do lựa chọn:

- UART 115200 baud chậm hơn RAM/eMMC rất nhiều.
- Giảm số dòng log được in giúp console ít chiếm thời gian hơn và tránh log chen vào banner.
- Log kernel vẫn có thể đọc sau boot bằng `dmesg`.
- Mức `3` vẫn giữ các lỗi quan trọng.

## 4. Tối ưu root filesystem

File cấu hình image đã sửa:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/conf/local.conf
```

### 4.1. Bỏ package management khỏi image

Đã bỏ:

```bitbake
EXTRA_IMAGE_FEATURES += "package-management"
```

Tác động:

- Không còn kéo `apt`, `dpkg` và dữ liệu package management vào rootfs.
- Giảm dung lượng image và số file phải xử lý.
- Thiết bị production cập nhật bằng OTA A/B, không cần cài package trực tiếp trên board.

### 4.2. Không cài toàn bộ kernel modules

Đã bỏ:

```bitbake
IMAGE_INSTALL:append = " kernel-modules ..."
```

Thay bằng cài đúng driver Wi-Fi cần thiết:

```bitbake
IMAGE_INSTALL:append = " rtl8723du"
```

Lý do lựa chọn:

- `kernel-modules` kéo hàng trăm module camera, DVB, USB gadget, crypto và phần cứng không có trên board.
- Board chỉ cần driver phần cứng thực tế được sử dụng.
- Đây là thay đổi làm giảm rootfs nhiều nhất.

### 4.3. Bỏ các tiện ích userspace không cần

Đã bỏ khỏi `IMAGE_INSTALL`:

```text
iw
usbutils
openssh (gói tổng)
e2fsprogs (gói tổng)
```

Đã giữ đúng thành phần cần thiết:

```bitbake
IMAGE_INSTALL:append = " wpa-supplicant"
IMAGE_INSTALL:append = " rtl8723du"
IMAGE_INSTALL:append = " openssh-sshd openssh-sftp-server"
IMAGE_INSTALL:append = " init-ifupdown"
IMAGE_INSTALL:append = " wlan0-autostart"
IMAGE_INSTALL:append = " mosquitto mosquitto-clients"
IMAGE_INSTALL:append = " hnn-okm6ull-ota"
IMAGE_INSTALL:append = " libubootenv-bin"
IMAGE_INSTALL:append = " u-boot-env-config"
```

Lý do lựa chọn:

- SSH/SFTP vẫn hoạt động nhưng tránh khai báo gói tổng dư thừa.
- Wi-Fi vẫn dùng `wpa_supplicant` và driver RTL8723DU.
- MQTT broker/client và ứng dụng OTA được giữ nguyên theo yêu cầu.
- `fw_printenv/fw_setenv` vẫn có để điều khiển slot U-Boot từ Linux.

### 4.4. Đưa dependency vào đúng recipe OTA

File đã sửa:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-apps/hnn-okm6ull-ota/hnn-okm6ull-ota_1.0.bb
```

Runtime dependency hiện tại:

```bitbake
RDEPENDS:${PN} += " \
    mosquitto \
    zstd \
    e2fsprogs-mke2fs \
    libubootenv-bin \
    u-boot-env-config \
"
```

Lý do lựa chọn:

- App gọi trực tiếp `zstd`, `mkfs.ext4/mke2fs` và `fw_setenv` bằng `system()`.
- Dependency phải thuộc recipe app, không nên phụ thuộc ngầm vào `local.conf`.
- Khi app được đưa sang image khác, BitBake vẫn tự kéo đủ công cụ OTA.
- Chỉ dùng `e2fsprogs-mke2fs`, tránh kéo toàn bộ tiện ích `badblocks`, `dumpe2fs` và các tool không cần.

OTA rootfs hiện dùng luồng:

```sh
zstd -t rootfs.tar.zst
mkfs.ext4 -F /dev/mmcblk1pX
zstd -dc rootfs.tar.zst | tar --numeric-owner -xf - -C /mnt/rootfs
fw_setenv rootfs_slot B
```

`tar`, `mount`, `umount`, `cp`, `mkdir`, `chmod`, `sync` và `killall` được BusyBox cung cấp.

### 4.5. Kết quả giảm rootfs

Kết quả đã ghi nhận trong quá trình build:

| Hạng mục | Trước | Sau |
|---|---:|---:|
| Rootfs đã bung | khoảng 91 MiB | khoảng 51 MiB |
| Số package trong manifest | 422 | 98 |
| `rootfs.tar.zst` | — | khoảng 17 MiB |
| `rootfs.wic.zst` | — | khoảng 58 MiB |

Image đã được build thành công nhiều lần bằng:

```sh
source sources/poky/oe-init-build-env build-fb
bitbake core-image-minimal
```

## 5. Tối ưu BusyBox

Các file mới:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-core/busybox/busybox_%.bbappend
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-core/busybox/busybox/disable-unused.cfg
```

`busybox_%.bbappend` đưa fragment vào recipe gốc:

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://disable-unused.cfg"
```

Các nhóm applet đã tắt:

- Nén không dùng: gzip/gunzip, bzip2/bunzip2, unzip, xzcat, lzcat.
- Network tool không dùng: telnet, tftp, ftpget/ftpput, udhcpd, traceroute, netcat.
- Disk/console tool không dùng: fdisk, losetup, swap, framebuffer và console font/keymap.
- Quản lý user runtime: adduser/addgroup/deluser/delgroup.
- Debug tool không cần: hexdump, microcom, patch, strings, watch.

Các applet bắt buộc giữ cho OTA và boot:

```text
sh/ash, test, tar, mount, umount, cp, mv, rm, mkdir, chmod,
killall, sync, sleep, ifup, ifdown, udhcpc, ip, ifconfig, route
```

Lý do lựa chọn:

- Giảm thêm kích thước BusyBox và số command không cần trên production.
- Chỉ tắt applet không nằm trong boot/OTA/network path.
- Mức tiết kiệm nhỏ hơn nhiều so với bỏ `kernel-modules`, nên phải ưu tiên tính ổn định.

## 6. Banner và trải nghiệm boot

Các file mới:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-core/system-banner/system-banner.bb
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-core/system-banner/files/issue
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-core/system-banner/files/banner-unicode
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-core/system-banner/files/motd
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-core/system-banner/files/okmx6ull-banner.sh
```

Package được thêm vào image bằng:

```bitbake
IMAGE_INSTALL:append = " system-banner"
```

Thiết kế:

- UART/Minicom dùng ASCII thuần để tránh lỗi Unicode trên terminal VT102.
- SSH/PTY dùng Unicode block art `HNN VIET NAM`.
- Sau login hiển thị model, CPU, RAM, kernel, hostname, IP, OTA slot, uptime và phiên bản U-Boot.
- Script chỉ chạy trên interactive terminal để không phá SCP, SFTP, systemd hoặc remote command.

Ban đầu serial getty được cấu hình chờ `wlan0-autostart.service` để tránh kernel log xé banner. Cấu hình này sau đó đã bị loại bỏ vì có thể làm login UART chậm tới 20 giây. Hiện UART login không chờ Wi-Fi.

## 7. Cấu hình mạng và service: thay đổi đã hoàn tác

Các file liên quan:

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-core/wlan0-autostart/files/wlan0-autostart.service
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-core/init-ifupdown/init-ifupdown/okmx6ull-s-emmc/interfaces
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-apps/hnn-okm6ull-ota/files/hnn-okm6ull-ota.service
```

Đã thử:

- Chuyển Wi-Fi service từ `Type=oneshot` sang `Type=simple`.
- Giảm vòng chờ interface từ 20 xuống 8 giây.
- Bỏ `auto wlan0`.
- Bỏ `ExecStartPre` chờ default route của app OTA.

Kết quả trên board:

```text
wlan0: <NO-CARRIER,BROADCAST,MULTICAST,UP>
ping: sendto: Network is unreachable
```

Nguyên nhân: thứ tự giữa driver, `wpa_supplicant`, `ifup`, DHCP và app không còn ổn định. Interface được đưa lên nhưng chưa associate và không có IP/default route.

Quyết định cuối cùng: hoàn tác toàn bộ thay đổi mạng và giữ luồng ổn định cũ:

```ini
Type=oneshot
ExecStartPre=/bin/sh -c 'for i in $(seq 1 20); do [ -e /sys/class/net/wlan0 ] && exit 0; sleep 1; done; exit 1'
ExecStart=/sbin/ifup wlan0
RemainAfterExit=yes
```

Trong `/etc/network/interfaces` tiếp tục giữ:

```text
auto wlan0
iface wlan0 inet dhcp
```

App OTA tiếp tục chờ default route:

```ini
ExecStartPre=/bin/sh -c 'for i in $(seq 1 30); do ip route | grep -q default && exit 0; sleep 1; done; exit 1'
```

Lý do lựa chọn:

- Mạng và OTA quan trọng hơn việc giảm vài giây bằng cách phá ordering.
- UART/getty đã được tách khỏi Wi-Fi nên người dùng vẫn thấy login sớm.
- Cần thiết kế lại network state machine hoặc dùng systemd-networkd trước khi tiếp tục tối ưu phần này.

## 8. Các file khác đã thao tác

### 8.1. Command LED U-Boot

```text
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-bsp/u-boot/files/command_blink_led.c
```

Command vẫn được giữ để debug/thao tác thủ công, nhưng đã bị loại khỏi boot command bình thường để không tạo delay.
