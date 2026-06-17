# i.MX 6ULL — Chapter 21: External Interface Module (EIM)

> Tài liệu tham khảo: *i.MX 6ULL Applications Processor Reference Manual, Rev. 1, 11/2017 — NXP Semiconductors*

---

## 21.1 Tổng quan

EIM quản lý giao diện tới các thiết bị ngoài chip, bao gồm tạo chip select, clock và điều khiển cho các peripheral và bộ nhớ ngoài. Hỗ trợ:
- **Asynchronous access** — thiết bị có giao diện kiểu SRAM
- **Synchronous access** — thiết bị có giao diện kiểu NOR-Flash hoặc PSRAM

### 21.1.1 Tính năng

- **6 chip select** cho thiết bị ngoài
- Giải mã địa chỉ linh hoạt, mỗi CS space xác định riêng theo cấu hình VIA port
- Mật độ tối đa: **128 MB** (AUS=0) hoặc **32 MB** (AUS=1)
- Write protection riêng cho mỗi Chip Select
- Hỗ trợ multiplexed address/data bus x16
- Programmable Data Port Size: x8, x16
- Programmable Wait-State generator cho mỗi CS (read/write riêng biệt)
- Asynchronous accesses với setup/hold time cấu hình được
- Asynchronous page mode (x16)
- Synchronous Memory Burst Read cho NOR-Flash và PSRAM (x16)
- Synchronous Memory Burst Write cho PSRAM và NOR-Flash (CellularRAM™, OneNAND™, utRAM™, COSMORAM™)
- Hỗ trợ NAND-Flash với giao diện NOR-Flash — MDOC™, OneNAND™
- Variable/fix latency cho read/write synchronous (burst) mode
- Big Endian và Little Endian per access
- ARM AXI slave interface — hỗ trợ 1 ID tại một thời điểm

---

### 21.1.2 Modes of Operation

| Chế độ | Mô tả |
|--------|-------|
| Asynchronous Mode | Non-burst, single data read/write mỗi access (SRAM) |
| Asynchronous Page Mode | Emulate page mode, burst access với địa chỉ assert cho từng data |
| Multiplexed Address/Data Mode | Address và data dùng chung pins, sync/async, x8/x16 |
| Burst Clock Mode | Synchronous burst read/write, tần số BCLK = EIM clock / 1~4 |
| Low Power Modes | Clock gated khi tất cả CS bị vô hiệu hóa |
| Boot Mode | Boot từ thiết bị ngoài trên CS0 |

---

### 21.1.2.1 Asynchronous Mode
Non-burst, dùng cho SRAM. Mỗi access đọc/ghi một data đơn. Timing điều khiển bởi Chip Select Configuration Registers.

### 21.1.2.2 Asynchronous Page Read Mode
Bit `APR=1` → EIM thực hiện burst bằng cách emulate page mode. Địa chỉ assert cho mỗi data piece. Timing ban đầu theo `RWSC`, các lần tiếp theo theo `PAT`. Page size đặt qua `BL` field: 2, 4, 8, 16, hoặc 32 words.

### 21.1.2.3 Multiplexed Address/Data Mode

#### Bảng 21-1. EIM Multiplexing

| Setup | Non-Muxed 8-bit DSZ=100 | Non-Muxed 8-bit DSZ=101 | Non-Muxed 16-bit DSZ=001 | Non-Muxed 16-bit DSZ=010 | Muxed 16-bit NUM=1, DSZ=001 |
|-------|------------------------|------------------------|--------------------------|--------------------------|----------------------------|
| EIM_ADDR[15:00] | EIM_AD[15:00] | EIM_AD[15:00] | EIM_AD[15:00] | EIM_AD[15:00] | EIM_AD[15:00] |
| EIM_ADDR[26:16] | EIM_ADDR[26:16] | EIM_ADDR[26:16] | EIM_ADDR[26:16] | EIM_ADDR[26:16] | EIM_ADDR[26:16] |
| EIM_DATA[07:00] | EIM_DATA[07:00] | — | EIM_DATA[07:00] | Reserved | EIM_AD[07:00] |
| EIM_DATA[15:08] | — | EIM_DATA[15:08] | EIM_DATA[15:08] | Reserved | EIM_A[15:08] |

### 21.1.2.4 Burst Clock Mode
Tần số BCLK có thể chia 1, 2, 3 hoặc 4 từ EIM clock (tối đa 133 MHz). Hỗ trợ variable và fix latency.
- **Synchronous read**: sau address assertion, burst data được đọc theo BCLK, có thể delay theo `WAIT_B`.
- **Synchronous write**: burst data ghi tới thiết bị, có thể delay theo `WAIT_B` trước data đầu tiên.

---

## 21.2 External Signals

### Bảng 21-2. EIM Important Internal Signals

| Tên | I/O | Mô tả |
|-----|-----|-------|
| EIM_FB_BCLK | Input | Burst Clock Feedback — lấy mẫu read data ở tốc độ cao, căn chỉnh với data từ bộ nhớ ngoài |
| EIM_BOOT | Input | EIM Boot Configuration — xác định reset state của DSZ[1:0] và MUM |
| ACLK | Input | AXI clock, tối đa 133 MHz |
| IPG_CLK_S | Input | EIM module IPG clock |
| RST_B | Input | Active low HW reset |
| EIM_WARM_RESET | Input | Warm Reset (active high) — reset chỉ FF và state machine, giữ nguyên SW registers |

---

## 21.3 Clocks

### Bảng 21-3. EIM Clocks

| Tên Clock | Clock Root | Mô tả |
|-----------|-----------|-------|
| aclk | aclk_eim_slow_clk_root | EIM clock chính (AXI clock), tối đa 133 MHz |
| aclk_slow | aclk_eim_slow_clk_root | EIM all-time running ACLK, dùng cho FF cần active kể cả khi low power |
| ipg_clk_s | ipg_clk_root | Peripheral access clock (IP registers kích hoạt bởi ACLK_SLOW) |
| aclk_exsc | aclk_eim_slow_clk_root | Clock cho thiết bị ngoài, chia nguyên 1/2/3/4 qua BCD bit field |

---

## 21.4 Chip Select Memory Map

Tổng không gian EIM: **128 MB** trong processor memory. Chia cho các CS bởi thanh ghi `IOMUXC_GPR1` (trường `ADDRSn[10]`):

| Cấu hình | CS0 | CS1 | CS2 | CS3 |
|----------|-----|-----|-----|-----|
| Mặc định | 128 MB | 0 MB | 0 MB | 0 MB |
| 2 CS | 64 MB | 64 MB | 0 MB | 0 MB |
| 3 CS | 64 MB | 32 MB | 32 MB | 0 MB |
| 4 CS | 32 MB | 32 MB | 32 MB | 32 MB |

---

## 21.5 Functional Description

### 21.5.2 EIM Operational Modes

#### Bảng 21-4. EIM Operation Modes Field Settings

| MUM | SRD | SWR | Mô tả |
|-----|-----|-----|-------|
| 0 | 0 | 0 | Async write / Async read (APR=0) hoặc Async page read (APR=1), non-muxed |
| 0 | 0 | 1 | Sync write / Async read hoặc page read, non-muxed |
| 0 | 1 | 0 | Async write / Sync read, non-muxed |
| 0 | 1 | 1 | Sync write/read, non-muxed |
| 1 | 0 | 0 | Async write/read, muxed |
| 1 | 0 | 1 | Sync write / Async read, muxed |
| 1 | 1 | 0 | Async write / Sync read, muxed |
| 1 | 1 | 1 | Sync write/read, muxed |

---

### 21.5.7 AXI Burst Cycles Support

#### Bảng 21-5. AXI Burst Cycles Supported

| Burst Length | Burst Size (bytes) | Burst Type | Mô tả |
|-------------|-------------------|------------|-------|
| 1 | 1/2/4 | INCR | Single transfer |
| 2 | 4 | WRAP | 2-beat wrapping burst |
| 4 | 4 | WRAP | 4-beat wrapping burst |
| 8 | 4 | WRAP | 8-beat wrapping burst |
| 16 | 4 | WRAP | 16-beat wrapping burst |
| 2–16 | 4 | INCR | 2–16 beat incrementing burst |

#### Bảng 21-6. AXI to Memory Burst Splits Number

| AXI Burst Type | Memory Burst Config | Số access (x8) | Số access (x16) | Số access (x32) |
|---------------|--------------------:|---------------:|----------------:|----------------:|
| INC16 Aligned | WRAP4 | 16 | 8 | 4 |
| INC16 Aligned | Cont. | 1 | 1 | 1 |
| INC16 Unaligned | WRAP4 | 17 | 9 | 5 |
| INC16 Unaligned | Cont. | 1 | 1 | 1 |
| WRAP16 Aligned | WRAP16 | 4 | 2 | 1 |
| WRAP16 Aligned | Cont. | 1 | 1 | 1 |
| WRAP16 Unaligned | WRAP16 | 5 | 3 | 1 |
| WRAP16 Unaligned | Cont. | 2 | 2 | 2 |
| INC8 Aligned | WRAP8 | 4 | 2 | 1 |
| INC8 Aligned | WRAP16 | 2 | 1 | 1 |
| INC8 Unaligned | WRAP8 | 4 hoặc 5 | 2 hoặc 3 | 2 |
| INC8 Unaligned | WRAP16 | 2 hoặc 3 | 2 | 1 hoặc 2 |
| WRAP8 Aligned | WRAP16 | 2 | 1 | 1 |
| WRAP8 Aligned | Cont. | 1 | 1 | 1 |
| WRAP8 Unaligned | WRAP16 | 2 hoặc 3 | 1 | 2 |
| WRAP8 Unaligned | Cont. | 2 | 2 | 2 |

---

### 21.5.17 Endianness

#### Bảng 21-7. EIM Data khi AXI data = 0xB3B2B1B0

| Endian | AXI Access | AXI addr[1:0] | Word port [31:24] | [23:16] | [15:8] | [7:0] | Half word port ext. addr[0] | [31:24]/[15:8] | [23:16]/[7:0] | Byte port ext. addr[1:0] | [31:24~7:0] |
|--------|-----------|--------------|-----------------|---------|--------|-------|-----------------------------|---------------|--------------|--------------------------|-------------|
| **Big** | Word | 0 | 0xB3 | 0xB2 | 0xB1 | 0xB0 | 0 | 0xB3 | 0xB2 | 0→0xB3, 1→0xB2, 2→0xB1, 3→0xB0 | — |
| **Big** | Half Word | 0 | 0xB1 | 0xB0 | — | — | 0 | 0xB3 | 0xB2 | 0→0xB3, 1→0xB2, 2→0xB1, 3→0xB0 | — |
| **Big** | Byte | 0 | 0xB0 | — | — | — | 0 | 0xB3 | — | 0→0xB3, 1→0xB2, 2→0xB1, 3→0xB0 | — |
| **Little** | Word | 0 | 0xB3 | 0xB2 | 0xB1 | 0xB0 | 0 | 0xB1 | 0xB0 | 0→0xB0, 1→0xB1, 2→0xB2, 3→0xB3 | — |
| **Little** | Half Word | 0 | 0xB1 | 0xB0 | — | — | 0 | 0xB1 | 0xB0 | 0→0xB0, 1→0xB1, 2→0xB2, 3→0xB3 | — |
| **Little** | Byte | 0 | 0xB0 | — | — | — | 0 | 0xB0 | — | 0→0xB0, 1→0xB1, 2→0xB2, 3→0xB3 | — |

---

## 21.7 Typical Application

### 21.7.8 8-bit Support

#### Bảng 21-8. Intel Mode Pin Connections

| ARM Platform Pin | EIM Pin | Ghi chú |
|-----------------|---------|---------|
| ADS# | IPP_DO_ADV_B | WAL=1, RAL=1 |
| W/R | IPP_DO_BE_B | WBED=1 |
| WR# | WE# | — |
| RD# | OE# | — |

#### Bảng 21-9. Motorola Mode Pin Connections

| ARM Platform Pin | EIM Pin | Ghi chú |
|-----------------|---------|---------|
| AS# | IPP_DO_CS_B | — |
| R/W# | WE# | — |
| LDS# | BE# | — |

---

## 21.8 External Bus Timing Diagrams

### 21.8.1 Asynchronous Read (Hình 21-2)
```
EIM clk   ____‾‾‾‾____‾‾‾‾____‾‾‾‾____‾‾‾‾____‾‾‾‾____
ARVALID   ___‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾____________
ADDR      ________[  Valid Address                     ]
CSo       ___‾‾‾‾‾‾[___________________________]‾‾‾‾‾‾
ADV       ___‾‾‾‾[__]‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
OE        ________[_____________________________]‾‾‾‾
DATA_IN   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~[Valid]
          |<------------ RWSC=2 cycles ------------->|
```
*RWSC=2, RCSA=0, OEA=0, RCSN=0, OEN=0, RAL=1*

---

### 21.8.2 Asynchronous Write (Hình 21-3)
```
EIM clk   ____‾‾‾‾____‾‾‾‾____‾‾‾‾____‾‾‾‾____‾‾‾‾
ADDR      [  Valid Address                         ]
CSo       ‾‾‾[_____________________________________]‾
WE        ‾‾‾‾‾‾[_______________________________]‾‾
ADV       ‾‾[__]‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
DATA_OUT  ~~~[          Valid Write Data          ]
          |<----------- WWSC=2 cycles ------------->|
```
*WWSC=2, WCSA=0, WEA=0, WCSN=0, WEN=0, BEA=0, BEN=0, WAL=1*

---

### 21.8.3 Read/Write Timing với RCSA, WCSA, CSREC (Hình 21-4 & 21-5)

```
EIM CLK   ____‾‾‾‾____‾‾‾‾____‾‾‾‾....____‾‾‾‾____‾‾‾‾
ADDR      [RD Address          ]     [WR Address        ]
CSo       ‾[RCSA][___RWSC___][RCSN]‾ [CSREC][WCSA][WWSC][WCSN]
ADV       [RADVA][__][RADVN+1]        [WADVA][___][WADVN+1]
OE        [OEA][_______][OEN]
BE        [BEA][__________][BEN]
DATA_IN   ~~~~~~~~~~~~~~[Read Data]
DATA_OUT  ~~~~~~~~~~~~~~~~~~~~~~~~~~[Write Data]
```
*Các tham số RCSA, RCSN, RADVA, RADVN, OEA, OEN, WCSA, WCSN, WADVA, WADVN, BEA, BEN điều chỉnh timing từng tín hiệu*

---

### 21.8.4 Read/Write với RAL, WAL và CSREC (Hình 21-6)

```
EIM CLK  ___‾‾‾___‾‾‾___‾‾‾....
ADDR     [RD Addr  ]    [WR Addr  ]
CSo      ‾[RCSA][__RWSC__][RCSN][CSREC][WCSA][__WWSC__][WCSN]
ADV      [RADVA][_____RAL=1: giữ đến hết access_____]
         (WAL=1: ADV giữ đến hết write access)
OE       [OEA][________________________]
BE       [BEA][___][BEN]
DATA_IN  ~~~~~~~~~[Read Data]
DATA_OUT ~~~~~~~~~~~~~~~~~[Write Data]
```
*RAL=1: ADV giữ đến hết read access; WAL=1: ADV giữ đến hết write access*

---

### 21.8.5 Consecutive Async Write (Hình 21-7, 21-8, 21-9)

```
Hình 21-7 (CSREC=0 — không có recovery):
EIM CLK  ___‾‾‾___‾‾‾...___‾‾‾
ADDR     [Addr0     ][Addr1     ]
CSo      ‾[__WWSC__]‾[__WWSC__]‾
WE       ‾[________]‾[________]‾
DATA_OUT [WD0       ][WD1      ]

Hình 21-8 (CSREC=2 — có recovery cycles):
EIM CLK  ___‾‾‾___‾‾‾...___‾‾‾
ADDR     [Addr0     ][Addr1    ]
CSo      ‾[__WWSC__][CSREC][__WWSC__]‾
WE       ‾[________]‾      [________]‾
DATA_OUT [WD0      ]        [WD1     ]

Hình 21-9 (WCSA, WEA, WADVA, WADVN, BEA, BEN ≠ 0):
CSo      ‾[WCSA][___WWSC___][WCSN]
WE         ‾[WEA][____][WEN]
ADV      [WADVA][__][WADVN+WADVA+1]
BE           [BEA][_________][BEN]
```

---

### 21.8.6 Consecutive Async Read (Hình 21-10, 21-11)

```
Hình 21-10 (CSREC=0):
EIM CLK  ‾‾‾___‾‾‾...___‾‾‾
ADDR     [Addr0      ][Addr1     ]
CSo      ‾[__RWSC___]‾[__RWSC__]‾
OE       ‾[_________]‾[________]‾
DATA_IN  ~[RData0   ]~[RData1  ]

Hình 21-11 (CSREC=2):
CSo      ‾[__RWSC__][CSREC][__RWSC__]‾
OE       ‾[________]‾      [________]‾
DATA_IN  ~[RData0  ]        [RData1 ]
```

---

### 21.8.7–21.8.8 Burst (Sync) Read — BCD=0 và BCD=1

```
BCD=0 (Hình 21-12) — BCLK = EIM clock tần số đầy đủ:
EIM CLK  ‾‾‾___‾‾‾___‾‾‾___
BCLK     ‾‾‾___‾‾‾___‾‾‾___  (cùng tần số với EIM CLK)
ADDR     [Address            ]
CS       ‾[__________________]‾
ADV      ‾[__]‾‾‾‾‾‾‾‾‾‾‾‾‾
DATA_IN  ~~~[D0][D1][D2][D3]
         |RWSC=1|

BCD=1 (Hình 21-13) — BCLK = EIM clock / 2:
EIM CLK  ‾___‾___‾___‾___‾___‾___‾___‾___
BCLK     ‾‾‾‾____‾‾‾‾____‾‾‾‾____‾‾‾‾____  (tần số / 2)
ADDR     [Address                        ]
CS       ‾[______________________________]‾
ADV      ‾[____]‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
DATA_IN  ~~~~~~~~~~~[D0  ][D1  ][D2  ][D3]
         |<-- RL=3 latency -->|
```
*SRD=1, BCS=0, RADVA=0, RADVN=0, RFL=0*

---

### 21.8.9 Burst (Sync) Write — BCD=1 (Hình)

```
EIM clock  ‾___‾___‾___‾___‾___‾___‾___
awvalid    ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾___________
awready    ‾‾‾‾‾‾‾‾‾‾‾‾‾‾[‾‾‾‾]____________
BCLK       ________‾‾‾‾____‾‾‾‾____‾‾‾‾____
CS         ____[_________________________________]____
WR         ______[_________________________________]__
ADV        ____[__]________________________________
ADDR       ________[  Address                   ]
DATA_OUT   ________________[D1    ][D2           ]
WAIT       __________________________[‾‾‾‾‾‾]______
```

---

### 21.8.10 Asynchronous Page Mode (Hình 21-14, PAT=2)

```
ACLK     ‾___‾___‾___‾___‾___‾___...
ADDR     [Last Addr][A0  ][A1  ][A2  ][A3  ]
CSo      ‾[_______________________________________]‾
ADV      ‾[__]‾[__]‾[__]‾[__]‾[__]‾‾‾‾‾‾‾‾‾‾‾‾
OE       ‾‾‾‾‾[_________________][OEA]
DATA_IN  ~~~~~~~~~~[RD0][RD1][RD2][RD3]
         |RWSC |PAT|PAT|PAT|
```
*APR=1, PAT=2 — mỗi lần đọc tiếp theo mất 2 EIM cycles*

---

### 21.8.11–21.8.13 DTACK Mode (Hình 21-15 đến 21-19)

```
DTACK Single Read (DAPS=2):
ACLK    ‾___‾___‾___‾___‾___‾___‾___
ADDR    [Last Valid Addr][Address V1 ]
CSo     ‾‾‾‾‾‾‾‾‾‾‾‾‾‾[_____________]‾
ADV     ‾‾‾‾‾‾‾‾‾‾‾‾‾‾[__]‾‾‾‾‾‾‾‾‾
OE      ‾‾‾‾‾‾‾‾‾‾‾‾‾‾[_____________]‾
DTACK  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾[____]‾
DATA_IN ~~~~~~~~~~~~~~~~~~~~~~~~~~[V1]
        |<DAPS=2>|<--Sync Time-->|

DTACK Burst Access (DAPS=2, CSREC=2):
Mỗi word trong burst được xử lý như single access
CS được negate giữa các lần (CSREC field)
```

---

## 21.9 EIM Memory Map / Register Definition

### EIM Memory Map

| Địa chỉ (hex) | Tên Register | Width | Access | Reset Value |
|--------------|-------------|-------|--------|-------------|
| `21B_8000` | EIM_CS0GCR1 | 32 | R/W | `0001_0080h` |
| `21B_8004` | EIM_CS0GCR2 | 32 | R/W | `0000_1000h` |
| `21B_8008` | EIM_CS0RCR1 | 32 | R/W | `0000_0000h` |
| `21B_800C` | EIM_CS0RCR2 | 32 | R/W | `0000_0000h` |
| `21B_8010` | EIM_CS0WCR1 | 32 | R/W | `0000_0000h` |
| `21B_8014` | EIM_CS0WCR2 | 32 | R/W | `0000_0000h` |
| `21B_8018` | EIM_CS1GCR1 | 32 | R/W | `0001_0080h` |
| `21B_801C` | EIM_CS1GCR2 | 32 | R/W | `0000_1000h` |
| `21B_8020` | EIM_CS1RCR1 | 32 | R/W | `0000_0000h` |
| `21B_8024` | EIM_CS1RCR2 | 32 | R/W | `0000_0000h` |
| `21B_8028` | EIM_CS1WCR1 | 32 | R/W | `0000_0000h` |
| `21B_802C` | EIM_CS1WCR2 | 32 | R/W | `0000_0000h` |
| `21B_8030–804C` | EIM_CS2GCR1–WCR2 | 32 | R/W | Tương tự CS1 |
| `21B_8048–805C` | EIM_CS3GCR1–WCR2 | 32 | R/W | Tương tự CS1 |
| `21B_8060–8074` | EIM_CS4GCR1–WCR2 | 32 | R/W | Tương tự CS1 |
| `21B_8078–808C` | EIM_CS5GCR1–WCR2 | 32 | R/W | Tương tự CS1 |
| `21B_8090` | EIM_WCR | 32 | R/W | Xem mục 21.9.7 |

> Mỗi CS có 6 registers; CS0 bắt đầu tại `0x21B_8000`, mỗi CS cách nhau `24d` (0x18) bytes.

---

### 21.9.1 EIM_CSnGCR1 — Chip Select General Configuration Register 1

**Địa chỉ:** `21B_8000h + 0h + (24d × i)`, i = 0–5

| Bits | Tên | Reset | Mô tả |
|------|-----|-------|-------|
| [31:28] | PSZ | 0000 | Page Size (words): `0000`=8, `0001`=16, `0010`=32, `0011`=64, `0100`=128, `0101`=256, `0110`=512, `0111`=1024, `1000`=2048 |
| [27] | WP | 0 | Write Protect: `0`=Writes allowed · `1`=Writes prohibited |
| [26:24] | GBC | 000 | Gap Between Chip Selects: 0–7 EIM clock cycles trước access từ CS khác |
| [23] | AUS | 0 | Address UnShifted: `0`=Shifted (128MB max) · `1`=Unshifted (32MB max) |
| [22:20] | CSREC | 110* | CS Recovery: 0–7 EIM clock cycles pulse width CS/OE/WE tối thiểu |
| [19] | SP | 0 | Supervisor Protect: `0`=User access allowed · `1`=User access prohibited |
| [18:16] | DSZ | 001* | Data Port Size: `001`=16-bit DATA[15:0] · `010`=16-bit DATA[31:16] · `011`=32-bit · `100`=8-bit DATA[7:0] · `101`=8-bit DATA[15:8] · `110`=8-bit DATA[23:16] · `111`=8-bit DATA[31:24] |
| [15:14] | BCS | 00 | Burst Clock Start: 0–3 EIM clock cycles delay trước BCLK edge đầu tiên |
| [13:12] | BCD | 00 | Burst Clock Divisor: `00`=÷1 · `01`=÷2 · `10`=÷3 · `11`=÷4 |
| [11] | WC | 0 | Write Continuous: `0`=Theo BL · `1`=Continuous |
| [10:8] | BL | 000 | Burst Length: `000`=4 words · `001`=8 · `010`=16 · `011`=32 · `100`=Continuous |
| [7] | CREP | 1 | CRE Polarity: `0`=Active low · `1`=Active high |
| [6] | CRE | 0 | CRE Enable: `0`=Disable · `1`=Enable |
| [5] | RFL | 0 | Read Fix Latency: `0`=Monitor WAIT signal · `1`=Fix latency |
| [4] | WFL | 0 | Write Fix Latency: `0`=Monitor WAIT signal · `1`=Fix latency |
| [3] | MUM | 0* | Multiplexed Mode: `0`=Disable · `1`=Enable |
| [2] | SRD | 0 | Synchronous Read: `0`=Async · `1`=Sync |
| [1] | SWR | 0 | Synchronous Write: `0`=Async · `1`=Sync |
| [0] | CSEN | 1** | CS Enable: `0`=Disabled · `1`=Enabled |

> \* Reset value cho CS0: CSREC=0b110, DSZ[2]=0, DSZ[1:0]=EIM_BOOT[1:0], MUM=EIM_BOOT[2]
> \*\* CS0: CSEN=1; CS1–CS5: CSEN=0

---

### 21.9.2 EIM_CSnGCR2 — Chip Select General Configuration Register 2

**Địa chỉ:** `21B_8000h + 4h + (24d × i)`

| Bits | Tên | Reset | Mô tả |
|------|-----|-------|-------|
| [31:13] | Reserved | 0 | — |
| [12] | MUX16_BYP_GRANT | 0 | Muxed 16 bypass grant: `0`=Chờ grant · `1`=Bỏ qua grant, drive ngay |
| [11:10] | Reserved | 0 | — |
| [9] | DAP | 0 | DTACK Polarity: `0`=Active high · `1`=Active low |
| [8] | DAE | 0 | DTACK Enable: `0`=Disable · `1`=Enable |
| [7:4] | DAPS | 0000 | DTACK Polling Start: bắt đầu từ (DAPS+3) EIM cycles sau start of access (`0000`=3, `0001`=4, ... `1111`=18) |
| [3:2] | Reserved | 0 | — |
| [1:0] | ADH | 10* | Address Hold: 0–2 cycles sau ADV negation (chỉ khi MUM=1) |

> \* CS0: ADH=10; CS1–CS5: ADH=00

---

### 21.9.3 EIM_CSnRCR1 — Chip Select Read Configuration Register 1

**Địa chỉ:** `21B_8000h + 8h + (24d × i)`

| Bits | Tên | Reset | Mô tả |
|------|-----|-------|-------|
| [31:30] | Reserved | 0 | — |
| [29:24] | RWSC | 0b011100* | Read Wait State Control: 1–63 EIM/BCLK cycles (sync: từ start đến sample data; async: độ dài access) |
| [23] | Reserved | 0 | — |
| [22:20] | RADVA | 000 | ADV Assertion: 0–7 cycles từ đầu access đến ADV assert |
| [19] | RAL | 0 | Read ADV Low: `0`=Negation theo RADVN · `1`=ADV giữ đến hết access |
| [18:16] | RADVN | 010* | ADV Negation: (RADVN+RADVA+1) cycles async; (RADVN+RADVA+BCD+BCS+1) cycles sync |
| [15] | Reserved | 0 | — |
| [14:12] | OEA | 000* | OE Assertion: 0–7 cycles từ đầu access |
| [11] | Reserved | 0 | — |
| [10:8] | OEN | 000 | OE Negation: 0–7 cycles từ cuối access (chỉ async single, SRD=0) |
| [7] | Reserved | 0 | — |
| [6:4] | RCSA | 000 | Read CS Assertion: 0–7 cycles từ đầu read access |
| [3] | Reserved | 0 | — |
| [2:0] | RCSN | 000 | Read CS Negation: 0–7 cycles từ cuối read access (chỉ async single, SRD=0) |

> \* Reset CS0: RWSC=0b011100, RADVN=2, OEA=0 (EIM_BOOT[2]=0) hoặc 2 (EIM_BOOT[2]=1)

---

### 21.9.4 EIM_CSnRCR2 — Chip Select Read Configuration Register 2

**Địa chỉ:** `21B_8000h + Ch + (24d × i)`

| Bits | Tên | Reset | Mô tả |
|------|-----|-------|-------|
| [31:16] | Reserved | 0 | — |
| [15] | APR | 0 | Async Page Read: `0`=Single word · `1`=Page read mode (SRD=0, MUM=0 required) |
| [14:12] | PAT | 000 | Page Access Time: 2–9 EIM cycles (`000`=2, `001`=3, ... `111`=9) — chỉ khi APR=1 |
| [11:10] | Reserved | 0 | — |
| [9:8] | RL | 00 | Read Latency: feedback clock loop delay: `00`=1(BCD=0)/1.5 cycles · `01`=2/2.5 · `10`=3/3.5 · `11`=4/4.5 |
| [7] | Reserved | 0 | — |
| [6:4] | RBEA | 000 | Read BE Assertion: 0–7 cycles từ đầu read access |
| [3] | RBE | 0 | Read BE Enable: `0`=Disabled · `1`=Enabled |
| [2:0] | RBEN | 000 | Read BE Negation: 0–7 cycles từ cuối read access (chỉ async single) |

---

### 21.9.5 EIM_CSnWCR1 — Chip Select Write Configuration Register 1

**Địa chỉ:** `21B_8000h + 10h + (24d × i)`

| Bits | Tên | Reset | Mô tả |
|------|-----|-------|-------|
| [31] | WAL | 0 | Write ADV Low: `0`=Negation theo WADVN · `1`=ADV giữ đến hết write access |
| [30] | WBED | 0 | Write Byte Enable Disable: ngăn IPP_DO_BE_B assert trong write |
| [29:24] | WWSC | 0b011100* | Write Wait State Control: 1–63 EIM/BCLK cycles |
| [23:21] | WADVA | 000 | ADV Assertion: 0–7 cycles từ đầu access |
| [20:18] | WADVN | 010* | ADV Negation: (WADVN+WADVA+1) async; (WADVN+WADVA+BCD+BCS+1) sync |
| [17:15] | WBEA | 010* | BE Assertion: 0–7 cycles từ đầu access (chỉ async, SWR=0) |
| [14:12] | WBEN | 010* | BE[3:0] Negation: 0–7 cycles từ cuối access (chỉ async, SWR=0) |
| [11:9] | WEA | 010* | WE Assertion: 0–7 cycles từ đầu write cycle |
| [8:6] | WEN | 010* | WE Negation: 0–7 cycles từ đầu access (chỉ async, SWR=0) |
| [5:3] | WCSA | 000 | Write CS Assertion: 0–7 cycles từ đầu write access |
| [2:0] | WCSN | 000 | Write CS Negation: 0–7 cycles từ cuối write access (chỉ async, SWR=0) |

> \* Reset CS0: WWSC=0b011100, WADVN=2, WBEA=2, WBEN=2, WEA=2, WEN=2; CS1–CS5: tất cả = 0

---

### 21.9.6 EIM_CSnWCR2 — Chip Select Write Configuration Register 2

**Địa chỉ:** `21B_8000h + 14h + (24d × i)`

| Bits | Tên | Reset | Mô tả |
|------|-----|-------|-------|
| [31:1] | Reserved | 0 | — |
| [0] | WBCDD | 0 | Write Burst Clock Divisor Decrement: nếu set và BCD=0, sync write thực hiện như BCD=1 |

---

### 21.9.7 EIM_WCR — EIM Configuration Register

**Địa chỉ:** `21B_8090h`

| Bits | Tên | Reset | Mô tả |
|------|-----|-------|-------|
| [31:12] | Reserved | 0 | — |
| [11] | FRUN_ACLK_EN | 0 | Free run ACLK enable |
| [10:9] | WDOG_LIMIT | 10 | Watchdog cycle limit: `00`=128 · `01`=256 · `10`=512 · `11`=1024 BCLK cycles |
| [8] | WDOG_EN | 0 | Memory WDOG enable: `0`=Disabled · `1`=Enabled |
| [7:6] | Reserved | 0 | — |
| [5] | INTPOL | 0 | Interrupt Polarity: `0`=Active low · `1`=Active high |
| [4] | INTEN | 0 | Interrupt Enable: `0`=Disable · `1`=Enable |
| [3] | CONT_BCLK_SEL | 0 | Continuous BCLK: `0`=Chỉ khi cần · `1`=Liên tục |
| [2:1] | GBCD | 00 | General Burst Clock Divisor (khi BCM=1): `00`=÷1 · `01`=÷2 · `10`=÷3 · `11`=÷4 |
| [0] | BCM | 0 | Burst Clock Mode (debug): `0`=Chạy khi SWR/SRD set · `1`=Chạy liên tục theo ACLK |

---

## 21.7 Typical Application — Ví dụ cấu hình

### 21.7.1 Intel Sibley Flash

#### Async Mode
```c
WR32('EIM_CS0GCR1, 'h00210081);
WR32('EIM_CS0RCR1, 'h0e020000);
WR32('EIM_CS0RCR2, 'h00000000);
WR32('EIM_CS0WCR1, 'h0704a040);
```

#### Sync Mode 133 MHz (non-muxed)
```c
WR16('CS0+('h5903<<1), 'h0060);  // Set memory to sync read
WR16('CS0+('h5903<<1), 'h0003);
WR16('CS0+('h0000<<1), 'h00ff);
WR32('EIM_CS0GCR1, 'h50214225); // 133 MHz
WR32('EIM_CS0RCR1, 'h0c000000); // 12 cycles
```

#### Sync Mode 66 MHz (muxed)
```c
WR32('EIM_CS0GCR1, 'h5021122d); // 66 MHz
WR32('EIM_CS0RCR1, 'h07000000); // 7 cycles
```

---

### 21.7.3 Micron PSRAM — Async/Sync

#### Async 16-bit
```c
WR32('EIM_CS0GCR1, 'h403104b1);
WR32('EIM_CS0RCR1, 'h0b010000);
WR32('EIM_CS0RCR2, 'h00000008);
WR32('EIM_CS0WCR1, 'h0b040040);
```

#### Sync 16-bit (fixed latency, wrap 4)
```c
WR32('EIM_CS0GCR1, 'h4021_5487);
WR32('EIM_CS0RCR1, 'h04000000);
WR32('EIM_CS0WCR1, 'h04000000);
```

---

### 21.7.4 Samsung OneNAND

#### Async Non-muxed
```c
WR32('EIM_CS0GCR1, 'h00410081);
WR32('EIM_CS0RCR1, 'h0b010000);
WR32('EIM_CS0WCR1, 'h0c092480);
```

#### Sync Read 44 MHz (non-muxed)
```c
WR16('CS0+('hF221<<1), 'hc0e0);  // Sync read, 4 clk latency
WR32('EIM_CS0GCR1, 'h50412405); // 44 MHz
WR32('EIM_CS0RCR1, 'h05010000);
```

---

### 21.7.6 Spansion Flash

#### Async
```c
WR32('EIM_CS0GCR1, 'h00410081);
WR32('EIM_CS0RCR1, 'h0a018000);
WR32('EIM_CS0WCR1, 'h0704a240);
```

#### Sync 66 MHz
```c
WR32('EIM_CS0GCR1, 'h50411325); // 66 MHz
WR32('EIM_CS0RCR1, 'h05000000); // 5 cycles
```

---

*Tài liệu được chuyển đổi từ Chapter 21 — i.MX 6ULL Applications Processor Reference Manual, Rev. 1, 11/2017, NXP Semiconductors.*