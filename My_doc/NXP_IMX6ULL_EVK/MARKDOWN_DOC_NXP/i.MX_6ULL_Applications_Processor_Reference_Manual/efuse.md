# Boot Config Registers — iMX6ULL USDHC

---

## 0x450 — Boot Config Register

### [7:6] — Device selection (2 bit → 4 khả năng)

2 bit → đủ để chọn nhiều boot source khác nhau:

| Giá trị | Device |
|---------|--------|
| 00 | NOR Flash |
| 01 | **USDHC** ← đang dùng |
| 10 | NAND |
| 11 | Serial |

---

### [5] — MMC/eMMC vs SD Card

Tách tiếp để chọn loại thiết bị:

| Bit | Ý nghĩa |
|-----|---------|
| 0 | SD Card |
| 1 | **eMMC** |

---

### [4] — Normal / Fast boot

| Bit | Chế độ | Mô tả |
|-----|--------|-------|
| 0 | **Normal boot** | Không yêu cầu về thời gian — phải khởi tạo đầy đủ CMD[7:0] |
| 1 | **Fast boot** | Ví dụ cần boot trong 2s khi bật nguồn → truyền argument set sẵn trong CMD0, bỏ qua bước chọn → product thường làm như này |

---

### [3:2] — Speed mode

#### Bit [3] — Tốc độ clock

| Bit | Ý nghĩa |
|-----|---------|
| 0 | Tốc độ **chậm** — dùng cho board chưa test xung chuẩn, cần boot chậm để debug xem xung có chuẩn không |
| 1 | Tốc độ **nhanh** — dùng cho board đã căn chỉnh tụ, trở kháng, PCB xung ra không nhiễu nữa |

#### Bit [2] — ACK enable/disable

**ACK enable (bit2 = 0):**
```
eMMC nhận CMD0 → gửi ACK response lại
Boot ROM chờ ACK rồi mới đọc data
→ an toàn hơn, chắc chắn eMMC sẵn sàng
```

**ACK disable (bit2 = 1):**
```
eMMC nhận CMD0 → stream data luôn, không ACK
Boot ROM không chờ → nhanh hơn vài ms
→ rủi ro hơn nếu eMMC chưa kịp sẵn sàng
```

---

### [1] — eMMC hardware reset enable

| Bit | Ý nghĩa |
|-----|---------|
| 0 | Board đơn giản, eMMC luôn power on sạch → không cần RST_n |
| 1 | Hệ thống có thể mất điện bất ngờ → industrial, automotive → cần đảm bảo eMMC clean state mỗi lần boot |

---

### [0] — CLK feedback (through pad)

**Bit = 0 (through pad — bật feedback):**
```
CLK ra → qua trace PCB → feedback về
→ uSDHC dùng CLK feedback này để sample data
→ tự động bù delay trace
→ dùng trong production
```

**Bit = 1 (tắt feedback)**

---

### [15:13] — Bus width

Phụ thuộc vào thiết bị boot là **SD Card** hay **eMMC**:

#### Nếu là SD Card

Dùng **bit [13]** để chọn bus width:

| Bit 13 | Bus width |
|--------|-----------|
| 0 | 1-bit |
| 1 | 4-bit |

**Bit [14:15]** — Delay cell cho CLK sampling:

```
Không có delay:
CLK:   ─┬─┬─┬─┬─
        ↑ sample ở đây
Data:  ──[valid]──
         ↑ data mới có ở đây → sample sớm quá → SAI

Thêm 2 delay cell:
CLK:   ─┬─┬─┬─┬─
           ↑ sample dịch sang đây
Data:  ──[valid]──
           ↑ khớp → ĐÚNG
```

#### Nếu là eMMC

Dùng cả 3 bit [15:13]:

| Giá trị | Bus width |
|---------|-----------|
| 000 | 1-bit |
| 001 | 4-bit |
| 010 | 8-bit |
| 101 | 4-bit DDR (MMC 4.4) |
| 110 | 8-bit DDR (MMC 4.4) |
| else | Reserved |

---

### [12:11] — USDHC port (1 hay 2)

Trên board có 2 port controller: **USDHC1** và **USDHC2**

- Chọn theo mạch thực tế — eMMC/SD hàn vào controller nào thì chọn cái đó

---

### [9] — Voltage select

| Bit | Điện áp |
|-----|---------|
| 0 | 3.3V |
| 1 | 1.8V |

---

## 0x460 — Boot Config Register 2

### [31:30] — Power cycle delay

Thời gian delay để reset: kéo RESET xuống LOW rồi lên HIGH để đường CMD ổn định trước khi internal init.

| Giá trị | Delay |
|---------|-------|
| 00 | 20 ms |
| 01 | 10 ms |
| 10 | 5 ms |
| 11 | 2.5 ms |

---

### [24] — OEM Power stable cycle

Thời gian chờ nguồn ổn định trước khi toggle:

| Bit | Thời gian |
|-----|-----------|
| 0 | 5 ms |
| 1 | 2.5 ms |

---

## 0x470 — Boot Config Register 3

### [7] — DLL override

Tự động đo, sample và chỉnh lại độ trễ.

### [6/15] — Reset polarity USDHC1/2 config

---

## 0x32 — Boot config (binary)

```
0x32 = 0011 0010
```

| Bits | Field | Giá trị | Ý nghĩa |
|------|-------|---------|---------|
| [2:0] | Time unit | 010 | 10 MHz |
| [6:3] | Time value | 0110 | 2.5 |