# i.MX 6ULL Boot Fusemap

> Tài liệu tham khảo: *i.MX 6ULL Applications Processor Reference Manual, Rev. 1, 11/2017 — NXP Semiconductors*

---

## 5.1 Boot Fusemap

Phần này mô tả các chế độ boot và cách chọn thiết bị boot tương ứng. Mỗi thiết bị boot có một bảng fusemap riêng. Việc chọn thiết bị được xác định bởi các fuse `BOOT_CFG1[6:4]`.

---

### Bảng 5-1. Boot Device Select (BOOT_CFG1[7:0])

| Boot Device | [7] | [6] | [5] | [4] | [3] | [2] | [1] | [0] |
|-------------|-----|-----|-----|-----|-----|-----|-----|-----|
| **QSPI** | 0 | 0 | 0 | 1 | 0 | - | QSPI0 | DDRSMP: `000`=Default, `001–111` |
| **WEIM** | 0 | 0 | 0 | 0 | Memory Type: `0`=NOR Flash, `1`=OneNAND | Reserved | Reserved | Reserved |
| **Serial-ROM** | 0 | 0 | 1 | 1 | Reserved | Reserved | Reserved | Reserved |
| **SD/eSD** | 0 | 1 | 0 | Fast Boot: `0`=Regular, `1`=Fast | SD/SDXC Speed: `00`=Normal/SDR12, `01`=High/SDR25, `10`=SDR50, `11`=SDR104 | SD/SDXC Speed (cont.) | SD Power Cycle Enable | SD Loopback Clock Source Sel |
| **MMC/eMMC** | 0 | 1 | 1 | Fast Boot: `0`=Regular, `1`=Fast | SD/MMC Speed: `0`=Normal, `1`=High | Fast Boot Ack Disable | SD Power Cycle Enable | SD Loopback Clock Source Sel |
| **NAND** | 1 | BT_TOGGLEMODE | Pages in Block: `00`=128, `01`=64, `10`=32, `11`=256 | Pages in Block (cont.) | Nand Num Devices: `00`=1, `01`=2, `10`=4 | Nand Num Devices (cont.) | Nand_Row_Address_Bytes: `00`=3, `01`=2, `10`=4, `11`=5 | Nand_Row_Address_Bytes (cont.) |

> **⚠️ Lưu ý:** Các fuse đánh dấu "Reserved" chỉ dành cho NXP nội bộ. Không được burn các fuse này; hành vi IC có thể không xác định.

---

## 5.2 QSPI Boot Fusemap (Bảng 5-2)

| Địa chỉ | [7] | [6] | [5] | [4] | [3] | [2] | [1] | [0] |
|---------|-----|-----|-----|-----|-----|-----|-----|-----|
| `0x450[7:0]` BOOT_CFG1 | 0 | 0 | 0 | 1 | x | DDRSMP `000`=Default | | |
| `0x450[15:8]` BOOT_CFG2 | Reserved | HSPHS: Half Speed Phase Sel | HSDLY: Half Speed Delay Sel | FSPHS: Full Speed Phase Sel | FSDLY: Full Speed Delay Sel | Boot Freq: `0`=500/400MHz, `1`=250/200MHz | Reserved | Reserved |
| `0x450[23:16]` BOOT_CFG3 | Reserved | | | | | | | |
| `0x460[7:0]` | Reserved | FORCE_COLD_BOOT | BT_FUSE_SEL | DIR_BT_DIS | Reserved | SEC_CONFIG[1] | Reserved | |
| `0x460[15:8]` | Reserved | | | | | | | |
| `0x460[23:16]` | JTAG_SMODE[1:0] | | WDOG_ENABLE | SJC_DISABLE | Reserved | | | |
| `0x460[31:24]` | Reserved | TZASC_ENABLE | JTAG_HEO | KTE | Reserved | DLL_ENABLE | | |
| `0x470[7:0]` | Not used | Reserved | L1 I-Cache DISABLE | BT_MMU_DISABLE | Reserved | | | |
| `0x470[15:8]` | Reserved | Not used | Reserved | ADD_DS_SET_GPR1_16 | Reserved | | | |
| `0x470[23:16]` | Reserved | LPB_BOOT (Core/DDRBus): `00`=Disable, `01`=1 GPIO, `10`=Div/2, `11`=Div/4 | | BT_LPB_POLARITY: `0`=Active High, `1`=Active Low | Reserved | | | |

---

## 5.3 EIM Boot Fusemap (Bảng 5-3)

| Địa chỉ | [7] | [6] | [5] | [4] | [3] | [2] | [1] | [0] |
|---------|-----|-----|-----|-----|-----|-----|-----|-----|
| `0x450[7:0]` BOOT_CFG1 | 0 | 0 | 0 | 0 | Memory Type: `0`=NOR Flash, `1`=OneNAND | Reserved | Reserved | Reserved |
| `0x450[15:8]` BOOT_CFG2 | Muxing Scheme: `00`=A/D16, `01`=A+DH, `10`=A+DL, `11`=Reserved | OneNAND Page Size: `00`=1KB, `01`=2KB, `10`=4KB | Reserved | Boot Freq | Reserved | Reserved | | |
| `0x450[31:24]` BOOT_CFG4 | Reserved | EEPROM Recovery Enable | Reserved (Serial-ROM) | eCSPI Chip Select | eCSPI Addressing | Port Select | | |
| `0x470[7:0]` | DLL Override | SD1_RST_POLARITY | SD2 Voltage: `0`=3.3V, `1`=1.8V | Reserved | Disable SDMMC Mfg Mode | L1 I-Cache DISABLE | BT_MMU_DISABLE | Override SD Pad Settings |
| `0x470[15:8]` | SD2_RST_POLARITY | eMMC 4.4 Reset | Override HYS bit | USDHC_PAD_PULL_DOWN | ENABLE_EMMC_22K_PULLUP | ADD_DS_SET_GPR1_16 | USDHC_IOMUX_SION_BIT | USDHC IOMUX SRE |
| `0x470[31:24]` | Override NAND Pad Settings | MMC_DLL_DLY[6:0] | | | | | | |
| `0x6D0[7:0]` | RANDOMIZER_ENABLE | Reserved | PAD_SETTINGS[5:0] | | | | | |

---

## 5.4 Serial-ROM Boot Fusemap (Bảng 5-4)

| Địa chỉ | [7:4] | [3:0] |
|---------|-------|-------|
| `0x450[7:0]` BOOT_CFG1 | `0011` | Reserved |
| `0x450[15:8]` BOOT_CFG2 | Reserved | Boot Freq: `0`=500/400MHz, `1`=250/200MHz |
| `0x450[31:24]` BOOT_CFG4 | EEPROM Recovery Enable | eCSPI Chip Select / Addressing / Port Select |

*(Các trường 0x460 và 0x470 tương tự EIM Boot Fusemap)*

---

## 5.5 SD/eSD Boot Fusemap (Bảng 5-5)

| Địa chỉ | [7] | [6] | [5] | [4] | [3:2] | [1] | [0] |
|---------|-----|-----|-----|-----|-------|-----|-----|
| `0x450[7:0]` BOOT_CFG1 | 0 | 1 | 0 | Fast Boot | SD/SDXC Speed: `00`=SDR12, `01`=SDR25, `10`=SDR50, `11`=SDR104 | SD Power Cycle | SD Loopback Clock Sel |
| `0x450[15:8]` BOOT_CFG2 | SD Calibration Step | Bus Width: `0`=1-bit, `1`=4-bit | Port Select: `00`=eSDHC1, `01`=eSDHC2 | Boot Freq | SD Voltage: `0`=3.3V, `1`=1.8V | Reserved | |

---

## 5.6 MMC/eMMC Boot Fusemap (Bảng 5-6)

| Địa chỉ | [7] | [6] | [5] | [4] | [3] | [2] | [1] | [0] |
|---------|-----|-----|-----|-----|-----|-----|-----|-----|
| `0x450[7:0]` BOOT_CFG1 | 0 | 1 | 1 | Fast Boot | SD/MMC Speed: `0`=High, `1`=Normal | Fast Boot Ack Disable | SD Power Cycle | SD Loopback Clock Sel |
| `0x450[15:8]` BOOT_CFG2 | Bus Width: `000`=1-bit, `001`=4-bit, `010`=8-bit, `101`=4-bit DDR, `110`=8-bit DDR | Port Select: `00`=eSDHC1, `01`=eSDHC2 | Boot Freq | SD Voltage | Reserved | | | |

---

## 5.7 NAND Boot Fusemap (Bảng 5-7)

| Địa chỉ | [7] | [6] | [5:4] | [3:2] | [1:0] |
|---------|-----|-----|-------|-------|-------|
| `0x450[7:0]` BOOT_CFG1 | 1 | BT_TOGGLEMODE | Pages in Block: `00`=128, `01`=64, `10`=32, `11`=256 | Nand Num Devices: `00`=1, `01`=2, `10`=4 | Row Addr Bytes: `00`=3, `01`=2, `10`=4, `11`=5 |
| `0x450[15:8]` BOOT_CFG2 | Toggle Mode 33MHz Preamble Delay / Read Latency | Boot Search Count: `00`=2, `01`=2, `10`=4, `11`=8 | Boot Freq | Reset Time: `0`=12ms, `1`=22ms | Reserved |
| `0x6D0[23:16]` | NAND_READ_CMD_CODE1[7:0] | | | | |
| `0x6D0[31:24]` | NAND_READ_CMD_CODE2[7:0] | | | | |

---

## 5.8 Lock Fusemap (Bảng 5-8)

| Địa chỉ | Bit | Tên Fuse | Mô tả |
|---------|-----|----------|-------|
| `0x400[1:0]` | 2 | TESTER_LOCK | OCOTP |
| `0x400[3:2]` | 2 | BOOT_CFG_LOCK | Khóa các fuse liên quan BOOT |
| `0x400[5:4]` | 2 | MEM_TRIM_LOCK | Trimming fuses |
| `0x400[6]` | 1 | SJC_RESP_LOCK | OCOTP |
| `0x400[9:8]` | 2 | MAC_ADDR_LOCK | Khóa MAC_ADDR fuses |
| `0x400[11:10]` | 2 | GP1_LOCK | Khóa GP fuse register #1 |
| `0x400[13:12]` | 2 | GP2_LOCK | Khóa GP fuse register #2 |
| `0x400[14]` | 1 | SRK_LOCK | Khóa SRK_HASH[255:0] |
| `0x400[15]` | 1 | GP3_LOCK | Khóa GP fuse register #3 |
| `0x400[31]` | 1 | GP4_RLOCK | Read protection for GP fuse |

---

## 5.9 Fusemap Descriptions (Bảng 5-9 — Tóm tắt quan trọng)

| Địa chỉ Fuse | Tên | Số Fuse | Chức năng | Giá trị |
|-------------|-----|---------|-----------|---------|
| `0x430[21:20]` | TAMPER_PIN_DISABLE[1:0] | 2 | Disable tamper pins | `00`=enabled, `11`=tất cả GPIO |
| `0x440[17:16]` | SPEED_GRADING[1:0] | 2 | IC core speed | `01`=528MHz, `10`=800MHz, `11`=900MHz |
| `0x450[7:0]` | BOOT_CFG1 | 8 | Boot configuration #1 | Xem bảng thiết bị boot |
| `0x460[1]` | SEC_CONFIG[1] | 1 | Security Configuration | `00`=FAB Open, `1x`=Closed |
| `0x460[3]` | DIR_BT_DIS | 1 | Direct External Memory Boot Disable | `0`=Allowed, `1`=Not allowed |
| `0x460[4]` | BT_FUSE_SEL | 1 | Nguồn cấu hình boot | `0`=GPIO, `1`=Fuses |
| `0x460[20]` | SJC_DISABLE | 1 | Disable Secure JTAG Controller | `0`=Enabled, `1`=Disabled |
| `0x460[21]` | WDOG_ENABLE | 1 | Watchdog Enable | `0`=Disabled, `1`=Enabled |
| `0x460[23:22]` | JTAG_SMODE[1:0] | 2 | JTAG Security Mode | `00`=Enable, `01`=Secure, `11`=No debug |
| `0x460[24]` | DLL_ENABLE | 1 | DLL cho SD/eMMC | `0`=Disable, `1`=Enable |
| `0x460[28]` | TZASC_ENABLE | 1 | TZASC enable | `0`=Bypass, `1`=Enabled by Boot ROM |
| `0x470[1]` | BT_MMU_DISABLE | 1 | ROM không enable MMU | — |
| `0x470[2]` | L1 I-Cache DISABLE | 1 | ROM không enable L1 I-Cache | — |
| `0x4F0[15:0]` | USB_VID | 16 | USB Vendor ID | — |
| `0x4F0[31:16]` | USB_PID | 16 | USB Product ID | — |
| `0x580[31:0]` | SRK_HASH[255:0] | 256 | SRK key (HAB) | — |
| `0x620[15:0]` | MAC1_ADDR[47:0] | 48 | Ethernet1 MAC Address | — |
| `0x660[31:0]` | GP1[31:0] | 32 | General Purpose fuse #1 | — |
| `0x670[31:0]` | GP2[31:0] | 32 | General Purpose fuse #2 | — |
| `0x6D0[5:0]` | PAD_SETTINGS | 6 | IO pad override settings | `[0]`=Slew Rate, `[3:1]`=Drive Strength, `[5:4]`=Speed |
| `0x6D0[15:13]` | WDOG Timeout Select | 3 | Chọn timeout WDOG | `000`=64s, `001`=32s, `010`=16s, `011`=8s, `100`=4s |
| `0x6E0[0]` | FIELD_RETURN | 1 | Field return testing | `0`=Secure, `1`=Open for testing |
| `0x880–0x8B0` | GP3[127:0] | 128 | General Purpose fuse #3 | — |
| `0x8C0–0x8F0` | GP4[127:0] | 128 | General Purpose fuse #4 | — |

---

*Tài liệu được chuyển đổi từ Chapter 5 — i.MX 6ULL Applications Processor Reference Manual, Rev. 1, 11/2017, NXP Semiconductors.*