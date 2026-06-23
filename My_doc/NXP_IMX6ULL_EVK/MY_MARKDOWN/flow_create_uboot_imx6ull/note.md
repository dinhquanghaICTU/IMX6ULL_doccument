# Phân tích IVT (Image Vector Table) – i.MX6ULL Boot Process

## 1. Thông số đầu vào

Theo **Table 8-25. Image Vector Table Offset and Initial Load Region Size**:

| Boot Media | Flash Offset | Initial Load Region Size |
|---|---|---|
| SD/MMC/eSD/eMMC/SDXC | `0x400` (1 KByte) | `0x1000` (4 KByte) |

**Nguồn tham chiếu:**
- `/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/include/imximage.h` (line 28): `imximage_init_loadsize = 0x1000` (4 KByte)


4 KiB = 4 × 1024 byte
      = 4096 byte

      4096 decimal = 0x1000
- `entry_point` (mặc định của hãng): `0x87800000`

---

## 2. Tính địa chỉ nền (`hdr_base`)

**Nguồn:** `/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imximage.c` (line 390)

```c
hdr_base = entry_point - imximage_init_loadsize + flash_offset;
hdr_base = 0x87800000 - 0x1000 + 0x400
         = 0x877FF400
```

---

## 3. Các trường trong IVT Header

### 3.1. Trường `self`

**Nguồn:** `/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imximage.c` (line 394)

```c
fhdr_v2->self = hdr_base;
             // = 0x877FF400
```

---

### 3.2. Trường `dcd_ptr`

**Nguồn:** `/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imximage.c` (line 397)

```c
fhdr_v2->dcd_ptr = hdr_base + offsetof(imx_header_v2_t, data);
```

**Tính `offsetof(data)`** — `/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/x86_64-linux/u-boot-imx-tools-native/2022.04-r0/git/include/imximage.h` (line 170):

```c
typedef struct {
    flash_header_v2_t   fhdr;       // offset 0x00, size = 0x20
    boot_data_t         boot_data;  // offset 0x20, size = 0x0C
    dcd_v2_t            data;       // offset 0x2C  <--- đây chính là DCD
} imx_header_v2_t;
```

```
offsetof(data) = sizeof(flash_header_v2_t) + sizeof(boot_data_t)
               = 0x20 + 0x0C
               = 0x2C

dcd_ptr = 0x877FF400 + 0x2C
        = 0x877FF42C
```

---

### 3.3. Trường `boot_data_ptr`

**Nguồn:** `/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imximage.c` (line 408)

```c
fhdr_v2->boot_data_ptr = hdr_base + offsetof(imx_header_v2_t, boot_data);
```

```
offsetof(boot_data) = sizeof(flash_header_v2_t) = 0x20

boot_data_ptr = 0x877FF400 + 0x20
              = 0x877FF420
```

---

## 4. Các trường trong `BootData`

### 4.1. `BootData.start`

**Nguồn:** `/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imximage.c` (line 410)

```c
hdr_v2->boot_data.start = entry_point - imximage_init_loadsize;
```

```
BootData.start = 0x87800000 - 0x1000
               = 0x877FF000
```

### 4.2. `BootData.size`

**Nguồn:** `/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imximage.c` (line 1011)

```c
*header_size_ptr = ROUND(sbuf->st_size + imximage_ivt_offset, 4096);
```

**Giải thích:**

| Thành phần | Ý nghĩa |
|---|---|
| `sbuf->st_size` | Kích thước file u-boot.bin thực tế (bytes) |
| `imximage_ivt_offset` | Offset của IVT trên flash = `0x400` |
| `+ imximage_ivt_offset` | Cộng thêm vùng trước IVT (từ sector 0 đến IVT) để tính đủ toàn bộ image |
| `ROUND(..., 4096)` | Làm tròn lên bội số của 4096 (0x1000) — align theo page size của flash |

Kết quả là `BootData.size` = tổng số byte Boot ROM cần copy từ flash lên SDRAM, bắt đầu từ `BootData.start = 0x877FF000`.

---

## 5. Giải thích luồng hoạt động

- Các địa chỉ SDRAM trong IVT (`self`, `dcd_ptr`, `boot_data_ptr`) **không phải để Boot ROM nhảy tới** — mà chỉ là **pointer để Boot ROM tính offset tương đối** bằng phép trừ `dcd_ptr - self = 0x2C`. Boot ROM load **4KB đầu từ eMMC lên OCRAM** (vì DDR chưa init), sau đó dùng offset `0x2C` để tìm **data thực thụ của DCD** trong vùng 4KB đó trên OCRAM — bao gồm địa chỉ các thanh ghi và giá trị cấu hình DDR — rồi thực thi từng lệnh ghi vào hardware để init DDR.
- Boot ROM dùng **BootData** để biết load từ vùng nào, size bao nhiêu → sau đó dùng `entry_point` để **jump vào u-boot.imx**.
- **Tại sao IVT vẫn còn trên SDRAM sau khi đã init DDR xong?** Vì `BootData.start` trỏ về đầu toàn bộ image nên Boot ROM load **nguyên khối** từ đầu đến hết `BootData.size` lên SDRAM — IVT, DCD, BootData được copy lên theo, không có mục đích gì khác. Các địa chỉ SDRAM trong IVT chỉ nói lên tính **bất biến của offset `0x2C`** — khoảng cách này không thay đổi dù trên eMMC, OCRAM hay SDRAM vì do cấu trúc struct quyết định.
- Boot ROM **dịch địa chỉ từ offset base** — do không có code Boot ROM nên không rõ luồng chi tiết bên trong.

---

## 6. Layout offset bất biến (OCRAM vs SDRAM)

| eMMC Offset | Vùng | OCRAM / SDRAM Address | Vùng |
|---|---|---|---|
| `0x0400` | IVT Header | `0x877FF400` | IVT Header |
| `0x0420` | BootData | `0x877FF420` | BootData |
| `0x042C` | DCD data | `0x877FF42C` | DCD data |

Khoảng cách từ IVT đến DCD **luôn bất biến = `0x2C`** dù trên OCRAM hay SDRAM —
vì đây là `offsetof(imx_header_v2_t, data)` do cấu trúc struct quyết định:

```
dcd_ptr - self = 0x877FF42C - 0x877FF400 = 0x2C  ✅
```

Boot ROM load 4KB lên OCRAM, dùng `0x2C` này để tìm **data thực thụ của DCD**
(địa chỉ thanh ghi + giá trị cấu hình DDR) trong vùng 4KB đó rồi thực thi init DDR:

```
OCRAM_base + 0x2C → đọc DCD data thực thụ → ghi vào hardware register → init DDR
```

---

## 7. Layout IVT Header trên flash (tính từ `flash_offset = 0x0400`)

```c
typedef struct {
    uint32_t header;        // 0x0400
    uint32_t entry;         // 0x0404
    uint32_t reserved1;     // 0x0408
    uint32_t dcd_ptr;       // 0x040C
    uint32_t boot_data_ptr; // 0x0410
    uint32_t self;          // 0x0414
    uint32_t csf;           // 0x0418
    uint32_t reserved2;     // 0x041C
} flash_header_v2_t;        // tổng = 0x20 = 32 byte
```

| Offset | Trường | Giá trị |
|---|---|---|
| `0x0400` | `header` | Tag + length + version |
| `0x0404` | `entry` | `0x87800000` (entry point của u-boot) |
| `0x0408` | `reserved1` | `0x00000000` |
| `0x040C` | `dcd_ptr` | `0x877FF42C` |
| `0x0410` | `boot_data_ptr` | `0x877FF420` |
| `0x0414` | `self` | `0x877FF400` |
| `0x0418` | `csf` | `0x00000000` (không dùng secure boot) |
| `0x041C` | `reserved2` | `0x00000000` |




#### Layout vùng nhớ sau khi mkimage tạo xong

```
ptr + 0x000  ┌─────────────────┐
             │  padding 0x400  │  ← vùng trống trước IVT (filled 0x00)
ptr + 0x400  ├─────────────────┤
             │   IVT Header    │  ← flash_header_v2_t (0x20 bytes)
             │   self          │    = 0x877FF400
             │   dcd_ptr       │    = 0x877FF42C
             │   boot_data_ptr │    = 0x877FF420
             │   entry         │    = 0x87800000
ptr + 0x420  ├─────────────────┤
             │   BootData      │  ← boot_data_t (0x0C bytes)
             │   start         │    = 0x877FF000
             │   size          │    = ROUND(0x6A000 + 0x400, 4096)
             │   plugin        │    = 0x00000000
ptr + 0x42C  ├─────────────────┤
             │   DCD data      │  ← dcd_v2_t
             │   (cấu hình DDR)│    địa chỉ thanh ghi + giá trị
             │   ...           │
ptr + 0x1400 ├─────────────────┤
             │                 │
             │   u-boot.bin    │  ← binary thực tế của u-boot
             │                 │
             └─────────────────┘
```