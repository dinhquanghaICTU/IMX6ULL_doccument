# i.MX 6ULL — Chapter 6: External Memory Controllers

> Tài liệu tham khảo: *i.MX 6ULL Applications Processor Reference Manual, Rev. 1, 11/2017 — NXP Semiconductors*

---

## 6.1 Tổng quan

Chip này có các giao diện và bộ điều khiển bộ nhớ ngoài sau:

- **MMDC** — Multi-Mode DDR Controller
- **EIM** — PSRAM/NOR Flash Controller

---

## 6.2 Multi-Mode DDR Controller (MMDC)

MMDC là bộ điều khiển DDR hỗ trợ nhiều loại bộ nhớ DDR khác nhau.

### Bảng 6-1. Tóm tắt tính năng MMDC

| Tính năng | Mô tả |
|-----------|-------|
| **Chuẩn hỗ trợ** | LPDDR2 1ch x16, LV-DDR3, DDR3 x16 |
| **Giao diện DDR** | Dung lượng 256 MB – 4 GB · Column size: 8–12 bit · Row size: 11–16 bit · Burst length: 8 (aligned) cho DDR3, 4 cho LPDDR2 |
| **Hiệu năng DDR** | Hỗ trợ Real-Time priority qua QoS · Tối ưu page hit/miss · Tối ưu truy cập read/write liên tiếp · Hỗ trợ deep read/write queue để bank prediction · Trả về critical word ngay khi nhận được (không chờ toàn bộ data phase) · Theo dõi open memory pages · Hỗ trợ bank interleaving · Tối ưu đặc biệt cho non-aligned wrap access ở burst length 8 |
| **Giao diện AXI** | Tuân chuẩn AXI bus, giao diện glueless tới PL301 AXI network interconnect |
| **Hiệu chỉnh & Delay-lines** | Tất cả calibration có thể thực hiện tự động (hardware) hoặc thủ công (software) · ZQ calibration cho DDR3 (qua lệnh ZQ calibration) và LPDDR2 (qua lệnh MRW) · ZQ Short (định kỳ) và ZQ Long (khi thoát self-refresh) xử lý tự động · ZQ INIT xử lý thủ công |
| **Chung** | Tham số timing cấu hình linh hoạt · Cấu hình refresh scheme · Hỗ trợ thay đổi điện áp/tần số động và chế độ low-power qua hardware negotiation (req/ack handshake) · Tự động vào/ra self-refresh và power down · Hỗ trợ fast/slow precharge power down (DDR3) · Nhiều scheme điều khiển ODT · Hỗ trợ lệnh MRW và MRR cho LPDDR2 · Điều chỉnh timing/refresh theo nhiệt độ · Hỗ trợ các chế độ debug và profiling |

---

## 6.3 EIM — PSRAM/NOR Flash Controller

EIM là module giao diện ngoài quản lý kết nối tới các thiết bị chip ngoài, bao gồm tạo chip select, clock và điều khiển cho các peripheral và bộ nhớ ngoài.

EIM cung cấp truy cập **asynchronous** và **synchronous** tới các thiết bị có giao diện kiểu SRAM.

---

### 6.3.1 Tính năng EIM

- Tối đa **4 chip select** (cấu hình bằng phần mềm) cho thiết bị ngoài
- Giải mã địa chỉ linh hoạt; mỗi chip-select memory space được xác định riêng qua GPR bits trong IOMUXC
- Mật độ tối đa hỗ trợ:
  - **128 MB** (mặc định, khi AUS bit = 0)
  - **32 MB** khi AUS bit = 1
- Bảo vệ ghi có thể chọn cho từng chip select
- Bộ tạo wait-state lập trình được cho mỗi chip select (riêng cho read và write)
- Truy cập asynchronous với setup/hold time cấu hình được cho tín hiệu điều khiển
- Hỗ trợ synchronous memory burst write mode độc lập cho PSRAM và NOR Flash:
  - CellularRAM™ (Micron, Infineon, Cypress)
  - OneNAND™ và utRAM™ (Samsung)
  - COSMORAM™ (Toshiba)
- Hỗ trợ thiết bị NAND Flash với giao diện NOR Flash — OneNAND™ (Samsung)
- Hỗ trợ variable/fix latency cho read/write synchronous (burst) mode
- Hỗ trợ little-endian mode
- AXI slave interface chỉ xử lý song song với single AXI ID transactions
- Hỗ trợ ngắt ngoài qua tín hiệu **RDY_INT**
- Hỗ trợ boot từ thiết bị ngoài qua tín hiệu RDY_INT
- Hỗ trợ RDY signal assertion sau reset
- Hỗ trợ INT signal assertion sau reset cho OneNAND™ (Samsung)

---

### 6.3.2 EIM Boot Scenarios

EIM cho phép boot từ thiết bị NOR Flash. Để chọn NOR Flash làm nguồn boot, sử dụng:

- Boot mode và GPIO pins cấu hình, **hoặc**
- Internal boot-related fuses

*(Xem thêm chương System Boot)*

---

### 6.3.3 EIM Boot Configuration

#### Bảng 6-2. EIM Boot Configuration

| EIM_BOOT_CFG Bus | EIM Affected Bits | EIM Register |
|-----------------|-------------------|--------------|
| 12 | NUM16_BYP_GRANT | CS0GCR2 |
| 11 | DSZ[2] | CS0GCR1 |
| 10 | AUS | CS0GCR1 |
| [9:8] | CSREC[2:1] | CS0GCR1 |
| [7:5] | RWSC[4:2] | CS0GCR1 |
| [7:5] | WWSC[4:2] | CS0WCR |
| 4 | ERRST | WCR |
| 3 | RAL | CS0RCR1 |
| 3 | WAL | CS0WCR |
| 2 | MUM | CS0GCR1 |
| 2 | OEA[1] | CS0RCR1 |
| [1:0] | DSZ[1:0] | CS0GCR1 |

---

### 6.3.4 OneNAND Requirements

Theo mặc định, chân **Ready/Busy** không được sử dụng. Để cấu hình OneNAND, thực hiện một trong các bước sau:

1. **Poll thiết bị** để kiểm tra trạng thái sẵn sàng — phần mềm thực hiện read từ thiết bị.
2. **Kết nối tín hiệu Ready/Busy** của thiết bị OneNAND tới bất kỳ GPIO pin nào và sử dụng như một interrupt báo hiệu trạng thái sẵn sàng của thiết bị.

---

*Tài liệu được chuyển đổi từ Chapter 6 — i.MX 6ULL Applications Processor Reference Manual, Rev. 1, 11/2017, NXP Semiconductors.*