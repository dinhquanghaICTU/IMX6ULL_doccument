#!/usr/bin/env bash
set -Eeuo pipefail

# Create a 2-partition .wic image for OKM6ULL-S:
#   p1: FAT32 boot partition, contains zImage and DTB
#   p2: ext4 rootfs partition, contains extracted rootfs-console.tar.bz2
#
# Run this script from the release directory that contains:
#   zImage
#   okmx6ull-s-emmc.dtb
#   rootfs-console.tar.bz2
#
# Example:
#   cd /home/forlinx/release_wifi
#   chmod +x create_rootfs_wifi_wic.sh
#   ./create_rootfs_wifi_wic.sh

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
