# So sanh chi tiet: imx_loader va UUU

Tai lieu nay so sanh `imx_loader`/`imx_usb_loader` voi `uuu` trong bai toan boot va flash board NXP/Freescale i.MX, dac biet la i.MX6ULL.

## Ket luan nhanh

Neu chi can nap U-Boot vao RAM de test boot tam thoi, `imx_loader` la du.

Neu can flash san xuat, nap U-Boot/kernel/DTB/rootfs vao NOR, SD card, eMMC, hoac muon viet script tu dong, nen dung `uuu`.

```text
imx_loader:
PC -> USB SDP -> ROM code -> nap u-boot.imx vao RAM -> U-Boot chay

uuu:
PC -> USB SDP -> ROM code -> nap U-Boot vao RAM -> Fastboot trong U-Boot -> flash NOR/eMMC/SD theo script
```

## Bang so sanh tong quan

| Tieu chi | imx_loader / imx_usb_loader | uuu |
|---|---|---|
| Ten day du | i.MX/Vybrid recovery utility, thuong goi `imx_usb_loader` | Universal Update Utility |
| Nguon goc | Boundary Devices | NXP |
| Vai tro chinh | Nap va chay image qua SDP | Boot, flash, update board qua script |
| Muc tieu | Recovery, test bootloader, nap U-Boot tam thoi | Factory flashing, production, update firmware |
| Protocol chinh | SDP, SDPS co ban, UART | SDP, SDPS, Fastboot, FB command script |
| USB boot ROM | Co | Co |
| UART SDP | Co, qua `imx_uart` | Khong phai diem manh chinh |
| Fastboot | Khong dieu khien truc tiep, phai dung `fastboot` rieng | Tich hop trong script bang `FB:` |
| Script flash | Rat han che, config file don gian | Rat manh, file `.uuu` |
| Flash NOR/eMMC/SD | Khong truc tiep | Co, thong qua U-Boot fastboot/ucmd |
| Do phu hop production | Thap/trung binh | Cao |
| Do de tu dong hoa | Thap hon | Cao hon |
| Toc do tong the | Cham hon neu tinh ca quy trinh | Thuong nhanh hon |
| Do pho bien hien nay | Cu hon | Moi hon, duoc NXP khuyen dung hon |

## 1. Muc dich cua tung tool

### imx_loader

`imx_loader` trong thu muc nay tao ra 2 binary:

- `imx_usb`: nap image qua USB SDP.
- `imx_uart`: nap image qua UART SDP.

Muc dich chinh cua no la dua mot file bootable, vi du `u-boot.imx`, vao RAM cua chip i.MX khi board dang o Serial Downloader Mode. Sau khi nap xong, ROM code se nhay vao image do.

No phu hop khi:

- Board chua co bootloader trong flash.
- Can recover board.
- Can test nhanh U-Boot build moi.
- Can dua U-Boot vao RAM roi thao tac bang console/fastboot rieng.

Vi du:

```powershell
.\imx_usb.exe -c . .\u-boot.imx
```

### uuu

`uuu` la tool tong quat hon. No van co buoc dau giong `imx_loader`: dung SDP de nap U-Boot/SPL vao RAM. Nhung sau khi U-Boot chay va vao fastboot, `uuu` tiep tuc gui command fastboot, download file, erase flash, write flash, flash image `.wic`, va ket thuc bang script.

No phu hop khi:

- Can flash tron goi cho board.
- Can nap U-Boot, kernel, DTB, rootfs.
- Can flash NOR, SD card, eMMC.
- Can chay lap lai cho san xuat.
- Can mot file script duy nhat de van hanh.

Vi du:

```powershell
uuu.exe flash-qspi.uuu
```

## 2. Khac nhau ve flow boot

### Flow cua imx_loader

```text
1. Dua board vao USB Serial Downloader Mode.
2. PC phat hien USB VID/PID cua ROM code.
3. imx_usb doc imx_usb.conf.
4. imx_usb map VID/PID sang file config chip, vi du mx6ull_usb_work.conf.
5. imx_usb tao command SDP.
6. imx_usb gui command WRITE_FILE qua USB HID/BULK.
7. imx_usb gui data cua u-boot.imx vao RAM.
8. imx_usb gui command JUMP_ADDRESS.
9. ROM nhay vao U-Boot trong RAM.
10. Tool ket thuc.
```

Sau buoc 10, neu muon flash thi can tool khac, thuong la:

```powershell
fastboot devices
fastboot flash ...
```

### Flow cua uuu

```text
1. Dua board vao USB Serial Downloader Mode.
2. UUU phat hien ROM SDP device.
3. UUU chay dong SDP trong script.
4. UUU nap U-Boot/SPL vao RAM.
5. U-Boot chay va vao fastboot mode.
6. UUU phat hien fastboot device.
7. UUU chay cac dong FB trong script.
8. UUU gui U-Boot command bang ucmd.
9. UUU download file vao RAM buffer.
10. U-Boot ghi data tu RAM xuong NOR/eMMC/SD.
11. UUU ket thuc bang FB: done.
```

Vi du script:

```text
uuu_version 1.2.39

SDP: boot -f u-boot-imx6ull14x14evk_sd.imx

FB[-t 15000]: ucmd sf probe
FB[-t 15000]: ucmd sf erase 0x0 0x100000
FB[-t 15000]: ucmd setenv fastboot_buffer ${loadaddr}
FB[-t 15000]: download -f u-boot-imx6ull14x14evk_qspi1.imx
FB[-t 15000]: ucmd sf write ${loadaddr} 0x0 ${fastboot_bytes}

FB: done
```

## 3. Khac nhau ve protocol

### SDP

SDP la Serial Download Protocol co san trong ROM code cua i.MX. Khi board chua co bootloader hoac dang o recovery mode, PC co the dung SDP de nap mot boot image vao RAM.

Ca `imx_loader` va `uuu` deu dung SDP cho buoc dau.

Voi i.MX6ULL, buoc nay thuong la:

```text
Nap u-boot.imx vao RAM -> jump vao U-Boot
```

### Fastboot

Fastboot khong nam trong ROM code. No phai duoc U-Boot ho tro. Nghia la muon dung fastboot thi truoc do phai nap/chay U-Boot.

`imx_loader` khong tu dieu khien fastboot. Neu U-Boot vao fastboot, minh phai chay tool `fastboot` rieng.

`uuu` dieu khien fastboot truc tiep trong file `.uuu` bang prefix `FB:`.

Vi du:

```text
FB: download -f file.bin
FB: ucmd sf write 0x84000000 0xA11174 ${fastboot_bytes}
```

## 4. Khac nhau ve config

### Config cua imx_loader

`imx_loader` dung cac file `.conf`.

File quan trong:

```text
imx_usb.conf
mx6ull_usb_work.conf
mx6_usb_work.conf
```

Voi i.MX6ULL:

```text
0x15a2:0x0080, mx6ull_usb_work.conf
```

Dong nay nghia la neu PC thay USB ROM device co VID/PID `15a2:0080`, tool se dung config `mx6ull_usb_work.conf`.

Trong `mx6ull_usb_work.conf`:

```text
mx6ull
hid,1024,0x910000,0x80000000,2G,0x00900000,0x20000
```

Y nghia:

- `mx6ull`: ten target.
- `hid`: dung USB HID transport.
- `1024`: max transfer size.
- `0x910000`: dia chi DCD.
- `0x80000000,2G`: vung DDR.
- `0x00900000,0x20000`: vung OCRAM.

### Config cua uuu

`uuu` dung script `.uuu`.

Script vua la config, vua la quy trinh flash.

Vi du:

```text
SDP: boot -f u-boot-imx6ull14x14evk_sd.imx
FB: ucmd sf probe
FB: download -f zImage
FB: ucmd sf write 0x81000000 0x100000 ${fastboot_bytes}
```

Khac voi `imx_loader`, file `.uuu` co the mo ta day du:

- Nap bootloader nao.
- Erase flash o offset nao.
- Download file nao.
- Ghi vao NOR/eMMC/SD o dau.
- Timeout tung lenh.
- Ket thuc flow.

## 5. Khac nhau ve kha nang flash

### imx_loader

Ban chat `imx_loader` khong phai tool flash storage. No la tool nap code vao RAM.

No co the:

- Nap U-Boot vao RAM.
- Nap mot binary vao dia chi RAM cu the.
- Chay DCD.
- Jump vao image.
- Doc/ghi register nho qua SDP.

No khong tien de:

- Flash rootfs vao eMMC.
- Flash `.wic` vao SD card.
- Chia partition.
- Erase/write NOR theo nhieu offset.
- Quan ly nhieu file image trong mot script.

Muon flash sau khi dung `imx_loader`, can U-Boot command hoac fastboot rieng.

### uuu

`uuu` duoc thiet ke de flash.

No co the:

- Boot U-Boot qua SDP.
- Gui command U-Boot qua fastboot `ucmd`.
- Download file tu PC vao RAM.
- Flash NOR bang `sf erase`, `sf write`.
- Flash SD/eMMC bang fastboot.
- Flash `.wic` bang `flash -raw2sparse`.
- Script hoa tat ca trong mot file.

Vi du flash NOR:

```text
FB[-t 15000]: ucmd sf erase 0x100000 0x700000
FB[-t 15000]: ucmd setenv fastboot_buffer 0x81000000
FB[-t 15000]: download -f zImage-imx6ul7d.bin
FB[-t 15000]: ucmd sf write 0x81000000 0x100000 ${fastboot_bytes}
```

Vi du flash SD/eMMC:

```text
FB[-t 60000]: ucmd setenv fastboot_dev mmc
FB[-t 60000]: ucmd mmc dev ${sd_dev}
FB[-t 60000]: flash -raw2sparse all imx-image-base-imx6ul7d.wic
```

## 6. Khac nhau ve toc do

Can tach toc do thanh 2 phan.

### Toc do nap bootloader vao RAM

Buoc nay ca hai tool deu di qua SDP. Chenh lech thuong khong phai diem lon nhat.

Voi file `u-boot.imx` kich thuoc nho, thoi gian thuc te bi anh huong boi:

- USB mode cua ROM: HID/BULK.
- Max transfer size.
- Driver tren PC.
- Chat luong cap USB.
- Board co vao dung Serial Downloader Mode khong.

### Toc do flash storage

Day la phan `uuu` vuot hon ro rang trong workflow.

`imx_loader` chi nap U-Boot xong roi dung. Sau do minh phai chay `fastboot`, go lenh rieng, hoac thao tac bang serial console.

`uuu` chay lien mach:

```text
SDP boot -> wait fastboot -> erase -> download -> write -> flash rootfs -> done
```

Ngoai ra `uuu` co `-raw2sparse`, giup file `.wic` khong can gui toan bo block rong qua USB. Voi rootfs/SD image lon, viec nay co the tiet kiem thoi gian dang ke.

Ket luan ve toc do:

```text
Chi nap U-Boot vao RAM: imx_loader va uuu co the gan tuong duong.
Flash tron goi NOR/eMMC/SD: uuu nhanh hon ve tong thoi gian va it thao tac hon.
```

## 7. Khac nhau ve do on dinh va loi thuong gap

### imx_loader

Loi thuong gap:

- Khong tim thay USB device do board chua vao recovery mode.
- Sai VID/PID trong `imx_usb.conf`.
- Sai config target.
- Thieu `libusb-1.0.dll` tren Windows.
- Driver chua dung WinUSB/libusb.
- File `u-boot.imx` sai board hoac sai DDR init.
- Tool nap xong nhung U-Boot khong chay do DCD/image sai.

Vi du debug:

```powershell
.\imx_usb.exe -d -c . .\u-boot.imx
```

### uuu

Loi thuong gap:

- Script `.uuu` sai ten file.
- U-Boot khong vao fastboot.
- U-Boot khong enable fastboot/ucmd.
- Sai `fastboot_buffer`.
- Buffer RAM bi de len kernel/rootfs.
- Sai offset NOR.
- Sai MMC device number.
- Timeout qua ngan.
- Flash image qua lon so voi partition/storage.

Vi du nen tang timeout voi lenh lau:

```text
FB[-t 60000]: flash -raw2sparse all image.wic
```

## 8. Khac nhau ve yeu cau U-Boot

### imx_loader

Chi can `u-boot.imx` dung format boot ROM co the chay.

De nap va jump thanh cong, U-Boot can:

- Dung SoC.
- Dung board.
- Dung DDR init/DCD.
- Dia chi load/jump dung.

Khong bat buoc U-Boot phai co fastboot neu chi test boot.

### uuu

Ngoai yeu cau U-Boot boot duoc, neu muon flash bang `FB:` thi U-Boot can ho tro:

- Fastboot USB gadget.
- Command `fastboot`.
- Lenh `ucmd` tu fastboot.
- Driver flash tuong ung: `sf` cho NOR, `mmc` cho SD/eMMC.
- Bien moi truong phu hop: `fastboot_buffer`, `loadaddr`, `mmcdev`, `fastboot_dev`.

Neu U-Boot boot duoc nhung khong co fastboot, `uuu` se dung o buoc chuyen sang `FB:`.

## 9. Khac nhau trong bai toan i.MX6ULL

### Dung imx_loader voi i.MX6ULL

Flow phu hop:

```powershell
cd C:\ha\tailieuhoctap\thuctap\DOC_IMX6UL\My_doc\boot_script\imx_loader\imx_usb_loader
.\imx_usb.exe -c . .\u-boot-imx6ull14x14evk_sd.imx
```

Sau do:

```powershell
fastboot devices
```

Neu thay device, minh tiep tuc flash bang fastboot rieng.

### Dung uuu voi i.MX6ULL

Flow phu hop:

```powershell
uuu.exe flash-qspi.uuu
```

Trong script:

```text
SDP: boot -f u-boot-imx6ull14x14evk_sd.imx
FB: ucmd sf probe
FB: download -f u-boot-imx6ull14x14evk_qspi1.imx
FB: ucmd sf write ${loadaddr} 0x0 ${fastboot_bytes}
FB: done
```

Neu flash rootfs:

```text
FB[-t 60000]: flash -raw2sparse all imx-image-base-imx6ul7d.wic
```

## 10. Khi nao chon tool nao

### Chon imx_loader khi

- Dang debug bootloader.
- Chi can dua U-Boot vao RAM.
- Can test image `.imx` nhanh.
- Can dung UART SDP.
- Muon doc code SDP don gian de hoc co che boot ROM.
- Board cu dung flow cu co san.

### Chon uuu khi

- Can flash san xuat.
- Can flash nhieu file.
- Can nap NOR + SD/eMMC trong mot lan.
- Can script de nguoi khac bam mot lenh la chay.
- Can tang toc ghi image lon bang sparse.
- Can flow chuan NXP hon.
- Can thay the MFGTool cu.

## 11. Diem manh va diem yeu

### imx_loader

Diem manh:

- Source nho, de doc.
- Hieu ro SDP.
- Co USB va UART.
- Tot cho recovery/toi thieu.
- Config VID/PID don gian.

Diem yeu:

- Khong phai factory flashing tool hoan chinh.
- Khong co script flash manh.
- Phai ket hop fastboot rieng neu muon flash.
- Windows build can libusb va driver.
- Ho tro chip/flow moi kem hon `uuu`.

### uuu

Diem manh:

- Tool phu hop production.
- Script `.uuu` ro rang.
- Tich hop SDP + fastboot.
- Flash NOR/eMMC/SD linh hoat.
- Co timeout tung lenh.
- Ho tro `download`, `ucmd`, `flash`, `-raw2sparse`.
- Mot command co the flash tron board.

Diem yeu:

- Phu thuoc U-Boot co fastboot va command can thiet.
- Script sai offset co the ghi sai flash.
- Can hieu memory map de dat `fastboot_buffer`.
- Khi loi fastboot/USB co the can doc log ky.
- Khong don gian bang `imx_usb u-boot.imx` neu chi muon boot tam.

## 12. Bang quyet dinh nhanh

| Nhu cau | Nen dung |
|---|---|
| Nap U-Boot vao RAM de test | imx_loader hoac uuu |
| Recovery board chua co bootloader | imx_loader hoac uuu |
| Flash NOR nhieu offset | uuu |
| Flash rootfs `.wic` vao SD/eMMC | uuu |
| Lam tool san xuat mot lenh | uuu |
| Hoc code SDP | imx_loader |
| Dung UART SDP | imx_loader |
| Thay the MFGTool | uuu |
| Can workflow nhanh, lap lai | uuu |

## 13. Khuyen nghi cho project nay

Voi tai lieu hien tai trong `DOC_IMX6UL`, nen chia vai tro nhu sau:

```text
imx_loader:
Dung de hieu co che SDP va test nap u-boot.imx vao RAM.

uuu:
Dung lam flow flash chinh cho NOR, SD card, eMMC, firmware, kernel, dtb, rootfs.
```

Neu dang lam i.MX6ULL va can flash thuc te, nen uu tien `uuu`.

Neu dang debug vi sao board khong boot, nen dung `imx_loader` de co flow toi thieu:

```powershell
.\imx_usb.exe -d -c . .\u-boot.imx
```

Sau khi U-Boot da chay on dinh va fastboot hoat dong, chuyen sang script `uuu` de flash san xuat.

## 14. Vi du command

### imx_loader

```powershell
cd C:\ha\tailieuhoctap\thuctap\DOC_IMX6UL\My_doc\boot_script\imx_loader\imx_usb_loader
.\imx_usb.exe -c . .\u-boot-imx6ull14x14evk_sd.imx
```

Debug:

```powershell
.\imx_usb.exe -d -c . .\u-boot-imx6ull14x14evk_sd.imx
```

Kiem tra fastboot sau khi U-Boot chay:

```powershell
fastboot devices
```

### uuu

```powershell
uuu.exe flash-qspi.uuu
```

Nap rieng U-Boot vao RAM:

```powershell
uuu.exe u-boot-imx6ull14x14evk_sd.imx
```

## 15. Tom tat cuoi

`imx_loader` la tool nap bootloader qua SDP. No tot de recovery va debug bootloader.

`uuu` la tool flash/update hoan chinh. No dung SDP de boot U-Boot, sau do dung fastboot de flash storage theo script.

Trong thuc te:

```text
Debug bootloader: imx_loader
Factory flash: uuu
```
