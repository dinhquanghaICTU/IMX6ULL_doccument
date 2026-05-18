#!/usr/bin/env bash
 set -e
  KERNEL_SRC=~/work/
  ROOTFS=/home/forlinx/work/rootfs
  ROOTFS_URL="https://github.com/dinhquanghalCTU/IMX6ULL_document/releases/download/v1.0/rootfs-console.tar.bz2"
cd $KERNEL_SRC
echo "================= install build packages ================="
apt update
apt install libncurses5-dev libncursesw5-dev lzop -y
. /opt/fsl-imx-x11/4.1.15-2.0.0/environment-setup-cortexa7hf-neon-poky-linux-gnueabi
echo "================= load default config ================="
make mrproper

make imx6ull_defconfig

echo "================= configure kernel ================="
if [ -x scripts/config ]; then
    # Disable camera / media / video capture stack
    scripts/config --disable MEDIA_SUPPORT
    scripts/config --disable VIDEO_DEV
    scripts/config --disable VIDEO_V4L2
    scripts/config --disable V4L_PLATFORM_DRIVERS
    scripts/config --disable VIDEO_MXC_CAPTURE
    scripts/config --disable VIDEO_MXC_OUTPUT
    scripts/config --disable VIDEO_MXC_CSI_CAMERA
    scripts/config --disable MXC_CAMERA_OV5640
    scripts/config --disable MXC_CAMERA_OV5642
    scripts/config --disable MXC_CAMERA_OV5640_MIPI
    scripts/config --disable MXC_CAMERA_OV5642_MIPI
    scripts/config --disable MXC_TVIN_ADV7180
    scripts/config --disable VIDEO_OV9650
    scripts/config --disable USB_VIDEO_CLASS
    scripts/config --disable USB_GSPCA

    # Disable extra tuner/radio/DVB stack
    scripts/config --disable DVB_CORE
    scripts/config --disable MEDIA_TUNER
    scripts/config --disable RADIO_ADAPTERS

    # Disable USB audio if unused
    scripts/config --disable SND_USB_AUDIO

    make olddefconfig
else
    echo "WARNING: scripts/config not found or not executable, skip config tuning"
fi

echo "================= build kernel/dtb/modules ================="
make -j"$(nproc)" zImage dtbs modules

cd $KERNEL_SRC
mkdir rootfs
cd rootfs

wget https://github.com/dinhquanghaICTU/IMX6ULL_doccument/releases/download/v1.0/rootfs-console.tar.bz2

tar xvf rootfs-console.tar.bz2



mkdir -p etc/wpa_supplicant

echo "================= create wifi config ================="

sudo tee etc/wpa_supplicant.conf >/dev/null <<'EOF'
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
update_config=1

network={
    ssid="GIANG HA"
    psk="Z0358868830"
}
EOF

echo "================= create network interfaces ================="

sudo tee etc/network/interfaces >/dev/null <<'EOF'
# loopback
auto lo
iface lo inet loopback

# WiFi
auto wlan0
iface wlan0 inet dhcp
    wpa-driver wext
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

# Ethernet eth0
auto eth0
iface eth0 inet static
    address 192.168.0.232
    netmask 255.255.255.0
    broadcast 192.168.0.255

# USB gadget
auto usb0
iface usb0 inet static
    address 192.168.7.2
    netmask 255.255.255.0
    network 192.168.7.0
    gateway 192.168.7.1
EOF

echo "================= verify ================="

cat etc/wpa_supplicant.conf

echo "------------------------------------------"

cat etc/network/interfaces

wget https://mosquitto.org/files/source/mosquitto-1.6.15.tar.gz
tar xvf mosquitto-1.6.15.tar.gz

cd mosquitto-1.6.15

source /opt/fsl-imx-x11/4.1.15-2.0.0/environment-setup-cortexa7hf-neon-poky-linux-gnueabi

make clean

make \
  CROSS_COMPILE= \
  WITH_TLS=no \
  WITH_TLS_PSK=no \
  WITH_SRV=no \
  WITH_WEBSOCKETS=no \
  WITH_DOCS=no \
  WITH_SHARED_LIBRARIES=yes \
  WITH_STATIC_LIBRARIES=yes \
  prefix=/usr \
  -j"$(nproc)"

echo "================= verify build output ================="

file src/mosquitto
file client/mosquitto_pub
file client/mosquitto_sub
file lib/libmosquitto.so.1

echo "================= verify done ================="


echo "================= install mosquitto to rootfs ================="

ROOTFS=/home/forlinx/work_linx/rootfs

sudo mkdir -p $ROOTFS/usr/sbin
sudo mkdir -p $ROOTFS/usr/bin
sudo mkdir -p $ROOTFS/usr/lib

sudo cp src/mosquitto $ROOTFS/usr/sbin/
sudo cp client/mosquitto_pub $ROOTFS/usr/bin/
sudo cp client/mosquitto_sub $ROOTFS/usr/bin/
sudo cp lib/libmosquitto.so.1 $ROOTFS/usr/lib/

echo "================= create symlink ================="

cd $ROOTFS/usr/lib
sudo ln -sf libmosquitto.so.1 libmosquitto.so

echo "================= set execute permission ================="

sudo chmod +x $ROOTFS/usr/sbin/mosquitto
sudo chmod +x $ROOTFS/usr/bin/mosquitto_pub
sudo chmod +x $ROOTFS/usr/bin/mosquitto_sub

echo "================= verify install ================="

ls -lh $ROOTFS/usr/sbin/mosquitto
ls -lh $ROOTFS/usr/bin/mosquitto_pub
ls -lh $ROOTFS/usr/bin/mosquitto_sub
ls -lh $ROOTFS/usr/lib/libmosquitto.so*

echo "================= mosquitto install done ================="

echo "================= create mosquitto config ================="

sudo mkdir -p $ROOTFS/etc/mosquitto

sudo tee $ROOTFS/etc/mosquitto/mosquitto.conf >/dev/null <<'EOF'
listener 1883 0.0.0.0
allow_anonymous true
persistence false
log_dest stdout
EOF

echo "================= verify mosquitto config ================="

cat $ROOTFS/etc/mosquitto/mosquitto.conf

echo "================= mosquitto config done ================="


cd /home/forlinx

mkdir -p source_app
cd source_app

cat > app.c <<'EOF'
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <unistd.h>

#define BROKER_IP   "192.168.1.8"
#define BROKER_PORT 1883
#define CLIENT_ID   "imx6ull_led1"
#define TOPIC       "test/topic"

#define LED_TRIGGER    "/sys/class/leds/led1/trigger"
#define LED_BRIGHTNESS "/sys/class/leds/led1/brightness"

#define BUF_SIZE 1024

static int put_remaining_length(unsigned char *buf, int len)
{
    int i = 0;

    do {
        unsigned char encoded = len % 128;
        len /= 128;
        if (len > 0)
            encoded |= 128;
        buf[i++] = encoded;
    } while (len > 0);

    return i;
}

static int put_string(unsigned char *buf, const char *s)
{
    int len = strlen(s);

    buf[0] = (unsigned char)(len >> 8);
    buf[1] = (unsigned char)(len & 0xff);
    memcpy(buf + 2, s, len);

    return len + 2;
}

static int read_exact(int fd, unsigned char *buf, int len)
{
    int total = 0;

    while (total < len) {
        int n = read(fd, buf + total, len - total);
        if (n <= 0)
            return -1;
        total += n;
    }

    return 0;
}

static int read_remaining_length(int fd, int *out_len)
{
    int multiplier = 1;
    int value = 0;
    unsigned char encoded;

    do {
        if (read_exact(fd, &encoded, 1) < 0)
            return -1;

        value += (encoded & 127) * multiplier;
        multiplier *= 128;

        if (multiplier > 128 * 128 * 128)
            return -1;
    } while (encoded & 128);

    *out_len = value;
    return 0;
}

static int mqtt_read_packet(int fd, unsigned char *type,
                            unsigned char *buf, int *len)
{
    if (read_exact(fd, type, 1) < 0)
        return -1;

    if (read_remaining_length(fd, len) < 0)
        return -1;

    if (*len > BUF_SIZE)
        return -1;

    if (read_exact(fd, buf, *len) < 0)
        return -1;

    return 0;
}

static int write_text_file(const char *path, const char *value)
{
    int fd = open(path, O_WRONLY);
    ssize_t written;
    size_t len;

    if (fd < 0) {
        perror(path);
        return -1;
    }

    len = strlen(value);
    written = write(fd, value, len);
    close(fd);

    if (written != (ssize_t)len) {
        perror("write");
        return -1;
    }

    return 0;
}

int main(void)
{
    printf("MQTT LED APP START\\n");
    return 0;
}
EOF

echo "================= build mqtt app ================="

echo "================= build mqtt app ================="

source /opt/fsl-imx-x11/4.1.15-2.0.0/environment-setup-cortexa7hf-neon-poky-linux-gnueabi

${CC} app.c -o mqtt_led_app

file mqtt_led_app

sudo mkdir -p $ROOTFS/usr/bin

sudo cp mqtt_led_app $ROOTFS/usr/bin/


echo "================= check rootfs app ================="

ls -lh $ROOTFS/usr/bin/

echo "----------------------------------"

file $ROOTFS/usr/bin/mqtt_led_app

echo "================= check done ================="

cat > /etc/rc.local <<'EOF'
#!/bin/sh

# By default this script does nothing.

if [ -e /laohua ]
then
    /laohua/test.sh &
fi

lcd_screen_arg() {
    geom=`fbset | grep geometry`
    w=`echo $geom | awk '{ print $2 }'`
    h=`echo $geom | awk '{ print $3 }'`
    echo -n "${w}x${h}"
}

LCD_SIZE=`lcd_screen_arg`

if [ "$LCD_SIZE" == "480x272" ] ; then
    DISPLAY=:0 xinput --set-prop 'iMX6UL TouchScreen Controller' 'Evdev Axes Swap' 0
elif [ "$LCD_SIZE" == "800x600" ] ; then
    DISPLAY=:0 xinput --set-prop 'iMX6UL TouchScreen Controller' 'Evdev Axes Swap' 0
elif [ "$LCD_SIZE" == "1280x800" ] ; then
    DISPLAY=:0 xinput --set-prop 'goodix-ts' 'Evdev Axes Swap' 1
fi

(
while true
do
    if ! ip a show wlan0 | grep -q "inet "; then
        echo "WiFi down reconnect"

        killall wpa_supplicant 2>/dev/null

        ifconfig wlan0 up

        wpa_supplicant -B -i wlan0 \
            -c /etc/wpa_supplicant/wpa_supplicant.conf

        sleep 5

        udhcpc -i wlan0 -n -q
    fi

    sleep 10
done
) &

(
sleep 10
/usr/bin/mqtt_led_app
) &

echo 30000 > /proc/sys/vm/min_free_kbytes

exit 0
EOF

chmod +x /etc/rc.local

cat /etc/rc.local


cd /home/forlinx/work/rootfs
rm -rf  rootfs-console.tar.bz2 
sudo fakeroot tar cvjf rootfs-console.tar.bz2 *      

cd /home/forlinx/

mkdir flash


FLASH_DIR=/home/forlinx/flash
KERNEL_SRC=/home/forlinx/work
ROOTFS_DIR=/home/forlinx/work/rootfs

echo "================= copy rootfs ================="

cp $ROOTFS_DIR/rootfs-console.tar.bz2 $FLASH_DIR/

echo "================= copy dtb ================="

cp $KERNEL_SRC/arch/arm/boot/dts/okmx6ull-s-emmc.dtb \
$FLASH_DIR/

echo "================= copy zImage ================="

cp $KERNEL_SRC/arch/arm/boot/zImage \
$FLASH_DIR/

echo "================= verify ================="

ls -lh $FLASH_DIR

echo "================= DONE ================="



cd

cd /home/forlinx/flash

cat > create_rootfs_wifi_wic.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

# Create a 2-partition .wic image for OKM6ULL-S:
#   p1: FAT32 boot partition, contains zImage and DTB
#   p2: ext4 rootfs partition, contains extracted rootfs-console.tar.bz2

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

echo "================= input files ================="

echo "kernel : $KERNEL"
echo "dtb    : $DTB"
echo "rootfs : $ROOTFS"

echo "==============================================="

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

echo "loop device: $LOOP_DEV"

echo "Format partitions"

sudo mkfs.vfat -F 32 -n BOOT "${LOOP_DEV}p1"

sudo mkfs.ext4 -F -L rootfs "${LOOP_DEV}p2"

echo "Mount partitions"

sudo mkdir -p "$BOOT_MNT"
sudo mkdir -p "$ROOT_MNT"

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

echo "================= image created ================="

ls -lh "$IMG"

echo "================= DONE ================="
EOF
chmod +x create_rootfs_wifi_wic.sh
sudo ./create_rootfs_wifi_wic.sh
 echo "================= OK ================="
