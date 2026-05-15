# CÁCH ĐỂ BUILD LINUX KERNEL + DTB +ROOTFS TRÊN OKM6ULL-S

## I. CÁC BƯỚC BUILD KERNEL + DTB + ROOTFS  : 


- Tài liệu này dựa trên tài liệu base của hãng /OKM6ULL-S/doc/how_to_build_SDK/Development_Environment.md, em custom lại 

## Bước 1. Cài Ubuntu phiên bản ubuntu 18.04 LTS BẮT BUỘC

- Nếu không cài sẽ gặp các lỗi khi biên dịch sau này.

## Bước 2. Bắt đầu quá trình xây build kernel

- Lấy src mã nguồn về qua link này để tải `linux-4.1.15.tar.bz2` và cho vào `/work`.

Link tải:

```text
https://onedrive.live.com/?redeem=aHR0cHM6Ly8xZHJ2Lm1zL2YvYy80ZTdjYWNlYmNmYWJjMmUwL0VnclFpWjJldE5GT2l4bGZ1eFY2aUFJQnNQS0VOVnRlQUxtQ2dtM2lIbXNGQlE%5FZT1mT05JSHo&id=4E7CACEBCFABC2E0%21s23a498b753e5455bb7fbff2d7e6a511b&cid=4E7CACEBCFABC2E0&sb=name&sd=1
```

Chuyển qua quyền sudo luôn cho đỡ vì rất nhiều files cần quyền sudo nên chuyển luôn:

```bash
sudo su
```

Tạo thư mục build cho gọn:

```bash
mkdir work
```

Di chuyển tới thư mục vừa tạo:

```bash
cd work
```

Giải nén mã nguồn ra, trước khi giải nén cần tải mã nguồn về và cho vào thư mục `/work`:

```bash
tar xvf linux-4.1.15.tar.bz2
```

## Bước 3. Tải files script SDK

Tải files script:

lệnh này dùng để cấp quyền thực thi script
chmod +x fsl-imx-x11-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-toolchain-4.1.15-2.0.0.sh


script

```text
. /fsl-imx-x11-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-toolchain-4.1.15-2.0.0.sh
```
lệnh này gọi biến môi trường ra để biên dịch (mỗi tắt terminal đi muốn chạy được phải set nó lên)
. /opt/fsl-imx-x11/4.1.15-2.0.0/environment-setup-cortexa7hf-neon-poky-linux-gnueabi


lên
Tải ở link này và cho nó vào thư mục `work`:

```text
https://onedrive.live.com/?redeem=aHR0cHM6Ly8xZHJ2Lm1zL2YvYy80ZTdjYWNlYmNmYWJjMmUwL0VnclFpWjJldE5GT2l4bGZ1eFY2aUFJQnNQS0VOVnRlQUxtQ2dtM2lIbXNGQlE%5FZT1mT05JSHo&id=4E7CACEBCFABC2E0%21sbcfcde53b16f49e6854e4b86ea9e9c2c&cid=4E7CACEBCFABC2E0&sb=name&sd=1
```

- Files script này set các biến và nạp môi trường cross-compile của Yocto SDK.

Các biến nó set:

```text
CC
CXX
LD
AR
AS
STRIP
CROSS_COMPILE
ARCH
SDKTARGETSYSROOT
PATH
PKG_CONFIG_PATH
```

- Mục đích sau này khi chạy `make zImage` hoặc `make dtbs` nó sẽ biên dịch chéo các lib hay các file header cho ARM Cortex-A7 i.MX6ULL.
- Lưu ý file này phải chạy khi đầu tiên khi mở terminal mới để biên dịch.

## Bước 4. Chạy files script imx6ull_build.sh

Kiểm tra xem có files trong `work` chưa:

```bash
ls
```

- Nếu có files `imx6ull_build.sh` thì bắt đầu chạy. Nếu không có xem lại đã giải nén `linux-4.1.15.tar.bz2` chưa?

```bash
./imx6ull_build.sh
```

- Sau khi chạy ra build thành công nó sẽ ra các files `.ko` đó chính là các file driver như `8723du.ko` là driver của chip wifi RTL8723DU.

## Bước 5. Build zImage

`zImage` là files kernel đã nén lại.

Ở đây có hai sự lựa chọn:

### Lựa chọn 1: Dùng sẵn files config của hãng

Dùng sẵn files config của hãng nó sẽ tích hợp đầy đủ các module và driver trên board, rất nặng nếu full option.




Tạo `.config` từ config của hãng:

```bash
make imx6ull_defconfig
```

Lệnh này sẽ build `zImage`, `dtbs` và `modules`:

- mục đích của make dtbs là sau khi sửa thêm hay xóa driver ta phải make dtbs lại mới config ta đã chỉnh.

```bash
make -j$(nproc) zImage dtbs modules
```

### Lựa chọn 2: Nếu muốn config riêng

Nếu muốn config riêng xem mình cần những modul hay driver nào hoặc tối ưu cho kernel thì có thể tạo ra files script riêng.

Lệnh này là tạo files config mới lấy `.config` của hãng làm nền để mình có thể ennable hoặc disable những thứ mình không dùng đến:

```bash
cp .config arch/arm/configs/test_defconfig
```



- trước khi chạy ta cần cài các package cần thiết để có thể  dùng được menuconfig
apt update
apt install libncurses5-dev libncursesw5-dev -y

Mình có thể dùng gui để config:

```bash
make menuconfig
```

Lệnh này ghi đè lên files config đang dùng:

```bash
make test_defconfig
```

Lệnh này sẽ build `zImage`, `dtbs` và `modules`, là các file có `<M>` trong files config mà mình vừa chỉnh:

- đến đoạn này có thể thiếu các package nên cần cài 
apt update
apt install lzop -y

```bash
make -j$(nproc) zImage dtbs modules
```

## Bước 6. Build rootfs

Nếu đang ở sudo thì có thể thoát `su` bằng lệnh:

```bash
exit
```

Sau đó tải `rootfs-console.tar.bz2` ở link:

```text
https://onedrive.live.com/?redeem=aHR0cHM6Ly8xZHJ2Lm1zL2YvYy80ZTdjYWNlYmNmYWJjMmUwL0VnclFpWjJldE5GT2l4bGZ1eFY2aUFJQnNQS0VOVnRlQUxtQ2dtM2lIbXNGQlE%5FZT1mT05JSHo&id=4E7CACEBCFABC2E0%21s202273b474d0417c983cca3547533a3f&cid=4E7CACEBCFABC2E0&sb=name&sd=1
```

Và cho nó vào `/work`.

Sau đó tạo thư mục chứa rootfs:

```bash
sudo mkdir rootfs
```

Di chuyển vào rootfs:

```bash
cd rootfs
```

Lệnh này copy `rootfs-console.tar.bz2` ở `work` vào thư mục `/rootfs`:

```bash
sudo cp ../rootfs-console.tar.bz2 ./
```

Lệnh này giải nén files `rootfs-console.tar.bz2`:

```bash
sudo tar xvf rootfs-console.tar.bz2
```

Sau khi giải nén song dùng lệnh này để kiểm tra:

```bash
ls
```

Nếu có các thư mục này là được:

```text
bin  dev  etc  forlinx  home  lib  media  mnt  proc  run  sbin  sys  tmp  usr  var
```

Sau đó muốn sửa thêm cái gì thì có thể chỉnh lại rootfs ví dụ như tự động kết nối wifi:

```bash
cd /home/forlinx/work_linx/rootfs
mkdir -p etc/wpa_supplicant
wpa_passphrase "SALE" "66668888" > etc/wpa_supplicant/wpa_supplicant.conf
```

Hoặc là vào `etc/network/interfaces` sửa cho wlano dùng DHCP cấp địa chỉ ip tự động:

```bash
cat /home/forlinx/work_linx/rootfs/etc/network/interfaces
```

Sau đó nén lại để flash cho dễ và di chuyển qua windown cho dễ bằng mobaxterm:

```bash
sudo fakeroot tar cvjf rootfs-console.tar.bz2 *
```

Sau khi chạy xong lệnh này có thể kiểm tra trong thư mục boot, nó sẽ chứa `zImage` và trong `dts` có file `.dtb` là được:

```bash
ls /home/forlinx/work_linx/arch/arm/boot
ls /home/forlinx/work_linx/arch/arm/boot/dts/okmx6ull-s-emmc.dtb
```

Di chuyển tới đây chuẩn bị tạo thư mục chứa các file đã build cho gọn, chuẩn bị tạo file `.wic`:

```bash
cd /home/forlinx/
mkdir -p release_wifi
```

Sau đó copy `dtb` cần thiết, `zImage` và `rootfs-console.tar.bz2`:

```bash
cp /home/forlinx/work_linx/arch/arm/boot/dts/okmx6ull-s-emmc.dtb \
   /home/forlinx/work_linx/arch/arm/boot/zImage \
   /home/forlinx/work_linx/rootfs-console.tar.bz2 \
   /home/forlinx/release_wifi/
```

Kiểm tra lại:

```bash
ls -lh /home/forlinx/release_wifi
```

Sau khi làm đến đây muốn đơn giản hơn nữa thì nén nó thành file `.wic`, sau này flash lên bằng `uuu` sẽ đơn giản.

```bash
cd /home/forlinx/release_wifi
```

Tạo file script `create_rootfs_wifi_wic.sh` cùng cấp với `zImage`, `okmx6ull-s-emmc.dtb`, `rootfs-console.tar.bz2`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

IMG="${IMG:-rootfs_wifi.wic}"
ROOTFS="${ROOTFS:-rootfs-console.tar.bz2}"
KERNEL="${KERNEL:-zImage}"
DTB="${DTB:-okmx6ull-s-emmc.dtb}"
IMAGE_SIZE_MB="${IMAGE_SIZE_MB:-2048}"
BOOT_START="${BOOT_START:-8MiB}"
BOOT_END="${BOOT_END:-128MiB}"
BOOT_MNT="${BOOT_MNT:-/mnt/wic_boot}"
ROOT_MNT="${ROOT_MNT:-/mnt/wic_root}"

LOOP_DEV=""
BOOT_MOUNTED=0
ROOT_MOUNTED=0

die() {
    echo "ERROR: $*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

cleanup() {
    set +e
    sync
    if [ "$BOOT_MOUNTED" = "1" ]; then
        sudo umount "$BOOT_MNT"
    fi
    if [ "$ROOT_MOUNTED" = "1" ]; then
        sudo umount "$ROOT_MNT"
    fi
    if [ -n "$LOOP_DEV" ]; then
        sudo losetup -d "$LOOP_DEV"
    fi
}

trap cleanup EXIT

need_cmd dd
need_cmd parted
need_cmd losetup
need_cmd mkfs.vfat
need_cmd mkfs.ext4
need_cmd mount
need_cmd tar
need_cmd sudo

[ -f "$ROOTFS" ] || die "Cannot find rootfs archive: $ROOTFS"
[ -f "$KERNEL" ] || die "Cannot find kernel image: $KERNEL"
[ -f "$DTB" ] || die "Cannot find DTB file: $DTB"

echo "Input files:"
echo "  kernel : $KERNEL"
echo "  dtb    : $DTB"
echo "  rootfs : $ROOTFS"
echo

if [ -e "$IMG" ]; then
    echo "Remove old image: $IMG"
    rm -f "$IMG"
fi

echo "Create empty image: $IMG (${IMAGE_SIZE_MB}MB)"
dd if=/dev/zero of="$IMG" bs=1M count="$IMAGE_SIZE_MB" status=progress

echo "Create MBR partition table"
parted -s "$IMG" mklabel msdos
parted -s "$IMG" mkpart primary fat32 "$BOOT_START" "$BOOT_END"
parted -s "$IMG" set 1 boot on
parted -s "$IMG" mkpart primary ext4 "$BOOT_END" 100%

echo "Attach loop device"
LOOP_DEV="$(sudo losetup --find --show -P "$IMG")"
echo "  loop: $LOOP_DEV"

echo "Format partitions"
sudo mkfs.vfat -F 32 -n BOOT "${LOOP_DEV}p1"
sudo mkfs.ext4 -F -L rootfs "${LOOP_DEV}p2"

echo "Mount partitions"
sudo mkdir -p "$BOOT_MNT" "$ROOT_MNT"
sudo mount "${LOOP_DEV}p1" "$BOOT_MNT"
BOOT_MOUNTED=1
sudo mount "${LOOP_DEV}p2" "$ROOT_MNT"
ROOT_MOUNTED=1

echo "Copy boot files"
sudo cp "$KERNEL" "$BOOT_MNT/"
sudo cp "$DTB" "$BOOT_MNT/"

echo "Extract rootfs"
sudo tar --numeric-owner -xpf "$ROOTFS" -C "$ROOT_MNT"

echo "Flush data"
sync

echo "Image created successfully:"
ls -lh "$IMG"
```

Chạy script:

```bash
chmod +x create_rootfs_wifi_wic.sh
./create_rootfs_wifi_wic.sh
```

Sau khi nó chạy xong sẽ tạo ra file:

```text
rootfs_wifi.wic
```

Bắt đầu đến bước flash cho board để xem thành quả.

Đọc tiếp ở thư mục:

```text
/OKM6ULL-S/How_to_flash_OKM6ULL-S.md
```
