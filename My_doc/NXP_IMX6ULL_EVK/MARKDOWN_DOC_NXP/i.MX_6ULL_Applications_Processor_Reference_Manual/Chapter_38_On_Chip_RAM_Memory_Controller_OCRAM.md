# Chapter 38: On-Chip RAM Memory Controller (OCRAM)

## 38.1 Overview

Chip này có **1 OCRAM controller** quản lý **128 KB on-chip RAM**.

OCRAM được triển khai là slave module trên **64-bit system AXI bus**. Đây là một memory controller đơn giản, chỉ hỗ trợ một AXI port với nhiều memory bank. Read và write transaction được xử lý bởi hai module độc lập. Vì AXI bus có thể gửi read và write request đồng thời, mỗi memory bank có một **arbiter round-robin** riêng.

Sau khi arbitration, lệnh read/write được cấp quyền sẽ được gửi đến memory cell thông qua một read/write MUX.

### Tổ chức Memory Bank

Memory bank được tổ chức theo **2 bit thấp nhất của địa chỉ** (AXI bus address, 64-bit aligned, interleaved). Nhờ đó, một read access và một write access có thể được xử lý **đồng thời** nếu chúng hướng đến các bank khác nhau.

### Sơ đồ khối

```
AXI Bus ──┬──► RD REQ DEC ──► Read Control Module ──► Arbiter ──► RAM MUX ──► Bank 0
          │                                                        Arbiter ──► RAM MUX ──► Bank 1
          │                                                        Arbiter ──► RAM MUX ──► Bank 2
          └──► WR REQ DEC ──► Write Control Module ─► Arbiter ──► RAM MUX ──► Bank 3
                              WDATA MUX ──────────────────────────────────────────┘
                                                              └──► RDATA MUX [0–3] ──► AXI RDATA
Timing Configuration ──────────────────────────────────────────────────────────────────────────
```

---

## 38.2 Basic Functions

### 38.2.1 Read/Write Arbitration

Quy tắc arbitration chi tiết:

| Tình huống | Kết quả |
|---|---|
| Không có granted R/W trong cycle trước + chỉ có read hoặc write request | Request đó được grant |
| Không có granted R/W trong cycle trước + có cả read và write request cùng lúc | **Read được grant trước** |
| Một read/write transaction vừa hoàn thành | Write/read request còn lại được **ưu tiên** trong cycle tiếp theo |
| Read/write burst đang được xử lý | **Toàn bộ dữ liệu của burst** được hoàn thành trước khi arbitration tiếp theo bắt đầu |

> Round-robin arbitration dựa trên **AXI transaction**, không phải dựa trên từng data access.

---

## 38.3 Advanced Features

Các tính năng nâng cao giúp tránh timing issue khi OCRAM chạy ở tần số cao. Tất cả có thể được bật/tắt qua **`IOMUXC.GPR3`** bits `[24:21]` và `[3:0]`.

### 38.3.1 Read Data Wait State

| Trạng thái | Hành vi |
|---|---|
| **Enabled** | Mỗi read access (mỗi beat) mất **2 cycles** |
| **Disabled** | Mỗi read access mất **1 cycle** (read data sẵn sàng ở cycle tiếp theo) |

- Dành cho: tránh vấn đề timing do access time dài hơn ở tần số cao.
- Cấu hình: `IOMUXC.GPR3[21]`

---

### 38.3.2 Read Address Pipeline

| Trạng thái | Hành vi |
|---|---|
| **Enabled** | Read address từ AXI master bị **delay 1 cycle** trước khi OCRAM chấp nhận |
| **Disabled** | Read address được chấp nhận ngay, data sẵn sàng ở cycle tiếp theo |

- Dành cho: tránh setup time issue cho read access ở tần số cao.
- Chi phí: tối đa **1 clock cycle thêm** cho mỗi AXI read transaction (mỗi burst).
- Cấu hình: `IOMUXC.GPR3[22]` (normal OCRAM) / `IOMUXC.GPR3[1]` (L2 cache as OCRAM)

---

### 38.3.3 Write Data Pipeline

| Trạng thái | Hành vi |
|---|---|
| **Enabled** | Write data từ AXI master bị **delay 1 cycle** trước khi OCRAM chấp nhận |
| **Disabled** | Write data được chấp nhận ngay, data được ghi vào memory ở cycle đó |

- Dành cho: tránh setup time issue cho write access ở tần số cao.
- Chi phí: tối đa **1 clock cycle thêm** cho mỗi AXI write transaction.
- Cấu hình: `IOMUXC.GPR3[23]` (normal OCRAM) / `IOMUXC.GPR3[2]` (L2 cache as OCRAM)

---

### 38.3.4 Write Address Pipeline

| Trạng thái | Hành vi |
|---|---|
| **Enabled** | Write address từ AXI master bị **delay 1 cycle** trước khi OCRAM chấp nhận |
| **Disabled** | Write address được chấp nhận ngay, data được ghi ở cycle đó |

- Dành cho: tránh setup time issue cho write access ở tần số cao.
- Chi phí: tối đa **1 clock cycle thêm** cho mỗi AXI write transaction.
- Cấu hình: `IOMUXC.GPR3[24]` (normal OCRAM) / `IOMUXC.GPR3[3]` (L2 cache as OCRAM)

---

### Bảng tổng hợp Advanced Features

| Feature | Normal OCRAM | L2 as OCRAM | Tác dụng |
|---|---|---|---|
| Read data wait state | `GPR3[21]` | — | +1 cycle read latency, giảm timing risk |
| Read address pipeline | `GPR3[22]` | `GPR3[1]` | +1 cycle/burst, tránh read setup issue |
| Write data pipeline | `GPR3[23]` | `GPR3[2]` | +1 cycle/burst, tránh write setup issue |
| Write address pipeline | `GPR3[24]` | `GPR3[3]` | +1 cycle/burst, tránh write setup issue |

---

## 38.4 Programmable Registers

OCRAM **không có register riêng**. Các bit cấu hình nằm trong **IOMUX Controller (IOMUXC)**:

| Register | Mục đích |
|---|---|
| `IOMUXC_GPR3` | Wait state / Pipeline bits `[24:21]`, `[3:0]` |
| `IOMUXC_GPR10` | TrustZone bits |

---

*Source: i.MX 6ULL Applications Processor Reference Manual, Rev. 1, 11/2017 – NXP Semiconductors*