# CÁCH FLASH VÀO NOR VÀ NẠP BOOTFS VÀO SDCARD

---

- Hãng có hai Tools dùng để flash và ghi vào sdcard:
    + mfgtools (có UI nhưng nó đã bị out date, không còn được hỗ trợ)
    + sử dụng uuu (tools được khuyến nghị nhất thời điểm hiện tại, nhẹ, vào sử dụng command, có thể xây thành tools sau này)

---

## I. Nạp uboot + kernel + dtb vào Nor bằng uuu

+ tạo 1 file script flash-qspi.uuu

+ lý do chia flash như này là theo format của hãng
    0x000000    0x100000   U-Boot (1MB)
    0x100000    0x700000   Kernel (7MB)
    0x800000    0x100000   DTB (1MB)

-> em xem trong tài liệu 1. i.MX Linux User's Guide

```
uuu_version 1.2.39

# Step 1: Boot uboot lên RAM qua SDP
SDP: boot -f u-boot-imx6ull14x14evk_sd.imx

# Step 2: Flash uboot qspi1 vào NOR offset 0x0
FB[-t 15000]: ucmd sf probe
FB[-t 15000]: ucmd sf erase 0x0 0x100000
FB[-t 15000]: ucmd setenv fastboot_buffer ${loadaddr}
FB[-t 15000]: download -f u-boot-imx6ull14x14evk_qspi1.imx
FB[-t 15000]: ucmd sf write ${loadaddr} 0x0 ${fastboot_bytes}

# Step 3: Flash zImage vào NOR offset 0x100000
FB[-t 15000]: ucmd sf erase 0x100000 0x700000
FB[-t 15000]: ucmd setenv fastboot_buffer 0x81000000
FB[-t 15000]: download -f zImage-imx6ul7d.bin
FB[-t 15000]: ucmd sf write 0x81000000 0x100000 ${fastboot_bytes}

# Step 4: Flash dtb vào NOR offset 0x800000
FB[-t 15000]: ucmd sf erase 0x800000 0x100000
FB[-t 15000]: ucmd setenv fastboot_buffer 0x83000000
FB[-t 15000]: download -f imx6ull-14x14-evk.dtb
FB[-t 15000]: ucmd sf write 0x83000000 0x800000 ${fastboot_bytes}

# Step 5: Ghi rootfs wic vào SD card
FB[-t 60000]: ucmd setenv fastboot_dev mmc
FB[-t 60000]: ucmd setenv mmcdev ${sd_dev}
FB[-t 60000]: ucmd mmc dev ${sd_dev}
FB[-t 60000]: flash -raw2sparse all imx-image-base-imx6ul7d.wic

FB: done
```

---

### Chi tiết từng bước:

**SDP: boot -f u-boot-imx6ull14x14evk_sd.imx**

- Load uboot vào RAM trước để thực thi được lệnh command uboot
- ROM code chỉ hỗ trợ serial download protocol (SDP) qua USB
- U-Boot SD version được load vào RAM và chạy

---

**FB[-t 15000]: ucmd sf probe**

- `FB` = Fastboot protocol (sau khi U-Boot đã boot)
- `[-t 15000]` = timeout 15 giây cho mỗi lệnh
- `ucmd` = U-Boot command
- `sf probe` = detect và khởi tạo QSPI/NOR flash chip

---

**FB[-t 15000]: ucmd sf erase 0x0 0x100000**

- `sf erase` = xóa vùng nhớ trên NOR flash
- Offset `0x0`, size `0x100000` (1MB) cho U-Boot

---

**FB[-t 15000]: ucmd setenv fastboot_buffer ${loadaddr}**

- `setenv` = U-Boot command set environment variable
- `fastboot_buffer` = biến chỉ định RAM address buffer dùng cho fastboot operations
- `${loadaddr}` = biến môi trường mặc định, địa chỉ RAM an toàn để load file (thường 0x80008000)

---

**FB[-t 15000]: download -f u-boot-imx6ull14x14evk_qspi1.imx**

- `download` = UUU command download file từ PC qua USB fastboot
- File được ghi vào RAM trước (tại `fastboot_buffer`)
- Chưa flash ra NOR

---

**FB[-t 15000]: ucmd sf write ${loadaddr} 0x0 ${fastboot_bytes}**

- `sf write` = U-Boot command ghi từ RAM vào NOR flash
- `${loadaddr}` = nguồn (RAM address có file vừa download)
- `0x0` = đích (NOR offset)
- `${fastboot_bytes}` = số bytes đã download (U-Boot tự set sau lệnh download)
- **Lúc này U-Boot mới bắt đầu ghi vào NOR flash**

---

**Các file còn lại (kernel, dtb) tương tự**

- Tương tự với U-Boot: erase → set buffer → download → sf write
- Offset khác nhau (0x100000 cho kernel, 0x800000 cho dtb)
- Buffer addresses khác nhau (0x81000000, 0x83000000)

---

## II. Cơ chế ghi vào SD card

Vì trước đó đang làm việc với NOR, khi chuyển sang làm việc với SD card phải:

---

**FB[-t 60000]: ucmd setenv fastboot_dev mmc**

- `fastboot_dev` = biến môi trường chỉ định storage device cho fastboot
- Set thành `mmc` để dùng MMC driver (SD/eMMC) thay vì `nor` (NOR/QSPI)

---

**FB[-t 60000]: ucmd setenv mmcdev ${sd_dev}**

- `mmcdev` = biến môi trường chỉ định MMC device number
- `${sd_dev}` = biến tự động được UUU nhận diện khi detect SD card
- Nếu là 0/1 thì là SD card, nếu là 1/2 thì là eMMC

---

**FB[-t 60000]: ucmd mmc dev ${sd_dev}**

- `mmc dev` = U-Boot command chọn MMC device
- Select device tương ứng với `${sd_dev}` (SD card hoặc eMMC)

---

**FB[-t 60000]: flash -raw2sparse all imx-image-base-imx6ul7d.wic**

- `flash` = UUU command flash image vào storage
- `-raw2sparse` = convert raw image sang sparse format
- `all` = flash toàn bộ image (tất cả partitions)
- `imx-image-base-imx6ul7d.wic` = file image SD card

**Tại sao cần -raw2sparse?**
- Raw `.wic` file có thể chứa nhiều block `0xFFFF` (trống)
- Sparse format chỉ gửi data thực tế
- Tăng tốc độ flash, giảm thời gian transfer qua USB

---

## III. Cách chạy

```
uuu flash-qspi.uuu
```
