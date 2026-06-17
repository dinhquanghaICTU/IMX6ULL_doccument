# Quá trình Boot của i.MX6ULL — từ lúc cắm điện tới khi chạy `init` trên user space

> Tài liệu này mô tả **toàn bộ chuỗi boot** của board OKMX6ULL-S (i.MX6ULL) với cấu hình
> phần cứng đã chọn: **eMMC PS8225 (4GB/8GB, JEDEC eMMC 5.0)** làm thiết bị boot và
> **DDR3L Micron MT41K256M16 (4Gb = 512MB, 1.35V)** làm RAM chính.
>
> Nguồn tham khảo trong repo:
> - `FORLINX_OKM6ULL-S/IMX6ULLRM/09_Chapter_8_System_Boot.md` (Boot ROM của i.MX6ULL)
> - `FORLINX_OKM6ULL-S/IMX6ULLRM/03_Chapter_2_Memory_Maps.md` (memory map)
> - `FORLINX_OKM6ULL-S/emmc_4gb_8gb_ps8225_v50_wt/` (datasheet eMMC)
> - `FORLINX_OKM6ULL-S/4Gb_automotive_DDR3L(MT41K256M16TW)/` (datasheet DDR3L)
> - `Phu_doc/docs/lessons/15_uboot/uboot.md` (khái niệm U-Boot, tham chiếu chéo — bài này dạy trên AM335x/BBB, nguyên lý tương tự)

---

## 0. Bức tranh tổng thể — 5 chặng

Từ khi cấp điện đến khi có shell trên user space, i.MX6ULL đi qua 5 chặng. Điểm mấu chốt
cần nhớ: **mỗi chặng có nhiệm vụ duy nhất là khởi tạo đủ phần cứng để nạp và trao quyền
cho chặng kế tiếp** (chain-loading).

```
   CẮM ĐIỆN (Power ON)
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│ CHẶNG 1 — Boot ROM (mask ROM)                              │
│ • Code NXP nung cứng trong chip, KHÔNG sửa được            │
│ • Chạy trong: Boot ROM + OCRAM (128KB on-chip SRAM)        │
│ • Đọc BOOT_MODE pin + eFUSE → chọn boot từ eMMC (uSDHC)    │
│ • Nạp 4KB đầu của image → đọc IVT/DCD → cấu hình DDR3L     │
│ • Copy bootloader vào DDR → nhảy vào                       │
└───────────────────────────┬───────────────────────────────┘
                            │  (DDR3L MT41K256M16 đã sống)
        ┌───────────────────┴───────────────────┐
        │  Có 2 kiểu thiết kế bootloader:        │
        ▼                                        ▼
┌─────────────────────────┐         ┌─────────────────────────────┐
│ CHẶNG 2 — U-Boot SPL    │   HOẶC  │ (Kiểu cổ điển: 1 tầng)      │
│ • Chạy trong OCRAM      │         │ ROM dùng DCD cấu hình DDR,  │
│ • Tự khởi tạo DDR3L     │         │ rồi nạp thẳng U-Boot full   │
│ • Nạp u-boot.img vào DDR│         │ vào DDR (không cần SPL)     │
└────────────┬────────────┘         └──────────────┬──────────────┘
             └─────────────────┬────────────────────┘
                               ▼
┌───────────────────────────────────────────────────────────┐
│ CHẶNG 3 — U-Boot proper (u-boot.img)                      │
│ • Chạy trong DDR3L                                         │
│ • Relocate, khởi tạo driver (eMMC, UART, ENET...)         │
│ • Chạy `bootcmd`: nạp zImage + DTB từ eMMC vào DDR        │
│ • Set r0/r1/r2 theo ARM boot protocol → nhảy vào kernel   │
└───────────────────────────┬───────────────────────────────┘
                            ▼
┌───────────────────────────────────────────────────────────┐
│ CHẶNG 4 — Linux Kernel                                     │
│ • Giải nén, start_kernel(), parse DTB, probe driver       │
│ • Mount root filesystem từ eMMC (mmcblk)                  │
│ • Gọi /sbin/init                                          │
└───────────────────────────┬───────────────────────────────┘
                            ▼
┌───────────────────────────────────────────────────────────┐
│ CHẶNG 5 — User space (PID 1: init / systemd / BusyBox)    │
│ • Khởi tạo service, mount fs còn lại, lên màn login/shell │
└───────────────────────────────────────────────────────────┘
```

---

## 1. Phần cứng đã chọn — vì sao boot quan tâm tới nó

### 1.1 SoC: i.MX6ULL
- Lõi đơn **ARM Cortex-A7**.
- **OCRAM**: 128 KB SRAM on-chip — nơi Boot ROM và SPL chạy *khi DDR chưa sống*.
- **MMDC**: bộ điều khiển DDR **x16** (khớp đúng với DDR3L x16 đã chọn).
- **uSDHC**: bộ điều khiển SD/MMC — eMMC nối vào đây để boot.

### 1.2 RAM: DDR3L MT41K256M16 (4Gb)
| Thông số | Giá trị | Ý nghĩa với boot |
|---|---|---|
| Tổ chức | 256 Meg × 16 (32M×16×8 bank) | 1 chip = **512 MB**, bus dữ liệu 16-bit khớp MMDC x16 |
| Điện áp | **1.35V** (DDR3L) | DCD/SPL phải set đúng I/O voltage, nếu sai → memory error ngẫu nhiên |
| Base address | **0x8000_0000** | Toàn bộ ảnh kernel/U-Boot sẽ nằm trên vùng này |

> DDR **không tự chạy** sau reset. Phải nạp một loạt giá trị timing (tRCD, tRP, tRFC, ZQ
> calibration, write-leveling...) tính từ datasheet vào thanh ghi MMDC. Việc này do **DCD**
> (nếu boot 1 tầng) hoặc **U-Boot SPL** (nếu boot 2 tầng) đảm nhận — xem Chặng 1 & 2.

### 1.3 Thiết bị boot: eMMC PS8225 (4GB/8GB)
| Thông số | Giá trị | Ý nghĩa với boot |
|---|---|---|
| Chuẩn | JEDEC **eMMC 5.0** (JESD84-B50), 153-ball FBGA | Hỗ trợ HS200/HS400 ở chế độ vận hành |
| Boot partition | Có (Boot Area 1/2 + User Area) | ROM đọc `Ext_CSD[179]` để chọn partition boot |
| Giao tiếp | qua **uSDHC** | Cùng đường với SD card |

> **Lưu ý rất quan trọng:** Boot ROM của i.MX6ULL chỉ "biết" giao tiếp eMMC tới mức
> **eMMC v4.4 trở xuống** (xem `Table 8-17`). Dù chip PS8225 là eMMC 5.0, **ở giai đoạn
> Boot ROM** nó chạy ở chế độ tương thích ngược: nhận diện ở **347.22 KHz**, sau đó nâng
> lên **20 MHz (normal)** hoặc **40 MHz (high-speed)**, hoặc DDR mode nếu `BOOT_CFG2[7:5]`
> chọn. Tốc độ cao HS200/HS400 chỉ được dùng **sau khi Linux** nạp driver uSDHC đầy đủ.

---

## 2. Chặng 1 — Boot ROM (chi tiết)

Đây là chặng đặc thù i.MX6ULL nhất, được mô tả trong Chương 8 của Reference Manual.

### 2.1 Power-On Reset (POR) và lấy mẫu chân BOOT_MODE
1. Cấp điện → mạch reset giữ Cortex-A7 ở trạng thái reset cho tới khi nguồn ổn định.
2. Trên cạnh lên của `POR_B`, ROM **lấy mẫu (sample)** 2 chân `BOOT_MODE[1:0]` và nạp vào
   thanh ghi nội bộ. Sau thời điểm này, thay đổi điện áp trên chân không còn tác dụng.
3. CPU bắt đầu thực thi từ **on-chip Boot ROM** (địa chỉ thấp 0x0000_0000).

`BOOT_MODE[1:0]` quyết định "kiểu" boot (`Table 8-1`):

| BOOT_MODE[1:0] | Kiểu | Dùng khi |
|---|---|---|
| `00` | **Boot From Fuses** | Sản phẩm thực địa: bỏ qua GPIO override, chỉ theo eFUSE |
| `01` | **Serial Downloader** | Nạp image qua USB-OTG/UART (dùng `uuu`/`imx_usb` để cứu/nạp lần đầu) |
| `10` | **Internal Boot** | Phổ biến nhất khi phát triển: theo eFUSE *hoặc* cho phép GPIO override |
| `11` | Reserved | — |

### 2.2 Trình tự cấp cao của ROM (`Figure 8-1`)
```
Reset
  │
  ▼ Check CPU ID (MPIDR của Cortex-A7)
  ▼ Check Reset Type → có phải wake-up từ low-power không?
  │      └─ nếu wake-up & PERSISTENT_ENTRY0 hợp lệ → nhảy thẳng, BỎ QUA nạp image
  ▼ Check Boot Mode (đọc fuse và/hoặc GPIO)
  │      ├─ Serial Downloader → chờ USB/UART
  │      └─ Internal / Boot-From-Fuses → boot từ thiết bị (eMMC)
  ▼ Download initial boot image (4KB đầu)
  ▼ Authenticate Image (HAB) — ở chế độ "open" thì lỗi bị bỏ qua
  ▼ Execute Image (nhảy vào entry point)
```

### 2.3 Chọn thiết bị boot bằng eFUSE / BOOT_CFG
ROM đọc các eFUSE (hoặc GPIO override nếu Internal Boot) để biết boot từ đâu. Các fuse
liên quan tới eMMC:

| eFUSE | Vai trò |
|---|---|
| `BT_FUSE_SEL` | =1: boot device đã được nạp → boot bình thường. =0: nhảy thẳng Serial Downloader |
| `BOOT_CFG1[7:4]` | Chọn **loại thiết bị** ngoại vi (SD/MMC, NAND, EIM, QSPI...) |
| `BOOT_CFG2[2:0]` | Chọn **cổng uSDHC** nào (port number) |
| `BOOT_CFG2[7:5]` | Bus width của eMMC (1/4/8-bit, DDR) |
| `BOOT_CFG1[4]` | Fast Boot (special boot mode của eMMC4.3/4.4) |
| `BOOT_CFG2[1]` | BOOT ACK enable |

> Trên board phát triển, người ta thường để `BOOT_MODE=10` (Internal Boot) và dùng GPIO
> override để chọn nhanh "boot eMMC" hay "boot SD". Khi ra sản xuất, **đốt eFUSE** cho
> `BOOT_CFG` trỏ cố định về eMMC và set `BT_FUSE_SEL=1`.

### 2.4 Khởi tạo eMMC và đọc 4KB đầu tiên
ROM cấu hình IOMUX cho các chân uSDHC (`Table 8-18`) rồi khởi tạo eMMC (`Table 8-17`):
1. eSDHC software reset, đặt tần số nhận diện ~**400 KHz** (chính xác 347.22 KHz).
2. Gửi 80 xung clock (INITA), `CMD0` reset card, voltage validation, đọc capacity.
3. Đọc `Ext_CSD[179]` (`BOOT_PARTITION_ENABLE`) để chọn **boot partition**. Nếu không có
   → đọc từ **user partition**.
4. Nâng tần số lên 20/40 MHz và **copy 4 KB đầu** của image vào OCRAM.

### 2.5 Bố cục "initial load region" và parse IVT/DCD/Boot Data
Với SD/MMC/eMMC, ROM tìm **IVT ở offset 1 KB (0x400)** so với đầu image, và vùng nạp ban
đầu là **4 KB** (`Table 8-25`). 4KB này **bắt buộc chứa IVT + DCD + Boot Data**.

```
Image trên eMMC (boot partition / user partition)
offset 0x000  ┌───────────────────────────┐
              │ (trống / reserved)        │
offset 0x400  ├───────────────────────────┤  ← IVT bắt đầu ở đây (cố định cho SD/MMC)
              │ IVT  (32 byte, tag=0xD1)  │──┐
              │   • entry  (điểm vào)     │  │
              │   • dcd    → trỏ tới DCD  │  │
              │   • boot_data → trỏ Boot  │  │
              │   • self, csf             │  │
              ├───────────────────────────┤  │
              │ Boot Data (tag/3 word)    │◄─┘
              │   • start  = đích trong DDR (vd 0x87800000)
              │   • length = kích thước image
              │   • plugin                │
              ├───────────────────────────┤
              │ DCD  (tag=0xD2, ≤1768 B)  │  ← danh sách lệnh "write register"
              │   ghi timing DDR3L vào    │     cấu hình MMDC cho MT41K256M16
              │   các thanh ghi MMDC...   │
              └───────────────────────────┘
              │ ... phần còn lại của image (U-Boot SPL hoặc U-Boot full) ...
```

**IVT header** (`Figure 8-22`): byte `Tag=0xD1`, `Length=32`, `Version=0x40/0x41`.
**DCD header** (`Figure 8-24`): byte `Tag=0xD2`. Lệnh "Write Data" dùng `Tag=0xCC` để ghi
từng cặp (địa chỉ thanh ghi, giá trị) — chính là nơi **DDR3L được lập trình**.

### 2.6 DCD cấu hình DDR3L MT41K256M16 (nếu boot 1 tầng)
Sau khi parse IVT, ROM duyệt DCD và thực thi từng lệnh ghi thanh ghi MMDC: cấu hình
addressing (8 bank, 256M×16), timing, ZQ calibration, đặt I/O cho **1.35V**, DLL... Khi DCD
chạy xong, **DDR3L đã sẵn sàng**.

> DCD chỉ được phép ghi vào một số vùng "thiết yếu cho boot" (MMDC, IOMUX, CCM...). Giới
> hạn DCD là **1768 byte** — đủ cho toàn bộ chuỗi khởi tạo DDR.

### 2.7 Nạp toàn bộ image vào DDR và trao quyền
- ROM đọc `start` và `length` từ **Boot Data** → copy toàn bộ image (tối đa **32 MB** với
  SD/MMC, do giới hạn ADMA buffer descriptor của ROM) từ eMMC vào DDR tại địa chỉ `start`.
- HAB xác thực image (ở cấu hình "open" mặc định, lỗi xác thực bị bỏ qua, image vẫn chạy).
- ROM **nhảy vào `entry`** trong IVT → quyền điều khiển chuyển cho bootloader.

### 2.8 Memory map nội bộ liên quan (OCRAM)
Trong khi DDR chưa sống, mọi thứ nằm trong **OCRAM 128KB @ 0x0090_0000**
(`Chapter 2 Memory Maps` + `Figure 8-3`):

```
0x0090_0000 ┌─────────────────────────────┐
            │ ROM dùng riêng (~28 KB)      │
0x0090_7000 ├─────────────────────────────┤
            │ OCRAM Free Area (68 KB)     │ ← vùng ROM/SPL nạp & chạy code
0x0091_8000 ├─────────────────────────────┤
            │ MMU Table (20 KB)           │
0x0091_D000 ├─────────────────────────────┤
            │ Stack (~8 KB)               │
0x0091_FFFF └─────────────────────────────┘
DDR: 0x8000_0000 trở lên (sau khi DCD/SPL khởi tạo xong)
```

---

## 3. Hai kiểu thiết kế bootloader — chọn cái nào?

Đây là điểm hay gây nhầm. Với i.MX6ULL có **2 cách hợp lệ**:

| | **Kiểu A — 1 tầng (DCD)** | **Kiểu B — 2 tầng (SPL)** |
|---|---|---|
| Ai khởi tạo DDR? | **DCD** (ROM thực thi) | **U-Boot SPL** (code C) |
| ROM nạp gì? | Toàn bộ `u-boot.imx` thẳng vào DDR | Chỉ `SPL` (nhỏ) vào OCRAM |
| Ưu | Đơn giản, ít file | DDR init linh hoạt (code C dễ debug, hỗ trợ nhiều loại DDR) |
| Nhược | DDR init "cứng" trong bảng DCD | Thêm một tầng |
| File output | `u-boot.imx` | `SPL` + `u-boot.img` (hoặc gộp `flash.bin`/`imx-boot`) |

BSP hiện đại của NXP/Forlinx (U-Boot mới) **dùng Kiểu B (SPL)** vì dễ bảo trì. BSP cũ
(U-Boot 2016 trở về trước, kiểu `u-boot.imx`) dùng Kiểu A. Cả hai đều kết thúc ở cùng một
chỗ: **U-Boot proper chạy trong DDR**.

---

## 4. Chặng 2 — U-Boot SPL (chỉ khi dùng Kiểu B)

SPL (Secondary Program Loader) là U-Boot "thu nhỏ", build với cờ `CONFIG_SPL_BUILD`, đủ
nhỏ để chạy trong **OCRAM Free Area (68KB)**.

Luồng thực thi (tương tự mô tả trong `Phu_doc/.../15_uboot/uboot.md`, nhưng cho ARMv7
i.MX6ULL):
```
arch/arm/cpu/armv7/start.S        ← entry point ROM nhảy vào
        │
        ▼ board_init_f()  [bản SPL]
        │      • khởi tạo clock cơ bản, UART debug
        │      • gọi spl_dram_init() → ghi thanh ghi MMDC cho DDR3L MT41K256M16
        │        (thay cho DCD; timing nằm trong board/<vendor>/<board>/ hoặc DDR script)
        ▼ board_init_r()  [bản SPL]
        │      • khởi tạo uSDHC → đọc u-boot.img từ eMMC
        │      • nạp u-boot.img vào DDR (0x8780_0000 chẳng hạn)
        ▼ jump_to_image_no_args()
               • nhảy vào U-Boot proper trong DDR
```

> Khác biệt cốt lõi giữa hai tầng: SPL khởi tạo **DDR** rồi nạp tầng sau; U-Boot proper
> khởi tạo **ngoại vi đầy đủ** rồi nạp **kernel**.

---

## 5. Chặng 3 — U-Boot proper (u-boot.img)

Chạy hoàn toàn trong DDR3L với đầy đủ tài nguyên.

```
start.S
   ▼ board_init_f()   • khởi tạo malloc, stdio, ngoại vi cơ bản
   ▼ relocate_code()  • U-Boot tự copy mình về CUỐI DDR, nhường vùng thấp cho kernel
   ▼ board_init_r()   • Driver Model: probe uSDHC(eMMC), UART, ENET, GPIO, I2C, PMIC...
   │                  • đọc environment (lưu trong eMMC), khởi tạo network
   ▼ main_loop()      • đếm ngược bootdelay → chạy `bootcmd`, hoặc vào CLI nếu nhấn phím
```

### 5.1 `bootcmd` làm gì (boot Linux từ eMMC)
Một `bootcmd` điển hình trên i.MX6ULL/eMMC:
```bash
# Chọn thiết bị eMMC (vd mmc dev 1) và partition rootfs
mmc dev 1
# Nạp kernel nén zImage vào DDR
load mmc 1:1 ${loadaddr}  zImage
# Nạp device tree blob vào DDR
load mmc 1:1 ${fdt_addr}  imx6ull-okmx6ull.dtb
# Truyền tham số cho kernel: console, rootfs nằm ở partition eMMC
setenv bootargs console=ttymxc0,115200 root=/dev/mmcblk1p2 rootwait rw
# Khởi động kernel ARM (zImage)
bootz ${loadaddr} - ${fdt_addr}
```
- `root=/dev/mmcblk1p2` — rootfs nằm trên **partition 2 của eMMC** (`mmcblk1` = eMMC,
  `mmcblk0` thường là SD).
- `console=ttymxc0` — UART1 của i.MX6ULL làm console.

### 5.2 ARM boot protocol — cách U-Boot trao quyền cho kernel
Trước khi nhảy, U-Boot set thanh ghi theo quy ước ARM rồi gọi entry của kernel:
```c
r0 = 0                  /* bắt buộc = 0 */
r1 = machine type ID    /* với DT boot, giá trị này gần như bị bỏ qua */
r2 = địa chỉ DTB        /* = ${fdt_addr}, kernel đọc r2 để tìm device tree */
/* nhảy vào điểm vào kernel (head.S) */
```
`bootz` giải nén/đặt `zImage`, kiểm tra header, thiết lập r0/r1/r2 rồi jump.

---

## 6. Chặng 4 — Linux Kernel

1. **`arch/arm/boot/compressed/head.S`**: bộ giải nén tự bung `zImage` → `Image` thật, rồi
   nhảy vào kernel.
2. **`head.S` của kernel**: đọc `r2` để lấy con trỏ **DTB**, thiết lập MMU/trang ban đầu.
3. **`start_kernel()`**:
   - Parse **device tree** → biết có DDR ở `0x80000000` kích thước 512MB, có uSDHC, UART,
     ENET, I2C... (mọi thứ mô tả trong `imx6ull-okmx6ull.dtb`).
   - Khởi tạo memory management, scheduler, IRQ (GIC), timer.
   - **Probe driver** theo `compatible` trong DTB: driver uSDHC nhận eMMC và tạo
     `/dev/mmcblk1`, driver UART tạo `ttymxc0`...
4. **Mount root filesystem**: theo `root=/dev/mmcblk1p2` từ `bootargs`, kernel mount rootfs
   (ext4) nằm trên eMMC. (Nếu dùng initramfs thì mount tạm trước, rồi `switch_root`.)
5. Kernel gọi chương trình **`init` đầu tiên** (`/sbin/init`) với **PID 1** → chuyển sang
   user space.

---

## 7. Chặng 5 — User space (`init`, PID 1)

`init` là tiến trình đầu tiên ở user space, tổ tiên của mọi tiến trình khác. Tùy rootfs
(Yocto/Buildroot), `init` có thể là:
- **systemd** — phổ biến với Yocto: đọc các unit, khởi động service song song.
- **SysVinit / BusyBox init** — nhẹ, đọc `/etc/inittab`, chạy script `/etc/init.d/rcS`.

Việc `init` làm:
1. Mount nốt các filesystem ảo: `/proc`, `/sys`, `/dev` (devtmpfs/udev), `/tmp`...
2. Chạy các service khởi động: network, ssh, ứng dụng riêng của sản phẩm.
3. Mở **getty** trên `ttymxc0` → hiện **login prompt / shell**.

> Tới đây hệ thống đã "boot xong": từ lúc cắm điện, qua Boot ROM (đọc eMMC, dựng DDR3L),
> bootloader (SPL → U-Boot), kernel (mount rootfs eMMC), tới `init` đang chạy ở user space.

---

## 8. Bảng tóm tắt "ai chạy ở đâu, làm gì"

| Chặng | Code chạy trong | Khởi tạo cái gì | Nạp & trao quyền cho |
|---|---|---|---|
| Boot ROM | Boot ROM + OCRAM | uSDHC, đọc eFUSE, (DCD→DDR nếu 1 tầng) | SPL hoặc U-Boot |
| U-Boot SPL | OCRAM (68KB) | **DDR3L (MMDC)**, uSDHC | u-boot.img trong DDR |
| U-Boot proper | DDR3L | Toàn bộ ngoại vi, network, env | Kernel + DTB trong DDR |
| Linux kernel | DDR3L | MMU, driver, mount rootfs eMMC | `/sbin/init` (PID 1) |
| User space | DDR3L | service, /dev, /proc, getty | login / ứng dụng |

## 9. Sơ đồ địa chỉ tổng hợp

```
0x0000_0000  Boot ROM (mask ROM của NXP)
0x0090_0000  OCRAM 128KB  ← Boot ROM & U-Boot SPL chạy ở đây khi DDR chưa sống
0x8000_0000  DDR3L 512MB (MT41K256M16) ── vùng làm việc chính:
             ├─ U-Boot proper (sau relocate nằm ở cuối DDR)
             ├─ zImage kernel (vd ${loadaddr})
             ├─ DTB (vd ${fdt_addr})
             └─ kernel + user space sau khi boot
eMMC (qua uSDHC, /dev/mmcblk1):
             ├─ Boot partition / offset chứa: IVT + DCD + Boot Data + SPL/U-Boot
             ├─ partition 1: /boot (zImage, dtb) — tuỳ layout
             └─ partition 2: rootfs (ext4)  → root=/dev/mmcblk1p2
```

---

## 10. Những điểm dễ sai / cần nhớ riêng cho cấu hình này

1. **DDR3L 1.35V**: nếu DCD/SPL set nhầm I/O voltage (1.5V của DDR3 thường) → lỗi ngẫu
   nhiên. Phải dùng đúng tham số DDR3L cho MT41K256M16.
2. **Bus x16**: MMDC i.MX6ULL là x16, khớp đúng 1 chip MT41K256M16 x16 = 512MB. Không cần
   ghép 2 chip như cấu hình x32.
3. **eMMC ở Boot ROM chỉ chạy ≤ eMMC4.4** (≤40MHz/DDR). Tốc độ HS200/HS400 của PS8225 chỉ
   khai thác được **sau khi Linux** nạp driver — đừng kỳ vọng boot ROM đọc eMMC ở HS400.
4. **IVT cho eMMC ở offset 0x400**, vùng nạp ban đầu 4KB phải đủ chứa IVT+DCD+Boot Data.
5. **Image boot ≤ 32MB** khi nạp qua SD/MMC từ ROM (giới hạn ADMA descriptor).
6. **`BT_FUSE_SEL=0` → rơi vào Serial Downloader**: dùng `uuu`/`imx_usb_loader` qua USB-OTG
   để nạp lần đầu hoặc cứu board brick (đặt `BOOT_MODE=01`).
7. **Boot partition eMMC**: ROM đọc `Ext_CSD[179]`. Khi flash, phải ghi bootloader đúng
   partition mà fuse/Ext_CSD trỏ tới (boot area vs user area).

---

*Tài liệu tự soạn dựa trên Reference Manual i.MX6ULL (Chương 8 & 2) và datasheet eMMC/DDR3L
trong repo. Khi cần số liệu thanh ghi MMDC cụ thể, tra thêm `IMX6ULLRM/36_Chapter_35_Multi_Mode_DDR_Controller_(MMDC).md`.*
