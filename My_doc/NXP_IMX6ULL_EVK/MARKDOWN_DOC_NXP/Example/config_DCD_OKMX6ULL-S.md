# DDR3L SDRAM — iMX6ULL Notes

## Cấu trúc chip DDR3L SDRAM

> 256meg là cả tòa nhà
> 32meg chỉ là 1 phòng

**DDR3L SDRAM 32 Meg x 16 x 8 banks**

- 1 Megabit = 2^20 = 1.048.576 bit → 2 Mga = 2.097.152
- x16: mỗi khi trỏ vào 1 địa chỉ có thể đọc/ghi được 16 bit cùng lúc là DQ0–DQ15
- x8: có 8 bank chứa dữ liệu

```
= 2M địa chỉ × 16 bit × 8 bank
= 256 Mbit
= 32 MB
```

---

## Tốc độ truyền dữ liệu

```
933 MHz × 2 cạnh (rising + falling)
= 1866 triệu lần truyền / giây
= 1866 MT/s (Mega Transfers per second)

1866 MT/s × 16 bit (bus width)
= 29,856 Mb/s
= 3,732 MB/s
≈ 3.7 GB/s
```

---

## Address Structure

- **ROW ADDRESS**: 32K → A[14:0] (15 bit → 2^15 = 32.768 row)
- **COLUMN ADDRESS**: 1K → A[9:0] (10 bit → 2^10 = 1.024 = 1K columns)
- **Page size**: 2KB

> Tụ điện trong cell DDR rất nhỏ, khoảng 20–30 femtofarad (fF) — nhỏ đến mức điện tích lưu trong đó rất ít → cần buffer để khuếch đại lên để có thể đọc chính xác.

---

## AXI (Advanced Extensible Interface)

Thuộc chuẩn **AMBA** (Advanced Microcontroller Bus Architecture) của ARM — là chuẩn giao thức để chip ARM có thể giao tiếp với RAM và các khối khác.

Giống người vận chuyển trung gian giữa CPU và các khối khác → chia thành 2 loại:

- **MASTER**
- **SLAVE**

> Ví dụ: CPU → MMDC thì CPU là MASTER, MMDC là SLAVE, giao tiếp qua AXI interface.

---

## Luồng hoạt động MMDC

### B1: AXI Interface
Đưa các request của CPU vào **QUEUE**.

### B2: DDR Optimization
Nhân viên điều phối — sắp xếp các request sao cho hợp lý nhất để nhanh nhất.

### B3: MMDC Logic

#### ADDR CTRL
Chuyển AXI Address → Bank, Row, Column

```
Ví dụ: AXI Address 0x14000ABC
→ 0 | 000 | 1 0100 0000 0000 00 | 00 1010 1011 1 | 0
  A29| BANK|      ROW[14:0]     |    COL[9:0]    | A0
```

#### Bank Model
1. Theo dõi trạng thái bank: **IDLE / ACTIVE / PRECHARGING**
2. Lưu row nào đang mở → biết CAS hit hay miss:
   - Row đang mở = Row cần → **CAS hit** → READ/WRITE luôn
   - Row đang mở ≠ Row cần → **CAS miss** → PRECHARGE + ACTIVATE + READ/WRITE
3. Báo cho CMD CTRL trạng thái hiện tại của bank

#### Timing Parameters

| Tham số | Ý nghĩa |
|---------|---------|
| tRCD | ACTIVATE xong phải chờ bao lâu mới READ/WRITE được |
| tRP  | PRECHARGE xong phải chờ bao lâu mới ACTIVATE được cùng bank |
| tRAS | ACTIVATE xong phải chờ bao lâu mới PRECHARGE được |
| tRC  | 2 lần ACTIVATE cùng bank cách nhau bao lâu |
| tRFC | REFRESH xong phải chờ bao lâu |

#### CMD CTRL
Đúng đủ cycle → gửi command xuống PHY:

- `PRECHARGE` → đóng row đang mở
- `ACTIVATE`  → mở row mới (kèm BANK + ROW address)
- `READ/WRITE` → đọc/ghi (kèm BANK + COL address)
- `REFRESH`   → làm tươi tụ điện định kỳ

### B4: MMDC_PHY (Xử lý tín hiệu điện)

**PHY X16** — thiết kế cho bus width 16 bit:

- 16 chân **DQ** → data
- 2 chân **DQS#** → differential pair của DQS
  > Chip DDR gửi data ra → DQS cũng toggle cùng lúc → MMDC_PHY dùng DQS để biết chính xác lúc nào data hợp lệ → chốt data vào đúng thời điểm
- 1 chân **CLK**
- 1 chân **CLK#**

#### Measure Unit (ps)
Đơn vị đo nhỏ nhất để đo độ trễ.

> 16 chân DQ nhưng chỉ có 2 chân DQS quản lý → các chân trên PCB có độ dài ngắn khác nhau → sinh ra độ trễ khác nhau → cần cơ chế tính trễ và bù trễ.

#### Delay-lines (ps)
Đường dây — thường dùng 6 bit để biểu diễn → tương ứng 63 ô, mỗi ô chứa một bit.

#### Fine Tune
Giá trị cần sửa trong DCD để delay hợp lý cho đường dây đó lấy đúng data.

---

## IP0 — Cổng truy cập mềm

- **IP0**: cổng mềm cho phép truy cập và sửa thanh ghi của DDRAM
- **IP I/F (BASE 0)**: cổng mềm vào controller DDRAM tại `0x21B_0000`

---

## ZQ Calibration

Hiệu chỉnh trở kháng của các chân output trong MMDC_PHY.

**Hình dung thực tế:**

| Khái niệm | Tương đương |
|-----------|------------|
| Đường dây | Ống nước |
| Tín hiệu  | Nước chảy |
| Trở kháng | Độ rộng ống |

**Khi trở kháng không khớp:**
```
Nguồn phát → 50 ohm
Đường dây  → 60 ohm
→ tín hiệu đến chỗ thay đổi → bị dội ngược lại
→ giống sóng nước gặp bờ → dội lại → tín hiệu bị nhiễu
```

**Khi trở kháng khớp:**
```
Nguồn phát → 50 ohm
Đường dây  → 50 ohm
→ tín hiệu đi thẳng không bị dội → tín hiệu sạch
```

**Tại sao cần ZQ định kỳ:**
```
Nhiệt độ tăng → điện trở vật liệu thay đổi
→ trở kháng thay đổi theo → không còn khớp nữa
→ ZQ chỉnh lại cho khớp
```

```
RZQ = 240 ohm cố định
→ đo điện áp/dòng điện qua RZQ
→ so sánh với giá trị mong muốn
→ chỉnh cho khớp
```

---

## DCD Config — iMX6ULL + DDR3L MT41K256M16TW-107

### NHÓM 1: ENABLE CLOCK (CCM — Clock Controller Module)

Địa chỉ: `0x020c4xxx` — Mục đích: bật clock cho MMDC và các peripheral

```
DATA 4 0x020c4068 0xffffffff  /* CCM_CCGR0 — bật tất cả clock gate 0 */
DATA 4 0x020c406c 0xffffffff  /* CCM_CCGR1 — bật tất cả clock gate 1 */
DATA 4 0x020c4070 0xffffffff  /* CCM_CCGR2 — bật tất cả clock gate 2 */
DATA 4 0x020c4074 0xffffffff  /* CCM_CCGR3 — bật tất cả clock gate 3 */
DATA 4 0x020c4078 0xffffffff  /* CCM_CCGR4 — bật tất cả clock gate 4 */
DATA 4 0x020c407c 0xffffffff  /* CCM_CCGR5 — bật tất cả clock gate 5 */
DATA 4 0x020c4080 0xffffffff  /* CCM_CCGR6 — bật tất cả clock gate 6 */
```

---

### NHÓM 2: IOMUX — PIN CONFIG (IOMUXC)

Địa chỉ: `0x020Exxxx` — Mục đích: cấu hình chân vật lý DDR bus

- `0x00000030` = drive strength DSE=6 (110b), tốc độ FAST
- `0x00020000` = DDR mode select = DDR3
- `0x00000000` = drive strength thấp nhất (dùng cho CLK)

```
DATA 4 0x020E04B4 0x000C0000  /* IOMUXC_SW_PAD_CTL_GRP_DDR_TYPE  — DDR3 mode */
DATA 4 0x020E04AC 0x00000000  /* IOMUXC_SW_PAD_CTL_GRP_DDRPKE    — pull disable */
DATA 4 0x020E027C 0x00000030  /* IOMUXC_SW_PAD_CTL_PAD_DRAM_SDCLK0 — CLK drive */
DATA 4 0x020E0250 0x00000030  /* IOMUXC_SW_PAD_CTL_PAD_DRAM_CAS  — CAS# drive */
DATA 4 0x020E024C 0x00000030  /* IOMUXC_SW_PAD_CTL_PAD_DRAM_RAS  — RAS# drive */
DATA 4 0x020E0490 0x00000030  /* IOMUXC_SW_PAD_CTL_GRP_ADDDS     — addr drive */
DATA 4 0x020E0288 0x00000030  /* IOMUXC_SW_PAD_CTL_PAD_DRAM_RESET — RESET# drive */
DATA 4 0x020E0270 0x00000000  /* IOMUXC_SW_PAD_CTL_PAD_DRAM_SDBA2 — BA2 drive */
DATA 4 0x020E0260 0x00000030  /* IOMUXC_SW_PAD_CTL_PAD_DRAM_ODT0  — ODT drive */
DATA 4 0x020E0264 0x00000030  /* IOMUXC_SW_PAD_CTL_PAD_DRAM_ODT1  — ODT drive */
DATA 4 0x020E04A0 0x00000030  /* IOMUXC_SW_PAD_CTL_GRP_CTLDS      — ctrl drive */
DATA 4 0x020E0494 0x00020000  /* IOMUXC_SW_PAD_CTL_GRP_DDR_TYPE   — DDR3 mode */
DATA 4 0x020E0280 0x00000030  /* IOMUXC_SW_PAD_CTL_PAD_DRAM_SDCKE0 — CKE drive */
DATA 4 0x020E0284 0x00000030  /* IOMUXC_SW_PAD_CTL_PAD_DRAM_SDCKE1 — CKE drive */
DATA 4 0x020E04B0 0x00020000  /* IOMUXC_SW_PAD_CTL_GRP_DDRMODE    — DDR3 mode */
DATA 4 0x020E0498 0x00000030  /* IOMUXC_SW_PAD_CTL_GRP_B0DS       — DQ byte0 drive */
DATA 4 0x020E04A4 0x00000030  /* IOMUXC_SW_PAD_CTL_GRP_B1DS       — DQ byte1 drive */
DATA 4 0x020E0244 0x00000030  /* IOMUXC_SW_PAD_CTL_PAD_DRAM_DQM0  — DM0 drive */
DATA 4 0x020E0248 0x00000030  /* IOMUXC_SW_PAD_CTL_PAD_DRAM_DQM1  — DM1 drive */
```

---

### NHÓM 3: MMDC PHY CONFIG (MMDC_PHY registers)

Địa chỉ: `0x021B08xx` — Mục đích: cấu hình tín hiệu vật lý — delay-line, ZQ, ODT

#### Enable config mode

```
DATA 4 0x021B001C 0x00008000
```
> MDSCR — bật configuration request. Cho phép CPU ghi config vào MMDC qua IP0.

#### ZQ Calibration

```
DATA 4 0x021B0800 0xA1390003
```
> **MPZQHWCTRL** — cấu hình ZQ tự động
> - A1 = ZQ_HW_FOR=1 (bật ZQ HW)
> - 39 = ZQ interval (tần suất đo lại trở kháng)
> - 03 = ZQ_HW_PD_RES=3 (độ phân giải)
>
> Chip DDR có chân ZQ nối điện trở 240 ohm trên PCB → MMDC định kỳ đo dòng qua chân ZQ → so sánh với 240 ohm chuẩn → chỉnh output driver và ODT cho khớp → bù nhiệt độ thay đổi khi hệ thống chạy.

#### Write Leveling

```
DATA 4 0x021B080C 0x00000000
```
> **MPWLDECTRL0** — write leveling delay = 0
>
> CLK và DQS đi từ MMDC → chip DDR trên 2 đường dây khác nhau → dài ngắn khác nhau → đến chip không cùng lúc → cần căn chỉnh để CLK và DQS đến cùng lúc → = 0 vì chạy HW calibration tự động lúc boot.

#### DQS Gating — thời điểm MMDC_PHY mở cổng đọc DQS

```
DATA 4 0x021B083C 0x41570155
```
> **MPDGCTRL0** — DQS gating delay
> - byte1 = 0x57 = 87 unit
> - byte0 = 0x55 = 85 unit
>
> Khi READ, chip DDR phát DQS về MMDC_PHY → MMDC_PHY chỉ "mở cổng" đọc DQS trong khoảng thời gian hợp lệ → tránh đọc nhầm lúc DQS chưa ổn định → giá trị này là số unit delay để mở cổng đúng lúc.

#### Read Delay-line — bù độ lệch DQS khi đọc

```
DATA 4 0x021B0848 0x4040474A
```
> **MPRDDLCTL** — read delay-line
> - byte3 = 0x40 (không dùng với x16)
> - byte2 = 0x40 (không dùng với x16)
> - byte1 = 0x47 = 71 unit → delay cho UDQS (byte cao DQ[15:8])
> - byte0 = 0x4A = 74 unit → delay cho LDQS (byte thấp DQ[7:0])
>
> Khi READ, DQS và DQ đi từ chip DDR → MMDC_PHY → đường dây DQS và DQ dài ngắn khác nhau → thêm delay vào DQS để DQS và DQ đến cùng lúc → MMDC_PHY chốt data chính xác.

#### Write Delay-line — bù độ lệch DQS khi ghi

```
DATA 4 0x021B0850 0x40405550
```
> **MPWRDLCTL** — write delay-line
> - byte3 = 0x40 (không dùng với x16)
> - byte2 = 0x40 (không dùng với x16)
> - byte1 = 0x55 = 85 unit → delay cho UDQS khi ghi
> - byte0 = 0x50 = 80 unit → delay cho LDQS khi ghi
>
> Khi WRITE, DQS và DQ đi từ MMDC_PHY → chip DDR → tương tự read delay nhưng chiều ngược lại.

#### DQ Delay — fine tune từng chân DQ

```
DATA 4 0x021B081C 0x33333333
```
> **MPRDDQBY0DL** — read DQ delay byte0 DQ[7:0]
> - mỗi nibble = 3 unit
> - DQ0=3, DQ1=3, DQ2=3, DQ3=3, DQ4=3, DQ5=3, DQ6=3, DQ7=3
>
> Mỗi chân DQ đi trên đường dây riêng trên PCB → dài ngắn khác nhau → đến MMDC_PHY không cùng lúc → fine tune từng chân riêng lẻ để đồng bộ với LDQS.

```
DATA 4 0x021B0820 0x33333333
```
> **MPRDDQBY1DL** — read DQ delay byte1 DQ[15:8] — mỗi nibble = 3 unit cho từng chân DQ[15:8] — fine tune từng chân đồng bộ với UDQS.

```
DATA 4 0x021B082C 0xf3333333
```
> **MPWRDQBY0DL** — write DQ delay byte0 — delay cho DQ[7:0] khi ghi.

```
DATA 4 0x021B0830 0xf3333333
```
> **MPWRDQBY1DL** — write DQ delay byte1 — delay cho DQ[15:8] khi ghi.

#### Duty Cycle và Measure Unit

```
DATA 4 0x021B08C0 0x00921012
```
> **MPDCCR** — duty cycle control — điều chỉnh duty cycle của clock DDR — đảm bảo HIGH và LOW gần bằng nhau.

```
DATA 4 0x021B08b8 0x00000800
```
> **MPMUR0** — measure unit = 0x800 — đơn vị đo nhỏ nhất của delay-line (~15–20ps mỗi unit) — dùng làm chuẩn cho tất cả delay-line calibration.

#### DQS Gating HW — chỉ dùng cho chip TW-107

```
DATA 4 0x021B0890 0x23400A38
```
> **MPPDCMPR2** — pre-defined compare register — pattern chuẩn dùng cho HW calibration — MMDC so sánh data nhận được với pattern này → tìm delay-line tối ưu tự động.

---

### NHÓM 4: MMDC CORE TIMING

Địa chỉ: `0x021B0xxx` — Mục đích: cấu hình timing DDR theo datasheet chip
**Clock = 400MHz → tCK = 2.5ns**

```
DATA 4 0x021B0004 0x0002002D
```
> **MDPDC** — power down config (lần 1, trước init)
> - PRCT   = 2 → precharge timer
> - PWDT   = 0 → power down timer tắt (chưa bật lúc này)
> - tCKSRE = 5 cycles
>
> **tCKSRE**: sau lệnh Self Refresh Entry → chip DDR cần hoàn thành quá trình vào ngủ → phải chờ 5 cycles = 12.5ns → rồi mới tắt clock CK/CK# được → không tắt sớm hơn vì chip chưa vào ngủ xong.

```
DATA 4 0x021B0008 0x1B333030
```
> **MDOTC** — ODT timing
>
> - **tAOFPD** = 1 cycle: Chip đang Power Down, ODT đang bật → MMDC muốn tắt ODT → chờ 1 cycle mới tắt xong.
> - **tAONPD** = 1 cycle: Chip đang Power Down, có lệnh WRITE đến → phải bật ODT trước khi data đến → chờ 1 cycle mới bật ODT xong.
> - **tANPD** = 3 cycles: Chip đang Power Down ở chế độ Asynchronous → MMDC phát tín hiệu ODT=1 → transistor cần thời gian mở hoàn toàn → điện trở cần đạt giá trị ổn định → chờ 3 cycles = 7.5ns mới có tác dụng thực sự.
> - **tAXPD** = 3 cycles: Chip đang Power Down, ODT đang bật → MMDC phát tín hiệu ODT=0 → transistor cần thời gian đóng hoàn toàn → chờ 3 cycles = 7.5ns mới tắt hẳn.
> - **tODTLon** = 3 cycles: MMDC phát lệnh WRITE → data chưa đến chip DDR ngay (cần tCWL cycles) → không bật ODT ngay → tốn điện vô ích → chờ 3 cycles rồi mới bật ODT → bật đúng lúc data đến → hấp thụ phản xạ chính xác.
> - **tODT** = 0: WRITE xong → vẫn còn phản xạ trên đường dây → tODT = 0 → tắt ODT ngay → phù hợp board ngắn, phản xạ tắt nhanh.

```
DATA 4 0x021B000C 0x676B52F3
```
> **MDCFG0** — timing group 0
>
> - **tRFC** = 0x67 = 103 cycles × 2.5ns = 257ns: Tụ điện trong cell tự xả theo thời gian → MMDC phát lệnh REFRESH định kỳ → chip DDR nạp lại tất cả tụ điện → tốn tRFC = 103 cycles → trong thời gian này không thể READ/WRITE → phải chờ hết tRFC rồi mới dùng được. (datasheet tRFC min = 260ns → 103 × 2.5 = 257ns ≈ đủ)
> - **tXS** = 0x6B = 107 cycles × 2.5ns = 267ns: Chip DDR đang Self Refresh (ngủ sâu) → CKE kéo lên 1 → thoát Self Refresh → clock vừa bật lại → DLL cần thời gian lock lại → internal circuit cần ổn định → chờ 107 cycles rồi mới phát lệnh được. (= tRFC + 10ns = 260 + 10 = 270ns ≈ khớp)
> - **tXP** = 5 cycles × 2.5ns = 12.5ns: Chip DDR đang Power Down (ngủ nhẹ) → CKE kéo lên 1 → thoát Power Down → input buffer cần bật lại → chờ 5 cycles rồi mới phát lệnh được. (ngủ nhẹ hơn Self Refresh → thức nhanh hơn)
> - **tXPDLL** = 2 cycles: Thêm thời gian cho DLL lock sau Power Down.
> - **tFAW** = 0xF = 15 cycles × 2.5ns = 37.5ns: Four Activate Window → trong 1 khoảng tFAW chỉ được phát tối đa 4 ACTIVATE → tránh quá tải row amplifier.
> - **tCL** = 3 → CL = 7 cycles: CAS Latency — sau lệnh READ → chờ 7 cycles mới có data ra bus.

```
DATA 4 0x021B0010 0xB66D0B63
```
> **MDCFG1** — timing group 1
>
> - **tRCD** = 6 cycles × 2.5ns = 15ns: Sau ACTIVATE → chờ tRCD → mới READ/WRITE được. Row đang được kéo vào buffer, cần thời gian ổn định.
> - **tRP** = 6 cycles × 2.5ns = 15ns: Sau PRECHARGE → chờ tRP → mới ACTIVATE được. Row buffer đang đẩy data về tụ, cần thời gian hoàn thành.
> - **tRC** = 0x1A = 26 cycles × 2.5ns = 65ns: Khoảng cách tối thiểu giữa 2 lần ACTIVATE cùng bank = tRAS + tRP.
> - **tRAS** = 0x0B = 15 cycles × 2.5ns = 37.5ns: Sau ACTIVATE → chờ tối thiểu tRAS → mới PRECHARGE được. Đảm bảo data đã ghi xong vào tụ trước khi đóng row.
> - **tRPA** = 1: PRECHARGE ALL banks timing.
> - **tWR** = 6 cycles × 2.5ns = 15ns: Sau WRITE xong → chờ tWR → mới PRECHARGE được. Đảm bảo data ghi xong vào tụ điện.
> - **tMRD** = 3 cycles: Sau lệnh MRS → chờ tMRD → mới phát lệnh khác.
> - **tCWL** = 3 → CWL = 6 cycles: CAS Write Latency — sau lệnh WRITE → chờ 6 cycles mới ghi data vào chip.

```
DATA 4 0x021B0014 0x01FF00DB
```
> **MDCFG2** — timing group 2
>
> - **tDLLK** = 0x1FF = 511 cycles: Sau DLL reset → chờ 511 cycles → DLL lock hoàn toàn.
> - **tRTP** = 4 cycles: READ to PRECHARGE → sau READ chờ tRTP rồi mới PRECHARGE.
> - **tWTR** = 3 cycles: WRITE to READ → sau WRITE chờ tWTR rồi mới READ. Chờ data ghi xong trước khi đọc.
> - **tRRD** = 3 cycles: ACTIVATE to ACTIVATE different bank — Khoảng cách tối thiểu giữa 2 ACTIVATE khác bank.

```
DATA 4 0x021B0018 0x00201740
```
> **MDMISC** — miscellaneous config
> - DDR_TYPE  = 1 → DDR3
> - BI        = 1 → bank interleaving ON — BANK bits nằm ở giữa → trải request ra nhiều bank → giảm CAS miss → tăng hiệu suất
> - WALAT     = 1 → write additional latency
> - RALAT     = 5 → read additional latency
> - MIF3_MODE = 3 → AXI interface mode
> - LPDDR2_S2 = 0 → không dùng LPDDR2

```
DATA 4 0x021B001C 0x00008000
```
> **MDSCR** — bật configuration request lại.

```
DATA 4 0x021B002C 0x000026D2
```
> **MDRWD** — read/write command delay
> - RTW_SAME = 2 → READ to WRITE cùng bank
> - WTR_DIFF = 6 → WRITE to READ khác bank
> - WTR_SAME = 5 → WRITE to READ cùng bank
> - RTW_DIFF = 2 → READ to WRITE khác bank

```
DATA 4 0x021B0030 0x006B1023
```
> **MDOR** — out of reset delays
> - tXPR       = 0x6B = 107 cycles → sau RESET# thả ra chờ tXPR
> - SDE_to_RST = 0x10 → sau enable chip đến khi RESET# active
> - RST_to_CKE = 0x23 = 35 cycles → sau RESET# release đến CKE HIGH

```
DATA 4 0x021B0040 0x0000004F
```
> **MDASP** — address space partition
> - CS0_END = 0x4F → chip 512MB map vào 0x80000000 → 0x9FFFFFFF → MMDC so sánh 7 bit cao AXI address với CS0_END → biết request thuộc rank nào (CS0 hay CS1).

---

### NHÓM 5: DDR INITIALIZATION SEQUENCE (JEDEC)

Mục đích: khởi tạo chip DDR theo chuẩn JEDEC DDR3

```
DATA 4 0x021B0000 0x84180000
```
> **MDCTL** — control register, nói với MMDC cấu trúc chip DDR
> - DSIZ  = 01 → x16 (bus 16 bit)
> - BL    = 1  → burst length 8
> - COL   = 0  → 10 bit column (1K cols)
> - ROW   = 4  → 15 bit row (32K rows)
> - SDE_0 = 1  → enable CS0 (chip 1 hoạt động)
> - SDE_1 = 0  → disable CS1 (không có chip 2)

```
DATA 4 0x021B001C 0x02008032
```
> **MDSCR** → phát lệnh MRS → MR2
> - BA  = 010 → chip DDR load Mode Register 2
> - CWL = 6 cycles (CAS Write Latency)
> - ASR = 0 → disable Auto Self Refresh
> - SRT = 0 → normal temperature range (0°C~85°C)

```
DATA 4 0x021B001C 0x00008033
```
> **MDSCR** → phát lệnh MRS → MR3
> - BA  = 011 → chip DDR load Mode Register 3
> - MPR = 0 → normal operation (tắt Multi Purpose Register)

```
DATA 4 0x021B001C 0x00048031
```
> **MDSCR** → phát lệnh MRS → MR1
> - BA  = 001 → chip DDR load Mode Register 1
> - DLL = enable
> - DS  = 40 ohm (output drive strength)
> - ODT = 60 ohm (RTT_NOM=010) → điện trở termination bên trong chip

```
DATA 4 0x021B001C 0x15208030
```
> **MDSCR** → phát lệnh MRS → MR0
> - BA        = 000 → chip DDR load Mode Register 0
> - BL        = 8   → burst length 8
> - CL        = 7   → CAS Latency 7 cycles
> - WR        = 6 cycles (Write Recovery)
> - DLL reset = 1   → reset DLL trong chip DDR

```
DATA 4 0x021B001C 0x04008040
```
> **MDSCR** → phát lệnh ZQ Calibration Long (ZQCL)
> - Chip DDR đo dòng qua chân ZQ (240 ohm trên PCB) → chỉnh output driver và ODT lần đầu tiên → tốn ~512 cycles → sau lệnh này chip DDR sẵn sàng hoàn toàn.

---

### NHÓM 6: HOÀN THIỆN CONFIG

```
DATA 4 0x021B0020 0x00000800
```
> **MDREF** — refresh control
> - REF_CNT = 0x800 → tREFI = khoảng cách giữa 2 lần REFRESH → MMDC tự động phát REFRESH định kỳ → đảm bảo tụ điện không bị xả hết.

```
DATA 4 0x021B0818 0x00000227
```
> **MPODTCTRL** — ODT control
> - ODT0_RD_ACT = 0 → tắt ODT khi READ (chip đang phát data ra)
> - ODT0_WR_ACT = 1 → bật ODT khi WRITE (chip đang nhận data)
> - RTT = 0x27 → giá trị điện trở ODT

```
DATA 4 0x021B0004 0x0002552D
```
> **MDPDC** — power down config (lần 2, sau init)
> - PRCT   = 2 → precharge timer
> - PWDT   = 5 → power down timer = 5 → sau 5 cycles không có request → MMDC tự động cho chip DDR vào Power Down → tiết kiệm điện
> - tCKSRE = 5 cycles → chờ trước khi tắt clock

```
DATA 4 0x021B0404 0x00011006
```
> **MAARCR** — AXI reorder control
> - ARCR_DIS_RD_BUSY_CLR = 0
> - ARCR_ACC_HIT = 1 → ưu tiên request cùng bank/row đang mở → tăng CAS hit → hiệu suất cao hơn
> - ARCR_PAR_EN  = 1 → bật reorder queue → sắp xếp lại request để tối ưu

```
DATA 4 0x021B001C 0x00000000
```
> **MDSCR** — tắt configuration mode
> - = 0 → thoát config mode → MMDC sẵn sàng hoạt động bình thường → AXI0 bắt đầu nhận request từ CPU → chip DDR sẵn sàng READ/WRITE.
