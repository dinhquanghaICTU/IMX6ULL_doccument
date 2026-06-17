# Chương 58 – Ultra Secured Digital Host Controller (uSDHC)

---

## 58.1 Tổng quan

**Ultra Secured Digital Host Controller (uSDHC)** cung cấp giao diện giữa hệ thống host và các thẻ SD/SDIO/MMC.

uSDHC hoạt động như một cầu nối, chuyển tiếp các giao dịch bus host đến các thẻ SD/SDIO/MMC bằng cách gửi lệnh và thực hiện truy cập dữ liệu đến/từ thẻ. Nó xử lý các giao thức SD/SDIO/MMC ở tầng truyền dẫn.

### Các loại thẻ được hỗ trợ

| Loại thẻ | Mô tả |
|-----------|-------|
| **MMC (Multi Media Card)** | Phương tiện lưu trữ và truyền thông dữ liệu chi phí thấp, phổ quát. Thế hệ mới dùng bus nối tiếp 11 chân tốc độ cao, hoạt động ở dải điện áp thấp. |
| **SD (Secure Digital Card)** | Phát triển từ công nghệ MMC cũ. Thiết kế đáp ứng yêu cầu bảo mật, dung lượng, hiệu năng cho thiết bị điện tử tiêu dùng âm thanh/video. Form factor và giao thức tương thích ngược với MMC. |
| **SDIO Card** | Cung cấp I/O dữ liệu tốc độ cao với tiêu thụ điện năng thấp cho thiết bị điện tử di động. |

### Sơ đồ kết nối hệ thống uSDHC

```
┌─────────────────────────────────────────────────────────┐
│                    AHB Bus / IP Bus                      │
│                                                         │
│   ┌──────────────────────────────────────────────────┐  │
│   │         MMC/SD/SDIO Host Controller              │  │
│   │                                                  │  │
│   │  ┌─────────────┐     ┌────────────────────────┐  │  │
│   │  │ DMA Interface│     │       IP Bus           │  │  │
│   │  └──────┬───────┘     └────────────────────────┘  │  │
│   │         │                                          │  │
│   │  ┌──────▼───────────────────────────────────────┐ │  │
│   │  │              Transceiver                      │ │  │
│   │  └──────────────────────┬───────────────────────┘ │  │
│   └─────────────────────────┼────────────────────────┘  │
│                             │                           │
│                    ┌────────▼────────┐                  │
│                    │   Card Slot     │                  │
│                    │ ┌─────────────┐ │                  │
│                    │ │  MMC card   │ │                  │
│                    │ │  SD card    │ │                  │
│                    │ │  SDIO card  │ │                  │
│                    │ └─────────────┘ │                  │
│                    └─────────────────┘                  │
│                                                         │
│  [AHB Bus]  [IP Bus]  [Power Supply]                    │
└─────────────────────────────────────────────────────────┘
```

### Sơ đồ khối uSDHC

```
                    usdhc_clk_root
                          │
               ┌──────────▼──────────┐
               │       /M /N         │
               └──────────┬──────────┘
                          │
           ┌──────────────▼───────────────────────────────┐
           │         CLK(output) Domain                    │
           │                                               │
           │  ┌───────┐  ref_clk ┌─────┐                  │
           │  │  /2   │◄─────────│ DLL │                  │
           │  └───┬───┘          └─────┘                  │
           │      │                                        │
           │  ┌───▼─────────────────────────────────────┐ │
           │  │  Rising Edge    Falling Edge             │ │
           │  │  Async FIFO     Async FIFO               │ │
           │  └───────────────────────────────────────── ┘ │
           └──────────────────────────────────────────────-┘

┌──────────────────────────────────────────────────────────────┐
│          ipg_clk / ipg_clk_s / ahb_clk domain               │
│                                                              │
│  ┌──────────┐   ┌─────────────────────────────────────────┐ │
│  │  AHB Bus │   │            Register Bank                │ │
│  └────┬─────┘   │  ┌──────────┐  ┌──────────┐            │ │
│       │         │  │ CMD CTRL │  │DATA CTRL │            │ │
│  ┌────▼─────┐   │  └──────────┘  └──────────┘            │ │
│  │   DMA    │   │  ┌──────────┐                           │ │
│  │  Buffer  │   │  │CLK CTRL  │  IRQ ──────────────────►  │ │
│  │  Control │   │  └──────────┘                           │ │
│  └────┬─────┘   └─────────────────────────────────────────┘ │
│       │                                                      │
│  ┌────▼────────────────────────────────┐                    │
│  │   SRAM (128×32bit)                  │                    │
│  │   TX buffer    RX buffer            │                    │
│  └────────────────────────────────────-┘                    │
│                                                              │
│   IPS Bus ◄──────────────────────────► PIO                  │
└──────────────────────────────────────────────────────────────┘

                    CMD(output)
                    DAT[7:0](output)
                    CLK(output)
              ────────────────────────────►  Card
```

---

## 58.1.1 Tính năng

- Tuân thủ **SD Host Controller Standard Specification version 3.0**
- Tương thích **MMC System Specification version 4.2/4.3/4.4/4.41/4.5**
- Tương thích **SD Memory Card Specification version 3.0**, hỗ trợ Extended Capacity SD Memory Card
- Tương thích **SDIO Card Specification version 3.0**
- Hỗ trợ: SD Memory, miniSD Memory, SDIO, miniSDIO, SD Combo, MMC, MMC plus, MMC RS
- Tần số clock bus thẻ lên đến **208 MHz** trong mode SD/SDIO UHS-I SDR104
- Hỗ trợ chế độ **1-bit / 4-bit SD và SDIO**, chế độ **1-bit / 4-bit / 8-bit MMC**

| Card / Chế độ | Clock tham chiếu | Cách tính | Tốc độ lý thuyết |
|---------------|------------------|-----------|------------------|
| SD/SDIO 4-bit high-speed SDR | 50 MHz | `50 MHz × 4 × 1` | 200 Mbit/s = 25 MB/s |
| SD/SDIO 4-bit UHS-I SDR104 | 208 MHz | `208 MHz × 4 × 1` | 832 Mbit/s = 104 MB/s |
| SD/SDIO 4-bit UHS-I DDR50 | 50 MHz | `50 MHz × 4 × 2` | 400 Mbit/s = 50 MB/s |
| MMC/eMMC 8-bit SDR | 52 MHz | `52 MHz × 8 × 1` | 416 Mbit/s = 52 MB/s |
| MMC/eMMC 8-bit DDR | 52 MHz | `52 MHz × 8 × 2` | 832 Mbit/s = 104 MB/s |

> Lưu ý: `DDR` chỉ nhanh gấp đôi nếu so cùng clock. SD/SDIO DDR50 dùng clock 50 MHz nên đạt 400 Mbit/s, còn SD/SDIO SDR104 dùng clock 208 MHz nên đạt 832 Mbit/s.

- Hỗ trợ đọc/ghi **single block / multi-block**
- Hỗ trợ kích thước block từ **1 đến 4096 byte**
- Hỗ trợ công tắc bảo vệ ghi (write protection switch)
- Hỗ trợ abort đồng bộ và không đồng bộ
- Hỗ trợ tạm dừng truyền dữ liệu tại block gap
- Hỗ trợ SDIO **Read Wait** và **Suspend Resume**
- Hỗ trợ **Auto CMD12** cho multi-block transfer
- Host có thể phát lệnh non-data trong khi đang truyền dữ liệu
- Cho phép thẻ ngắt host ở chế độ **1-bit và 4-bit SDIO**
- FIFO **128×32-bit** hoàn toàn cấu hình được cho dữ liệu đọc/ghi
- Hỗ trợ **DMA nội bộ và ngoài**
- Hỗ trợ chọn điện áp qua thanh ghi vendor specific
- Hỗ trợ **Advanced DMA** để thực hiện truy cập bộ nhớ liên kết

---

## 58.1.2 Chế độ và hoạt động

### 58.1.2.1 Chế độ truyền dữ liệu

| Chế độ | Tần số tối đa |
|--------|--------------|
| SD 1-bit | — |
| SD 4-bit | — |
| MMC 1-bit | — |
| MMC 4-bit | — |
| MMC 8-bit | — |
| Identification Mode | 400 kHz |
| MMC full speed | 26 MHz |
| MMC high speed | 52 MHz |
| MMC HS200 | 200 MHz |
| MMC DDR | 52 MHz (cả 2 cạnh) |
| SD/SDIO full speed | 25 MHz |
| SD/SDIO high speed | 50 MHz |
| SD/SDIO UHS-I SDR | 208 MHz |
| SD/SDIO UHS-I DDR | 50 MHz |

---

## 58.2 Tín hiệu ngoài

### 58.2.1 Tổng quan tín hiệu

uSDHC có 14 tín hiệu I/O liên quan:

- **CLK**: Clock được tạo nội bộ để điều khiển thẻ MMC, SD, SDIO
- **CMD I/O**: Gửi lệnh và nhận phản hồi đến/từ thẻ
- **DAT[7:0]**: 8 đường dữ liệu để truyền dữ liệu giữa uSDHC và thẻ
- **CD (Card Detect)**: Phát hiện thẻ, tích cực mức thấp (0 = thẻ đã cắm)
- **WP (Write Protect)**: Bảo vệ ghi, tích cực mức cao (1 = write protect đang hoạt động)
- **LCTL**: Tín hiệu output điều khiển LED ngoài chỉ thị SD interface bận
- **RST**: Tín hiệu output để reset thẻ MMC
- **VSELECT**: Tín hiệu output thay đổi điện áp nguồn ngoài

> **Lưu ý**: CD, WP, LCTL, RST và VSELECT đều tùy chọn trong triển khai hệ thống. Nếu uSDHC cần hỗ trợ truyền dữ liệu 4-bit, DAT[7:4] cũng có thể tùy chọn và kéo lên cao.

### Bảng tín hiệu ngoài USDHC

| Tín hiệu | Mô tả | Pad Mode | Hướng |
|----------|-------|----------|-------|
| SD1_CD_B | Phát hiện thẻ. Nếu không dùng (bộ nhớ nhúng), kéo xuống thấp | CSI_DATA05 ALT8 / GPIO1_IO03 ALT4 / UART1_RTS_B ALT2 | I |
| SD1_CLK | Clock cho thẻ MMC/SD/SDIO | SD1_CLK ALT0 | O |
| SD1_CMD | Đường CMD kết nối đến thẻ | SD1_CMD ALT0 | IO |
| SD1_DATA0 | Đường DATA0 ở mọi chế độ, phát hiện trạng thái busy | SD1_DATA0 ALT0 | IO |
| SD1_DATA1 | Đường DATA1 ở chế độ 4/8-bit; phát hiện ngắt ở chế độ 1/4-bit | SD1_DATA1 ALT0 | IO |
| SD1_DATA2 | Đường DATA2 hoặc Read Wait ở chế độ 4-bit | SD1_DATA2 ALT0 | IO |
| SD1_DATA3 | Đường DATA3 ở chế độ 4/8-bit, hoặc chân phát hiện thẻ ở chế độ 1-bit | SD1_DATA3 ALT0 | IO |
| SD1_DATA4 | Đường DATA4 ở chế độ 8-bit | NAND_READY_B ALT1 | IO |
| SD1_DATA5 | — | NAND_CE0_B ALT1 | IO |
| SD1_DATA6 | — | NAND_CE1_B ALT1 | IO |
| SD1_DATA7 | — | NAND_CLE ALT1 | IO |
| SD1_LCTL | Điều khiển LED, tích cực mức cao, tùy chọn | ENET1_RX_DATA0 ALT8 | O |
| SD1_RESET_B | Tín hiệu reset phần cứng thẻ, tích cực mức thấp | CSI_DATA06 ALT8 / GPIO1_IO04 ALT4 | O |
| SD1_VSELECT | Chọn điện áp nguồn IO | CSI_DATA07 ALT8 / GPIO1_IO05 ALT4 | O |
| SD1_WP | Phát hiện write protect. Nếu không dùng, kéo xuống thấp | CSI_DATA04 ALT8 / GPIO1_IO02 ALT4 | I |
| SD2_CD_B | Phát hiện thẻ SD2 | CSI_MCLK ALT1 / GPIO1_IO07 ALT4 | I |
| SD2_CLK | Clock cho thẻ MMC/SD/SDIO (SD2) | CSI_VSYNC ALT1 / NAND_RE_B ALT1 | O |
| SD2_CMD | Đường CMD SD2 | CSI_HSYNC ALT1 / NAND_WE_B ALT1 | IO |
| SD2_DATA0–7 | Đường dữ liệu SD2 | CSI_DATA00–07 ALT1 / LCD_DATA ALT8 / NAND_DATA ALT1 | IO |
| SD2_RESET_B | Reset phần cứng thẻ SD2 | GPIO1_IO09 ALT4 / NAND_ALE ALT1 | O |
| SD2_VSELECT | Chọn điện áp SD2 | ENET1_TX_DATA0 ALT8 / GPIO1_IO08 ALT4 | IO |
| SD2_WP | Write protect SD2 | CSI_PIXCLK ALT1 / GPIO1_IO06 ALT4 | I |

---

## 58.3 Clock

| Tên clock | Clock Root | Mô tả |
|-----------|-----------|-------|
| hclk | ahb_clk_root | AHB bus clock |
| ipg_clk | ipg_clk_root | Peripheral clock |
| ipg_clk_perclk | usdhc_clk_root | Base clock |
| ipg_clk_s | ipg_clk_root | Peripheral access clock cho truy cập thanh ghi |

> Xem **Clock Controller Module (CCM)** để biết cài đặt, cấu hình và gating clock.

---

## 58.4 Mô tả chức năng

### 58.4.1 Data Buffer

uSDHC sử dụng một data buffer có thể cấu hình để truyền dữ liệu giữa system bus (IP Bus hoặc AHB Bus) và thẻ SD theo cách tối ưu, tối đa hóa thông lượng giữa hai miền clock.

- Watermark level cho đọc và ghi: cấu hình được từ **1 đến 128 words**
- Burst length cho đọc và ghi: cấu hình được từ **1 đến 31 words**

#### Sơ đồ buffer uSDHC

```
┌─────────────┐    ┌────────────────────────────────────────────────┐
│   IP Bus    │◄──►│                                                │
└─────────────┘    │              uSDHC Registers                  │
┌─────────────┐    │                                                │
│   AHB Bus   │◄──►│  ┌──────────────┐    ┌────────────────────┐   │
└─────────────┘    │  │Buffer Control│◄──►│   Internal DMA     │   │
                   │  └──────┬───────┘    └────────────────────┘   │
                   │         │                                      │
                   │  ┌──────▼─────────────────────────────────┐   │
                   │  │          RAM Wrapper                    │   │
                   │  │  ┌────────────┐   ┌──────────────────┐ │   │
                   │  │  │  Tx FIFO   │   │    Rx FIFO       │ │   │
                   │  │  └────────────┘   └──────────────────┘ │   │
                   │  │  ┌──────────────────────────────────┐  │   │
                   │  │  │         Sync FIFOs               │  │   │
                   │  └──────────────────────────────────────┘  │   │
                   │                      │                      │   │
                   │              ┌───────▼──────┐               │   │
                   │              │  Status Sync  │               │   │
                   │              └───────┬──────┘               │   │
                   └──────────────────────┼──────────────────────┘   │
                                          │                           │
                                 ┌────────▼────────┐
                                 │    SD Bus I/F   │
                                 └─────────────────┘
                                      dma_req
                                    uSDHC_irq
```

#### Ba chế độ truy cập Data Buffer

| Chế độ | Mô tả |
|--------|-------|
| **CPU Polling** | Host Driver đọc/ghi thanh ghi Data Buffer Port bằng cách polling bit BRR/BWR trong Interrupt Status register |
| **External DMA** | Khi số words trong buffer đạt ngưỡng watermark, tín hiệu DMA request được xác nhận để thông báo cho DMA ngoài. Sử dụng IP bus. |
| **Internal DMA** (Simple & Advanced) | DMA nội bộ truy cập qua AHB bus. Khi dùng chế độ này, external DMA request sẽ không bao giờ được gửi ra. |

#### Data Swap – Little Endian Mode

```
System IP Bus / System AHB Bus:
┌─────────┬─────────┬─────────┬─────────┐
│  31–24  │  23–16  │  15–8   │   7–0   │
└─────────┴─────────┴─────────┴─────────┘
               ▲ swap ▼
uSDHC Data buffer:
┌─────────┬─────────┬─────────┬─────────┐
│   7–0   │  15–8   │  23–16  │  31–24  │
└─────────┴─────────┴─────────┴─────────┘
```

#### Data Swap – Half Word Big Endian Mode

```
System IP Bus / System AHB Bus:
┌──────────────────┬──────────────────┐
│     31–16        │      15–0        │
└──────────────────┴──────────────────┘
               ▲ swap ▼
uSDHC Data buffer:
┌──────────────────┬──────────────────┐
│     15–0         │      31–16       │
└──────────────────┴──────────────────┘
```

#### 58.4.1.4 Chia nhỏ truyền dữ liệu lớn (CMD53)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    544 Bytes WLAN Frame                             │
│  ┌──────────┬────┬────────────────┬─────┬─────┐                    │
│  │802.11 MAC│ IV │   Frame Body   │ ICV │ FCS │                    │
│  │  Header  │    │                │     │     │                    │
│  └──────────┴────┴────────────────┴─────┴─────┘                    │
└─────────────────────────────────────────────────────────────────────┘
                              │
                   Chia thành các block 64 byte
                              │
                              ▼
┌──────────┐ ┌──────────┐        ┌──────────┐ ┌──────────┐
│  Data    │ │  Data    │  ....  │  Data    │ │  Data    │
│  64 byte │ │  64 byte │        │  64 byte │ │  32 byte │
│  block#1 │ │  block#2 │        │  block#8 │ │(remainder│
└──────────┘ └──────────┘        └──────────┘ └──────────┘
      │             │                  │             │
      ▼             ▼                  ▼             ▼
┌──────────────────────────────────────────────────────────┐
│ CMD53 │ SDIO block#1 │ SDIO block#2 │...│ SDIO block#8  │
└──────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│ CMD53 │           SDIO Data 32 bytes                     │
└──────────────────────────────────────────────────────────┘
```

8 block 64 byte được gửi ở chế độ Block Transfer, 32 byte còn lại gửi ở chế độ Byte Transfer.

---

### 58.4.2 DMA AHB Interface

#### Sơ đồ khối DMA AHB Interface

```
┌───────────────────────────────────────────────────────────┐
│                   uSDHC Registers                         │
│  ┌──────────────────────────────────────────────────────┐ │
│  │              Buffer Control                          │ │
│  └──────────────────────┬───────────────────────────────┘ │
│                         │                                 │
│  ┌──────────────────────▼───────────────────────────────┐ │
│  │                 DMA Engine                           │ │
│  │  ┌─────────────────────────────────────────────────┐ │ │
│  │  │             Master Logic                        │ │ │
│  │  └────────────────────┬────────────────────────────┘ │ │
│  │                       │                              │ │
│  │  ┌────────────────────▼────────────────────────────┐ │ │
│  │  │             AHB Interface                       │ │ │
│  │  └────────────────────────────────────────────────-┘ │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                           │
│  Inputs:  System Address, R/W Indication, Error Indication│
│           Burst Length, Data Exchange, DMA Request        │
│  Output:  AHB signal cluster                              │
└───────────────────────────────────────────────────────────┘
```

#### 58.4.2.4 ADMA Engine

**ADMA (Advanced DMA)** định nghĩa bảng descriptor có thể lập trình trong bộ nhớ hệ thống. Host Driver tính toán địa chỉ hệ thống tại ranh giới trang và lập trình bảng descriptor trước khi thực thi ADMA, giảm tần suất ngắt đến hệ thống host.

| Loại ADMA | Đặc điểm |
|-----------|---------|
| **ADMA1** | Hỗ trợ truyền dữ liệu 4KB aligned trong system memory |
| **ADMA2** | Cải tiến – cho phép dữ liệu ở bất kỳ vị trí và kích thước nào trong system memory |

#### Định dạng ADMA1 Descriptor Table

```
Bit:  31                    12  11    6   5    4    3    2    1    0
     ┌──────────────────────────┬──────┬────┬────┬────┬────┬────┬─────┐
     │  Address / Page Field    │000000│Act2│Act1│ 0  │Int │End │Valid│
     └──────────────────────────┴──────┴────┴────┴────┴────┴────┴─────┘

Act2 │ Act1 │ Symbol │ Comment       │ Bits 31–28  │ Bits 27–12
─────┼──────┼────────┼───────────────┼─────────────┼──────────────────
  0  │  0   │  Nop   │ No Operation  │ Don't Care  │ Don't Care
  0  │  1   │  Set   │ Set Data Len  │ Don't Care  │ Data Length
  1  │  0   │  Tran  │ Transfer Data │    0000     │ Data Address
  1  │  1   │  Link  │ Link Desc.    │ Desc. Addr  │ Don't Care

Valid = 1: descriptor này hợp lệ; Valid = 0: tạo ADMA Error Interrupt và dừng ADMA
End   = 1: descriptor hiện tại là descriptor cuối cùng
Int   = 1: tạo DMA Interrupt khi descriptor này được xử lý
```

#### Sơ đồ ADMA1 – Concept & Access Method

```
┌─────────────────────────────────────────────────────────────────┐
│                  Advanced DMA System Memory                     │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  Descriptor Table                       │   │
│  │  ┌──────────────────┬────────────┐                      │   │
│  │  │ Address/Length   │ Attribute  │  ← Data Length  Set  │   │
│  │  ├──────────────────┼────────────┤                      │   │
│  │  │ Address          │ Tran       │                      │   │
│  │  ├──────────────────┼────────────┤                      │   │
│  │  │ Address          │ Link       │                      │   │
│  │  ├──────────────────┼────────────┤                      │   │
│  │  │ Address/Length   │ Attribute  │                      │   │
│  │  ├──────────────────┼────────────┤                      │   │
│  │  │ Address          │ Tran, End  │                      │   │
│  │  └──────────────────┴────────────┘                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────┐        ┌─────────────────┐               │
│  │   Page Data     │        │   Page Data      │               │
│  └─────────────────┘        └─────────────────┘               │
└─────────────────────────────────────────────────────────────────┘
         ▲                         ▲
         │                         │
┌────────┴─────────────────────────┴─────────────────────────────┐
│                        uSDHC                                    │
│  ┌──────────────────────┐    ┌──────────────────────────────┐  │
│  │ System Address Reg.  │    │  Flags / State Machine        │  │
│  ├──────────────────────┤    ├──────────────────────────────┤  │
│  │ Data Length (invis.) │    │  DMA Interrupt               │  │
│  ├──────────────────────┤    │  Transfer Complete           │  │
│  │ Data Address (invis.)│    │  Block Gap Event             │  │
│  └──────────────────────┘    └──────────────────────────────┘  │
│                   SDMA                                          │
│   System Address Register → head node của Descriptor Table     │
└─────────────────────────────────────────────────────────────────┘
```

#### Định dạng ADMA2 Descriptor Table

```
Bit:  63              32  31           16  15   6    5    4    3    2    1    0
     ┌──────────────────┬──────────────────┬─────┬────┬────┬────┬────┬────┬─────┐
     │  32-bit Address  │  16-bit length   │00000│Act2│Act1│ 0  │Int │End │Valid│
     └──────────────────┴──────────────────┴─────┴────┴────┴────┴────┴────┴─────┘

Act2 │ Act1 │ Symbol │ Comment
─────┼──────┼────────┼──────────────────────────────────────────────
  0  │  0   │  Nop   │ No Operation – đọc dòng này và chuyển sang dòng tiếp
  0  │  1   │  Rsv   │ Reserved – như Nop
  1  │  0   │  Tran  │ Transfer Data với address và length từ descriptor này
  1  │  1   │  Link  │ Link to another descriptor

Valid = 1: descriptor hợp lệ; Valid = 0: tạo ADMA Error Interrupt
End   = 1: descriptor cuối
Int   = 1: tạo DMA Interrupt khi descriptor này được xử lý
```

---

### 58.4.3 Register Bank với IP Bus Interface

Chỉ cho phép truy cập **32-bit**, không hỗ trợ partial read/write; tất cả truy cập phải word-aligned.

#### Sơ đồ Register Bank

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Register Bank                               │
│                                                                      │
│  ┌──────────┐                                                        │
│  │  IP Bus  │──────────────────────────────────────────────────────► │
│  │  Signals │◄──────────────────────────────────────────────────────  │
│  └──────────┘          │                                             │
│                        │                                             │
│   ips_xfr_err ────────►│  ┌────────────────────────────────────┐    │
│   ips_xfr_wait ───────►│  │    Software Visible Registers       │    │
│         "0"  ─────────►│  └────────────────────┬───────────────┘    │
│         "0"  ─────────►│                        │                   │
│                        │  ┌────────────────────▼──────────────────┐ │
│                        │  │        Write 1 Clear Function Array   │ │
│                        │  └────────────────────┬──────────────────┘ │
│                        │                        │                   │
│                        │  ┌────────────────────▼──────────────────┐ │
│                        │  │        Data Port                      │ │
│                        │  └────────────────────┬──────────────────┘ │
│                        │                        │                   │
│                        │  ┌────────────────────▼──────────────────┐ │
│                        │  │        Buffer Control Synchronizer    │ │
│                        │  └───────────────────────────────────────┘ │
│                                                                      │
│   Control/Status Signals ──────────────────► other modules          │
│   Status Signals ──────────────────────────► other modules          │
│   Control Signals ─────────────────────────► other modules          │
└──────────────────────────────────────────────────────────────────────┘
```

#### CRC Polynomials

| Loại | Generator Polynomial |
|------|---------------------|
| **CMD CRC** | G(x) = x⁷ + x³ + 1 |
| **DATA CRC** | G(x) = x¹⁶ + x¹² + x⁵ + 1 |

#### Command CRC Shift Register

```
CLR_CRC ──►┌─────────────────────────────────────────────────────┐
           │                                                     │
CRC_IN ───►│  Bus[0] ── Bus[1] ── Bus[2] ── Bus[3] ── Bus[4]    │
           │                              Bus[5] ── Bus[6]       │
           │                                                     │
           └────────────────────────────────────────────────────►CRC OUT
            ZERO input ────────────────────────────────────────►
```

---

### 58.4.5 Clock Generator

Clock Generator tạo card CLK từ peripheral source clock theo 2 giai đoạn chia:

#### Sơ đồ Clock Divider 2 giai đoạn

```
                    Base Clock (ipg_perclk)
                           │
                  ┌────────▼────────┐
                  │  1st Divisor    │
                  │  DVS[3:0]       │  ÷1, ÷2, ÷3, ... ÷16
                  └────────┬────────┘
                           │  DIV
                  ┌────────▼────────┐
                  │  2nd Divisor    │
                  │  SDCLKFS[7:0]   │  ÷1*, ÷2, ÷4, ... ÷256
                  └────────┬────────┘
                           │  card_clk
                  ┌────────▼────────┐
                  │     DDR_EN?     │
                  │  Yes → /2       │
                  └────────┬────────┘
                           │
                         CLK (output)
```

| Chế độ | Mối quan hệ CLK / card_clk |
|--------|--------------------------|
| SDR mode | CLK = card_clk |
| DDR mode | CLK = card_clk / 2 |

**Công thức tần số:** `Clock Frequency = Base Clock / (prescaler × divisor)`

Ví dụ: Base Clock = 96 MHz, target = 25 MHz → prescaler = 01h, divisor = 1h → 24 MHz (gần nhất ≤ target).

---

### 58.4.6 SDIO Card Interrupt

#### 58.4.6.3 Sơ đồ xử lý ngắt thẻ

```
                       ┌─────────────────┐
                       │      Start      │
                       └────────┬────────┘
                                │
                       ┌────────▼────────┐
                       │ Enable card IRQ │
                       │   in Host       │
                       └────────┬────────┘
                                │
                       ┌────────▼────────────────┐
                       │   Detect and steer      │
                       │     card IRQ            │
                       └────────┬────────────────┘
                                │ IP Bus IRQ to CPU
                       ┌────────▼────────┐
                       │ Read IRQ Status │
                       │    Register     │
                       └────────┬────────┘
                                │
                       ┌────────▼─────────────────────────────┐
                       │ Disable Card Interrupt Status enable  │
                       │ THEN write 1 to clear Card Int status │
                       └────────┬─────────────────────────────┘
                                │
                       ┌────────▼──────────────────┐
                       │ Interrogate & Service Card │
                       │         IRQ               │
                       └────────┬──────────────────┘
                                │
                       ┌────────▼────────┐
                       │ Response Error? │
                       └──┬─────────┬────┘
                         Yes        No
                          │          │
                          │  ┌───────▼──────────────┐
                          │  │  Clear Card IRQ       │
                          │  │      in Card          │
                          │  └───────┬──────────────-┘
                          │          │
                          │  ┌───────▼──────────────┐
                          │  │ Enable card IRQ in    │
                          │  │       Host            │
                          │  └───────┬───────────────┘
                          │          │
                          └──────────▼
                       ┌────────────────────┐
                       │        End         │
                       └────────────────────┘
```

---

### 58.4.9 MMC Fast Boot

#### Sơ đồ trạng thái – Normal Boot Mode

```
CLK  ──────┬──────────────────────────────────────────────────────────
CMD  ──────┘LOW ─────────────────────────────────────────────────────► HIGH
                │◄── 50ms max ──►│
                │                │
DATA0 ─────────►│S│ 010 │E│──────►│S│ 512bytes+CRC │E│──►│S│ 512bytes+CRC │E│──► Boot terminated
                │                │
                │◄──────────── 1 sec. max ──────────────────────────►│
                                                                      │
                                              Min 8+48=56 clocks required from
                                              CMD signal high to next MMC command
                                                          │
                                                    CMD1  RESP  CMD2  RESP  CMD3  RESP
```

#### Sơ đồ trạng thái – Alternative Boot Mode

```
CLK  ─────────────────────────────────────────────────────────────────
CMD  ──►[Min 74 clocks]──►CMD0¹ ────────────────────► CMD0/Reset ──►
                                    │◄── 50ms max ──►│
DATA0 ──────────────────────────────►│S│010│E│ 512B+CRC S E ──► 512B+CRC
                                    │◄──────────── 1 sec. max ─────►│
                                                   │
                                         RESP CMD1  CMD2  RESP  CMD3  RESP

¹ CMD0 với argument 0xFFFFFFFA
```

---

## 58.5 Khởi tạo / Ứng dụng uSDHC

### 58.5.2.1 Sơ đồ phát hiện thẻ

```
                    ┌─────────────────────────┐
                    │   Enable card detection  │
                    │         irq              │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼─────────────┐
                    │  Wait for uSDHC interrupt│
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼─────────────┐
                    │    Check CINS bit        │
                    └──────┬──────────┬────────┘
                           │          │
               ┌───────────▼──┐  ┌────▼─────────────┐
               │ Cards present│  │  No cards present  │
               └───────────┬──┘  └────────────────────┘
                           │
               ┌───────────▼──────────────────────────┐
               │  Clear CINSIEN to disable card        │
               │  detection irq                        │
               └───────────┬──────────────────────────┘
                           │
               ┌───────────▼──────────────────────────┐
               │       Voltage validation               │
               └──────────────────────────────────────-┘
```

### 58.5.2.2 Sơ đồ Reset

```
                    ┌───────────────────────────────────┐
                    │ Write "1" to RSTA bit to reset    │
                    │           uSDHC                   │
                    └───────────────┬───────────────────┘
                                    │
                    ┌───────────────▼───────────────────┐
                    │     Send 80 clocks to card        │
                    └───────────────┬───────────────────┘
                                    │
                    ┌───────────────▼───────────────────┐
                    │  Send CMD0 / CMD52 to card to     │
                    │           reset card              │
                    └───────────────┬───────────────────┘
                                    │
                    ┌───────────────▼───────────────────┐
                    │        Voltage Validation          │
                    └───────────────────────────────────┘
```

### 58.5.3.2.4 DLL (Delay Line) trong Read Path

```
                           ┌──────────────────────┐
                           │     SD/MMC Card       │
                           └──────────┬───────────┘
                                      │ DATA
                                      │
           card_clk_pad ◄─────────────┼────── card_clk ◄── /2 ◄── DDR_EN
                         │            │
                   ┌─────▼──────┐     │
                   │  Delay     │     │
                   │  line      │     │
                   └─────┬──────┘     │
                         │            │
                   ┌─────▼──────────────────────────────┐
                   │  Read Data Async Buffer             │
                   │  (Stages: 6 → 5 → 4 → 3 → 2 → 1)  │
                   └─────────────────────────────────────┘
                         ipp_card_clk_in ──► DLL ──► ipp_card_clk_in_dll
```

**Quy trình thay đổi tần số card_clk khi DLL đang bật:**

```
Step 1: Set DLL_CTRL_RESET bit
      ↓
Step 2: Configure SDCLKFS[7:0] và DVS[3:0]
      ↓
Step 3: Wait until SDSTB is asserted
      ↓
Step 4: Clear DLL_CTRL_RESET bit
      ↓
Step 5: Wait until both DLL_STS_SLV_LOCK and DLL_STS_REF_LOCK are asserted
      ↓
Step 6: Set DLL_CTRL_SLV_FORCE_UPD
      ↓
Step 7: Clear DLL_CTRL_SLV_FORCE_UPD
        (đảm bảo bit này giữ ít nhất 1 card_clk trước khi clear)
```

---

## 58.6 Lệnh cho MMC/SD/SDIO

Có 4 loại lệnh:

| Loại | Ký hiệu | Mô tả |
|------|---------|-------|
| Broadcast commands | bc | Không có response |
| Broadcast commands with response | bcr | Response từ tất cả thẻ đồng thời |
| Addressed commands | ac | Không truyền dữ liệu trên DATA |
| Addressed data transfer commands | adtc | Có truyền dữ liệu |

### Table 58-3. Commands for MMC/SD/SDIO Cards

| CMD | Type | Argument | Response | Tên | Mô tả |
|-----|------|----------|----------|-----|-------|
| CMD0 | bc | [31:0] stuff bits | — | GO_IDLE_STATE | Reset tất cả thẻ MMC và SD về idle state |
| CMD1 | bcr | [31:0] OCR without busy | R3 | SEND_OP_COND | Yêu cầu thẻ MMC/SD trong idle gửi operation conditions |
| CMD2 | bcr | [31:0] stuff bits | R2 | ALL_SEND_CID | Yêu cầu tất cả thẻ gửi số CID |
| CMD3 | ac | [31:6] RCA [15:0] stuff | R1/R6 | SET/SEND_RELATIVE_ADDR | Gán địa chỉ tương đối cho thẻ |
| CMD4 | bc | [31:0] DSR | — | SET_DSR | Lập trình DSR của tất cả thẻ |
| CMD5 | bc | [31:0] OCR without busy | R4 | IO_SEND_OP_COND | Yêu cầu thẻ SDIO trong idle gửi operation conditions |
| CMD6 | adtc | [31] Mode / [7:0] Function | R1 | SWITCH_FUNC | Kiểm tra/chuyển đổi chức năng thẻ SD |
| CMD6 | ac | [25:24] Access ... | R1b | SWITCH | Chuyển đổi chế độ hoạt động thẻ MMC, chỉnh EXT_CSD |
| CMD7 | ac | [31:6] RCA | R1b | SELECT/DESELECT_CARD | Chuyển thẻ giữa standby và transfer states |
| CMD8 | adtc | [31:0] stuff bits | R1 | SEND_EXT_CSD | Thẻ gửi thanh ghi EXT_CSD (512 bytes) |
| CMD9 | ac | [31:6] RCA | R2 | SEND_CSD | Thẻ gửi card-specific data (CSD) |
| CMD10 | ac | [31:6] RCA | R2 | SEND_CID | Thẻ gửi card-identification (CID) |
| CMD12 | ac | [31:0] stuff bits | R1b | STOP_TRANSMISSION | Buộc thẻ dừng truyền |
| CMD13 | ac | [31:6] RCA | R1 | SEND_STATUS | Thẻ gửi status register |
| CMD16 | ac | [31:0] block length | R1 | SET_BLOCKLEN | Đặt độ dài block cho các lệnh tiếp theo |
| CMD17 | adtc | [31:0] data address | R1 | READ_SINGLE_BLOCK | Đọc một block |
| CMD18 | adtc | [31:0] data address | R1 | READ_MULTIPLE_BLOCK | Đọc nhiều block liên tục |
| CMD24 | adtc | [31:0] data address | R1 | WRITE_BLOCK | Ghi một block |
| CMD25 | adtc | [31:0] data address | R1 | WRITE_MULTIPLE_BLOCK | Ghi nhiều block liên tục |
| CMD38 | ac | [31:0] stuff bits | R1b | ERASE | Xóa tất cả các sector đã chọn trước |
| CMD52 | ac | [31:0] stuff bits | R5 | IO_RW_DIRECT | Truy cập một thanh ghi đơn trong không gian 128k của SDIO |
| CMD53 | ac | [31:0] stuff bits | R5 | IO_RW_EXTENDED | Truy cập nhiều thanh ghi I/O với một lệnh |
| CMD55 | ac | [31:16] RCA | R1 | APP_CMD | Báo lệnh tiếp theo là application-specific |
| ACMD6 | ac | [31:2] stuff [1:0] bus width | R1 | SET_BUS_WIDTH | Đặt độ rộng bus dữ liệu (1-bit hoặc 4-bit) |
| ACMD41 | bcr | [31:0] OCR | R3 | SD_APP_OP_COND | Yêu cầu thẻ SD gửi operation condition register |
| ACMD51 | adtc | [31:0] stuff bits | R1 | SEND_SCR | Đọc SD Configuration Register (SCR) |

### EXT_CSD Access Modes

| Bits | Tên truy cập | Hoạt động |
|------|-------------|----------|
| 00 | Command Set | Thay đổi command set theo trường Cmd Set của argument |
| 01 | Set Bits | Đặt các bit trong byte trỏ đến theo giá trị 1 trong trường Value |
| 10 | Clear Bits | Xóa các bit trong byte trỏ đến theo giá trị 1 trong trường Value |
| 11 | Write Byte | Ghi giá trị trường Value vào byte trỏ đến |

---

## 58.7 Giới hạn phần mềm

| Mục | Giới hạn |
|-----|---------|
| **Initialization Active** | Không được set INITA khi CMD hoặc DATA đang active (CDIHB và CIHB phải được clear) |
| **Software Polling** | Phải truy cập đúng số lần bằng giá trị WML. Ví dụ: RD_WML=4, block=40B, 2 blocks → trình tự truy cập: 4,4,2,4,4,2 |
| **Suspend Operation** | Phải gửi lệnh normal đánh dấu suspend (CMDTYP='01') sau khi Suspend được thẻ SDIO chấp nhận; đọc BLKCNT trước khi gửi |
| **Data Length** | Dữ liệu trong buffer phải word-aligned; data length trong descriptor phải là bội số của 4 |
| **(A)DMA Address** | Phải đảm bảo TC bit đã cleared trước khi cấu hình ADMA1/ADMA2/DMA address register |
| **Data Port Access** | Không hỗ trợ parallel access – cấm vừa CPU vừa DMA ghi đồng thời |
| **Change Clock Frequency** | Clear FRC_SDCLK_ON trước khi thay đổi SDCLKFS/DVS; đảm bảo SDSTB=1 trước khi thay đổi |
| **Multi-block Read** | Luôn cần lệnh abort (CMD12/CMD52) sau khi đọc xong dù thẻ không cần – để đưa state machine về idle |

---

## 58.8 Memory Map và Định nghĩa Thanh ghi

> **Lưu ý**: Tất cả thanh ghi uSDHC rộng 32-bit và chỉ hỗ trợ truy cập 32-bit.

### Memory Map uSDHC1 (Base: 0x2190_0000) và uSDHC2 (Base: 0x2194_0000)

| Offset | Tên thanh ghi | Truy cập | Reset Value |
|--------|---------------|----------|-------------|
| 0x00 | DMA System Address (DS_ADDR) | R/W | 0x0000_0000 |
| 0x04 | Block Attributes (BLK_ATT) | R/W | 0x0000_0000 |
| 0x08 | Command Argument (CMD_ARG) | R/W | 0x0000_0000 |
| 0x0C | Command Transfer Type (CMD_XFR_TYP) | R/W | 0x0000_0000 |
| 0x10 | Command Response0 (CMD_RSP0) | R | 0x0000_0000 |
| 0x14 | Command Response1 (CMD_RSP1) | R | 0x0000_0000 |
| 0x18 | Command Response2 (CMD_RSP2) | R | 0x0000_0000 |
| 0x1C | Command Response3 (CMD_RSP3) | R | 0x0000_0000 |
| 0x20 | Data Buffer Access Port (DATA_BUFF_ACC_PORT) | R/W | 0x0000_0000 |
| 0x24 | Present State (PRES_STATE) | R | 0x0000_8080 |
| 0x28 | Protocol Control (PROT_CTRL) | R/W | 0x0880_0020 |
| 0x2C | System Control (SYS_CTRL) | R/W | 0x8080_800F |
| 0x30 | Interrupt Status (INT_STATUS) | w1c | 0x0000_0000 |
| 0x34 | Interrupt Status Enable (INT_STATUS_EN) | R/W | 0x0000_0000 |
| 0x38 | Interrupt Signal Enable (INT_SIGNAL_EN) | R/W | 0x0000_0000 |
| 0x3C | Auto CMD12 Error Status (AUTOCMD12_ERR_STATUS) | R | 0x0000_0000 |
| 0x40 | Host Controller Capabilities (HOST_CTRL_CAP) | R | 0x07F3_B407 |
| 0x44 | Watermark Level (WTMK_LVL) | R/W | 0x0810_0810 |
| 0x48 | Mixer Control (MIX_CTRL) | R/W | 0x8000_0000 |
| 0x50 | Force Event (FORCE_EVENT) | W | 0x0000_0000 |
| 0x54 | ADMA Error Status (ADMA_ERR_STATUS) | R | 0x0000_0000 |
| 0x58 | ADMA System Address (ADMA_SYS_ADDR) | R/W | 0x0000_0000 |
| 0x60 | DLL Control (DLL_CTRL) | R/W | 0x0000_0200 |
| 0x64 | DLL Status (DLL_STATUS) | R | 0x0000_0000 |
| 0x68 | CLK Tuning Control and Status (CLK_TUNE_CTRL_STATUS) | R/W | 0x0000_0000 |
| 0xC0 | Vendor Specific Register (VEND_SPEC) | R/W | 0x2000_7809 |
| 0xC4 | MMC Boot Register (MMC_BOOT) | R/W | 0x0000_0000 |
| 0xC8 | Vendor Specific 2 Register (VEND_SPEC2) | R/W | 0x0000_0006 |
| 0xCC | Tuning Control Register (TUNING_CTRL) | R/W | 0x0021_2800 |

---

### 58.8.2 Block Attributes (BLK_ATT) – Offset 0x04

```
Bit:  31          16  15  13  12            0
     ┌──────────────┬───┬──────────────────┐
     │   BLKCNT     │ 0 │  BLKSIZE[12:0]   │
     └──────────────┴───┴──────────────────┘
```

| Field | Bits | Mô tả |
|-------|------|-------|
| BLKCNT | [31:16] | Số block cho transfer hiện tại (1–65535); 0 = không transfer block nào |
| Reserved | [15:13] | Luôn = 0 |
| BLKSIZE | [12:0] | Kích thước block transfer (1–4096 bytes) |

| Giá trị BLKSIZE | Ý nghĩa |
|-----------------|---------|
| 0x1000 | 4096 Bytes |
| 0x0800 | 2048 Bytes |
| 0x0200 | 512 Bytes |
| 0x0001 | 1 Byte |
| 0x0000 | Không truyền dữ liệu |

---

### 58.8.4 Command Transfer Type (CMD_XFR_TYP) – Offset 0x0C

```
Bit:  31 30  29    24  23  22  21  20  19  18  17 16
     ┌──┬──┬────────┬───┬───┬───┬───┬───┬───┬────┐
     │ 0│ 0│CMDINX  │CMD│CMD│DPS│CIC│CCC│ 0 │RSP │
     │  │  │[5:0]   │TYP│TYP│EL │EN │EN │   │TYP │
     └──┴──┴────────┴───┴───┴───┴───┴───┴───┴────┘
      Bit 15–0: Reserved = 0
```

#### Loại Transfer theo cài đặt

| Multi/Single Block Select | Block Count Enable | Block Count | Chức năng |
|--------------------------|-------------------|-------------|-----------|
| 0 | Don't Care | Don't Care | Single Transfer |
| 1 | 0 | Don't Care | Infinite Transfer |
| 1 | 1 | Positive Number | Multiple Transfer |
| 1 | 1 | Zero | No Data Transfer |

#### Quan hệ Response Type – Index Check – CRC Check

| Response Type | Index Check Enable | CRC Check Enable | Tên Response |
|--------------|-------------------|-----------------|--------------|
| 00 | 0 | 0 | No Response |
| 01 | 0 | 1 | R2 |
| 10 | 0 | 0 | R3, R4 |
| 10 | 1 | 1 | R1, R5, R6 |
| 11 | 1 | 1 | R1b, R5b |

---

### 58.8.8 Command Response3 – Ánh xạ Response

| Response Type | Ý nghĩa | Response Field | Thanh ghi |
|--------------|---------|---------------|----------|
| R1, R1b (normal) | Card Status | R[39:8] | CMDRSP0 |
| R1b (Auto CMD12) | Card Status for Auto CMD12 | R[39:8] | CMDRSP3 |
| R2 (CID, CSD) | CID/CSD register [127:8] | R[127:8] | {CMDRSP3[23:0], CMDRSP2, CMDRSP1, CMDRSP0} |
| R3 | OCR register for memory | R[39:8] | CMDRSP0 |
| R4 | OCR register for I/O | R[39:8] | CMDRSP0 |
| R5, R5b | SDIO response | R[39:8] | CMDRSP0 |
| R6 | New Published RCA + card status | R[39:9] | CMDRSP0 |

---

### 58.8.10 Present State (PRES_STATE) – Offset 0x24

```
Bit:  31    24  23  22 20  19  18  17  16
     ┌────────┬───┬────┬───┬───┬───┬────┐
     │DLSL[7:0]│CLS│ 0  │WPS│CDP│ 0 │CIN │
     └────────┴───┴────┴───┴───┴───┴────┘

Bit:  15  14 13  12  11  10   9   8   7   6   5   4   3   2   1   0
     ┌───┬──┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
     │TSD│0 │RTR│BRE│BWE│RTA│WTA│SDO│PER│HCK│IPG│SDS│DLA│CDI│CIH│
     └───┴──┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
         N   N   N   N   N   N   FF  FF  OFF OFF  TB  B   HB  B
```

| Bit | Tên | Mô tả |
|-----|-----|-------|
| [31:24] | DLSL[7:0] | Mức tín hiệu đường DATA[7:0] |
| [23] | CLSL | Mức tín hiệu CMD line |
| [19] | WPSPL | Write Protect Switch Pin Level (1=ghi được) |
| [18] | CDPL | Card Detect Pin Level (1=có thẻ, CD_B=0) |
| [16] | CINST | Card Inserted (1=thẻ đã cắm) |
| [12] | RTR | Re-Tuning Request (chỉ SDR104) |
| [11] | BREN | Buffer Read Enable |
| [10] | BWEN | Buffer Write Enable |
| [9] | RTA | Read Transfer Active |
| [8] | WTA | Write Transfer Active |
| [7] | SDOFF | SD Clock Gated Off Internally |
| [3] | SDSTB | SD Clock Stable |
| [2] | DLA | Data Line Active |
| [1] | CDIHB | Command Inhibit (DATA) |
| [0] | CIHB | Command Inhibit (CMD) |

---

### 58.8.13 Interrupt Status (INT_STATUS) – Offset 0x30

#### Quan hệ Command Timeout Error / Command Complete

| Command Complete | Command Timeout Error | Ý nghĩa |
|-----------------|----------------------|---------|
| 0 | 0 | — |
| X | 1 | Response không nhận được trong 64 SDCLK cycles |
| 1 | 0 | Response đã nhận |

#### Quan hệ Transfer Complete / Data Timeout Error

| Transfer Complete | Data Timeout Error | Ý nghĩa |
|------------------|-------------------|---------|
| 0 | 0 | — |
| 0 | 1 | Timeout xảy ra trong quá trình transfer |
| 1 | X | Data Transfer hoàn tất |

#### Quan hệ Command CRC Error / Command Timeout Error

| Command Complete | Command Timeout Error | Ý nghĩa |
|-----------------|----------------------|---------|
| 0 | 0 | Không có lỗi |
| 0 | 1 | Response Timeout Error |
| 1 | 0 | Response CRC Error |
| 1 | 1 | CMD line conflict |

#### Các bit Interrupt Status

| Bit | Tên | Mô tả |
|-----|-----|-------|
| [28] | DMAE | DMA Error |
| [26] | TNE | Tuning Error (chỉ SDR104) |
| [24] | AC12E | Auto CMD12 Error |
| [22] | DEBE | Data End Bit Error |
| [21] | DCE | Data CRC Error |
| [20] | DTOE | Data Timeout Error |
| [19] | CIE | Command Index Error |
| [18] | CEBE | Command End Bit Error |
| [17] | CCE | Command CRC Error |
| [16] | CTOE | Command Timeout Error |
| [14] | TP | Tuning Pass (chỉ SDR104) |
| [12] | RTE | Re-Tuning Event |
| [8] | CINT | Card Interrupt |
| [7] | CRM | Card Removal |
| [6] | CINS | Card Insertion |
| [5] | BRR | Buffer Read Ready |
| [4] | BWR | Buffer Write Ready |
| [3] | DINT | DMA Interrupt |
| [2] | BGE | Block Gap Event |
| [1] | TC | Transfer Complete |
| [0] | CC | Command Complete |

---

### 58.8.16 Auto CMD12 Error Status – Offset 0x3C

#### Quan hệ CRC Error / Timeout Error cho Auto CMD12

| Auto CMD12 CRC Error | Auto CMD12 Timeout Error | Loại lỗi |
|---------------------|------------------------|---------|
| 0 | 0 | Không có lỗi |
| 0 | 1 | Response Timeout Error |
| 1 | 0 | Response CRC Error |
| 1 | 1 | CMD line conflict |

| Bit | Tên | Mô tả |
|-----|-----|-------|
| [23] | SMP_CLK_SEL | Sample Clock Select (1=tuned clock) |
| [22] | EXECUTE_TUNING | Bắt đầu thủ tục tuning |
| [7] | CNIBAC12E | CMD not issued by Auto CMD12 Error |
| [4] | AC12IE | Auto CMD12/23 Index Error |
| [3] | AC12CE | Auto CMD12/23 CRC Error |
| [2] | AC12EBE | Auto CMD12/23 End Bit Error |
| [1] | AC12TOE | Auto CMD12/23 Timeout Error |
| [0] | AC12NE | Auto CMD12 Not Executed |

---

### 58.8.17 Host Controller Capabilities (HOST_CTRL_CAP) – Offset 0x40

| Bit | Tên | Mô tả |
|-----|-----|-------|
| [26] | VS18 | Hỗ trợ điện áp 1.8V |
| [25] | VS30 | Hỗ trợ điện áp 3.0V |
| [24] | VS33 | Hỗ trợ điện áp 3.3V |
| [23] | SRS | Hỗ trợ Suspend/Resume |
| [22] | DMAS | Hỗ trợ DMA nội bộ |
| [21] | HSS | Hỗ trợ High Speed |
| [20] | ADMAS | Hỗ trợ Advanced DMA |
| [18:16] | MBL[2:0] | Max Block Length (000=512B, 001=1024B, 010=2048B, 011=4096B) |
| [15:14] | RETUNING_MODE | Chế độ retuning (00=Mode1, 01=Mode2, 10=Mode3) |
| [13] | USE_TUNING_SDR50 | SDR50 cần tuning |
| [11:8] | TIME_COUNT_RETUNING | Giá trị khởi tạo Retuning Timer |
| [2] | DDR50_SUPPORT | Hỗ trợ DDR50 |
| [1] | SDR104_SUPPORT | Hỗ trợ SDR104 |
| [0] | SDR50_SUPPORT | Hỗ trợ SDR50 |

---

### 58.8.18 Watermark Level (WTMK_LVL) – Offset 0x44

```
Bit:  31 29  28    24  23    16  15 13  12     8   7       0
     ┌────┬──────────┬──────────┬────┬──────────┬──────────┐
     │  0 │WR_BRST   │  WR_WML  │ 0  │ RD_BRST  │  RD_WML  │
     │    │LEN[4:0]  │  [7:0]   │    │ LEN[4:0] │  [7:0]   │
     └────┴──────────┴──────────┴────┴──────────┴──────────┘
```

| Field | Phạm vi | Mô tả |
|-------|---------|-------|
| WR_BRST_LEN | 1–16 words | Burst length ghi (≤ WR_WML) |
| WR_WML | 1–128 words | Watermark level ghi |
| RD_BRST_LEN | 1–16 words | Burst length đọc (≤ RD_WML) |
| RD_WML | 1–128 words | Watermark level đọc |

---

### 58.8.21 ADMA Error Status (ADMA_ERR_STATUS) – Offset 0x54

#### Bảng mã trạng thái ADMA Error

| D[1:0] | ADMA Error State | Nội dung ADMA System Address Register |
|--------|-----------------|--------------------------------------|
| 00 | ST_STOP (Stop DMA) | Địa chỉ descriptor thực thi tiếp theo |
| 01 | ST_FDS (Fetch Descriptor) | Địa chỉ descriptor hợp lệ |
| 10 | ST_CADR (Change Address) | Không tạo ADMA Error |
| 11 | ST_TFR (Transfer Data) | Địa chỉ descriptor thực thi tiếp theo |

| Bit | Tên | Mô tả |
|-----|-----|-------|
| [3] | ADMADCE | ADMA Descriptor Error – descriptor không hợp lệ |
| [2] | ADMALME | ADMA Length Mismatch Error |
| [1:0] | ADMAES | ADMA Error State |

---

### 58.8.12 System Control (SYS_CTRL) – Offset 0x2C

| Bit | Tên | Mô tả |
|-----|-----|-------|
| [28] | RSTT | Reset Tuning circuit |
| [27] | INITA | Gửi 80 SD-Clocks đến thẻ (self-cleared) |
| [26] | RSTD | Software Reset cho DATA line |
| [25] | RSTC | Software Reset cho CMD line |
| [24] | RSTA | Software Reset For ALL |
| [23] | IPP_RST_N | Output ra CARD để hardware reset thẻ |
| [19:16] | DTOCV | Data Timeout Counter Value |
| [15:8] | SDCLKFS | SDCLK Frequency Select (2nd divisor stage) |
| [7:4] | DVS[3:0] | Divisor (1st divisor stage, ÷1 đến ÷16) |

#### SDCLKFS – Tần số trong SDR Mode

| SDCLKFS | Chia |
|---------|------|
| 0x80 | Base ÷ 256 |
| 0x40 | Base ÷ 128 |
| 0x20 | Base ÷ 64 |
| 0x10 | Base ÷ 32 |
| 0x08 | Base ÷ 16 |
| 0x04 | Base ÷ 8 |
| 0x02 | Base ÷ 4 |
| 0x01 | Base ÷ 2 |
| 0x00 | Base ÷ 1 |

---

### 58.8.27 MMC Boot Register (MMC_BOOT) – Offset 0xC4

| Bit | Tên | Mô tả |
|-----|-----|-------|
| [31:16] | BOOT_BLK_CNT | Giá trị Stop At Block Gap cho auto mode |
| [8] | DISABLE_TIME_OUT | Tắt kiểm tra timeout |
| [7] | AUTO_SABG_EN | Tự động Stop At Block Gap |
| [6] | BOOT_EN | Bật/tắt Fast Boot |
| [5] | BOOT_MODE | 0 = Normal boot; 1 = Alternative boot |
| [4] | BOOT_ACK | 0 = No ACK; 1 = ACK |
| [3:0] | DTOCV_ACK | Giá trị timeout cho Boot ACK |

#### DTOCV_ACK Timeout

| Giá trị | Timeout |
|---------|---------|
| 0000 | SDCLK × 2¹³ |
| 0001 | SDCLK × 2¹⁴ |
| ... | ... |
| 1110 | SDCLK × 2²⁷ |
| 1111 | SDCLK × 2²⁸ |

---

*Tài liệu tham khảo: i.MX 6ULL Applications Processor Reference Manual, Rev. 1, 11/2017, NXP Semiconductors.*
