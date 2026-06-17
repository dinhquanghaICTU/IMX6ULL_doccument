# Chapter 35: Multi Mode DDR Controller (MMDC)

## 35.1 Overview

MMDC is a multi-mode DDR controller that supports DDR3/DDR3L x16 and LPDDR2 x16 memory types. MMDC is configurable, high performance, and optimized.

MMDC consists of two main parts:

- **MMDC_CORE** – Responsible for communication with the system through an AXI interface, DDR command generation, DDR command optimizations, and a read/write data path.
- **MMDC_PHY** – Responsible for timing adjustment; uses special calibration mechanisms to ensure data capture margin at a clock rate of up to 400 MHz.

The internal memory map (configuration registers) of the MMDC can be configured through an IP channel (IP0).

---

### 35.1.1 MMDC Feature Summary

| Feature | Details |
|---|---|
| DDR Standards | DDR3L, DDR3 x16; LPDDR2 x16. Does **not** support LPDDR1, MDDR, or DDR2 |
| DDR Interface | x16 data bus width; Density 256 Mbits–8 Gbits; Column 8–12 bits; Row 11–16 bits; 2 chip selects; Up to 4 GB address space |
| DDR Performance | Up to 400 MHz (800 MT/s); QoS priority; Page hit/miss optimization; Bank interleaving |
| AXI Interface | AXI compliant; 8/16/64-bit transfers at 400 MHz; Burst up to 16; WRAP, INCR, FIXED burst types; 16-bit AXI ID |
| DDR Calibration | ZQ calibration; Read/Write data calibration; Read DQS gating; Write leveling; Fine tuning delay lines |
| Power Saving | DVFS; Self-refresh (HW/SW); Automatic power down; Clock gating |

---

## 35.2 External Signals

| Signal | Description | Direction |
|---|---|---|
| DRAM_ADDR[15:0] | Address Bus Signals | O |
| DRAM_CAS | Column Address Strobe | O |
| DRAM_CS[1:0] | Chip Selects | O |
| DRAM_DATA[31:0] | Data Bus Signals | I/O |
| DRAM_DQM[1:0] | Data Mask Signals | O |
| DRAM_ODT[1:0] | On-Die Termination Signals | O |
| DRAM_RAS | Row Address Strobe | O |
| DRAM_RESET | Reset Signal | O |
| DRAM_SDBA[2:0] | Bank Select Signals | O |
| DRAM_SDCKE[1:0] | Clock Enable Signals | O |
| DRAM_SDCLK0_N | Negative Clock Signal | O |
| DRAM_SDCLK0_P | Positive Clock Signal | O |
| DRAM_SDQS[1:0]_N | Negative DQS Signals | I/O |
| DRAM_SDQS[1:0]_P | Positive DQS Signals | I/O |
| DRAM_SDWE | WE Signal | O |
| DRAM_ZQPAD | ZQ Signal | O |

---

## 35.3 Clocks

| Clock Name | Clock Root | Description |
|---|---|---|
| aclk_fast_core_p0 | mmdc_axi_clk_root | Fast clock (channel 1) |
| ipg_clk_p0 | ipg_clk_root | Peripheral clock (channel 1) |
| aclk_fast_phy_p0 | mmdc_axi_clk_root | Fast clock (channel 1 – PHY) |

> **Note:** The terms *clocks* and *cycles* are used interchangeably and refer to the clock period of the main DDR clock (`mmdc_axi_clk_root`).

---

## 35.4 Functional Description

### 35.4.1 Write/Read Data Flow

#### 35.4.1.1 Write Data Flow

1. Write requests are received into an 8-entry request FIFO (access accepted when ≥2 entries available).
2. Round-robin arbitration between pending read/write accesses; winner pointer sent to re-ordering buffer.
3. Reordering mechanism selects the access with the highest dynamic score.
4. Winner write access is held for dispatch to DDR logic.
5. DDR command control unit issues precharge/active command as needed.
6. DDR logic drives data to the DDR device through the DDR PHY.

#### 35.4.1.2 Read Data Flow

1. Read requests are received into a 16-entry request FIFO (accepted when ≥2 entries available).
2. Round-robin arbitration selects winner; pointer sent to re-ordering buffer.
3. Reordering mechanism selects the highest-score access.
4. Winner read access held; dispatched when a free slot exists in the read data buffer.
5. DDR command control unit issues precharge/active command as needed.
6. MMDC PHY samples read data; DDR logic transfers data to the read data buffer slot.
7. MMDC transfers data back to master.

---

### 35.4.2 MMDC Initialization

> **Note:** DRAM_RESET and DRAM_SDCKE must be connected to pull-down resistors to remain low during power-up.

**Initialization Steps:**

1. Set `MDSCR[CON_REQ]` to assert configuration request.
2. Configure timing parameters: `MDCFG0`, `MDCFG1`, `MDOTC`, `MDCFG2`.
3. Configure DDR type at `MDMISC`.
4. Configure reset delays at `MDOR`.
5. Configure DDR physical parameters (density, burst length) at `MDCTL`.
6. Perform ZQ calibration of MMDC module.
7. Enable MMDC with desired chip select at `MDCTL[SDE_0]` / `MDCTL[SDE_1]`.
8. Complete JEDEC initialization sequence (MRS/MRW commands via `MDSCR`).
9. Program DDR mode registers via `MDSCR`.
10. Configure power down/self-refresh parameters at `MDPDC` and `MAPSR`.
11. Configure ZQ scheme at `MPZQHWCTRL` and `MPZQLP2CTL`.
12. Configure and activate periodic refresh at `MDREF`.
13. Deassert configuration request by clearing `MDSCR[CON_REQ]`.

> Steps 1–6 are non-blocking and can be done in any order.

---

### 35.4.3 Configuring MMDC Registers (Configuration Mode)

1. Set `MDSCR[CON_REQ]`.
2. Poll `MDSCR[CON_ACK]` until set.
3. Modify registers as needed.
4. Deassert `MDSCR[CON_REQ]` to exit configuration mode.

> During configuration mode, MMDC prevents further AXI accesses from being acknowledged.

---

### 35.4.4 MMDC Address Space

#### 35.4.4.1 Address Decoding

Decoding order: chip select → bank number → row number → column number.

Relevant registers:
- `MDMISC[DDR_4_BANK]` – 4 or 8 banks
- `MDCTL[DSIZ]` – DDR data bus width
- `MDMISC[BI]` – Bank interleaving on/off
- `MDCTL[COL]` – Column size
- `MDCTL[ROW]` – Row size

**Address Decoding – Bank Interleaving OFF (x16 DDR):**

| AXI Address | x16 DDR |
|---|---|
| A28 | BANK[2] |
| A27 | BANK[1] |
| A26 | BANK[0] |
| A25–A11 | ROW[14:0] |
| A10–A1 | COL[9:0] |

**Address Decoding – Bank Interleaving ON (x16 DDR):**

| AXI Address | x16 DDR |
|---|---|
| A28–A14 | ROW[14:0] |
| A13 | BANK[2] |
| A12 | BANK[1] |
| A11 | BANK[0] |
| A10–A1 | COL[9:0] |

#### 35.4.4.2 Chip Select Settings

Chip select is determined by comparing the 7 MSBs of the AXI address with `MDASP[CS0_END]`.

- **4 GB space (2 GB per CS):** `MDASP[CS0_END]` = `011_1111`
- **2 GB space (1 GB per CS):** Options at `001_1111`, `011_1111`, or `101_1111`

#### 35.4.4.4 Address Mirroring

When enabled, certain address/bank bits are swapped for chip select 1 to facilitate PCB routing.

| MMDC Pin | CS0 Pin | CS1 Pin |
|---|---|---|
| DRAM_A3 | DRAM_A3 | DRAM_A4 |
| DRAM_A4 | DRAM_A4 | DRAM_A3 |
| DRAM_A5 | DRAM_A5 | DRAM_A6 |
| DRAM_A6 | DRAM_A6 | DRAM_A5 |
| DRAM_A7 | DRAM_A7 | DRAM_A8 |
| DRAM_A8 | DRAM_A8 | DRAM_A7 |
| DRAM_SDBA0 | DRAM_SDBA0 | DRAM_SDBA1 |
| DRAM_SDBA1 | DRAM_SDBA1 | DRAM_SDBA0 |

> **Note:** Address mirroring is not supported for DDR3 (single chip select only).

---

### 35.4.6 Power Saving and Clock Frequency Change Modes

MMDC supports:

1. **Self-Refresh Entry** via:
   - LPMD (Low Power Mode): hardware or software handshaking
   - DVFS (Dynamic Voltage and Frequency Change): hardware or software handshaking
   - Automatic entry after idle cycles (configured via `MAPSR[PST]`)

2. **Automatic Power Down** per chip select via `MDPDC`:
   - `PWDT_0/PWDT_1` – idle cycle threshold per CS
   - `SLOW_PD` – slow precharge power down (DDR3)
   - `BOTH_CS_PS` – require both CS idle before power down

3. **Automatic Precharge** via `MDPDC[PRCT_0]` and `MDPDC[PRCT_1]`.

#### Self-Refresh / DVFS Entry Sequence:
- Block AXI accesses
- Complete open AXI accesses
- Precharge all banks
- Drive self-refresh command (deassert DRAM_SDCKE)
- Gate DDR clock (CK)
- Assert LPACK/DVACK

#### Exit Sequence:
- Restart DDR clock (CK)
- Reassert DRAM_SDCKE after `tCKSRX`
- Deassert LPACK/DVACK
- Issue refresh command after `tXS`
- Optionally issue long ZQ command
- Return to normal after `tDLLK`

---

### 35.4.7 Reset

| Reset Type | Description |
|---|---|
| Hard Reset | Full initialization including config registers and state machines |
| Warm Reset | Resets internal registers but preserves config needed for normal operation (no re-init required) |
| Software Reset | Similar to warm reset; triggered by setting `MDMISC[RST]` |

**Warm Reset Sequence:**
1. Enter self-refresh (LPMD or DVFS)
2. Wait for LPACK/DVACK
3. Assert warm_reset
4. Assert aresetn (hard reset)
5. Deassert aresetn
6. Deassert warm_reset
7. Exit LPMD/DVFS

---

### 35.4.8 Refresh Scheme

Refresh is configured via `MDREF`. Trigger sources:

- 32 kHz clock
- 64 kHz clock
- MMDC operating clock (via `REF_CNT`)

| Option | Description | REFR | REF_SEL | DDR Hang Time |
|---|---|---|---|---|
| 1 | 8 refreshes every 31,250 ns | 0x7 | 0x0 (64 kHz) | tRFC × 8 |
| 2 | 4 refreshes every 15,625 ns | 0x3 | 0x1 (32 kHz) | tRFC × 4 |
| 3 | 2 refreshes every 7,800 ns | 0x1 | 0x2 (REF_CNT) | tRFC × 2 |
| 4 | 1 refresh every 3,900 ns | 0x0 | 0x2 (REF_CNT) | tRFC |

---

### 35.4.9 Burst Length

- **DDR3 mode:** Only burst length 8 is supported.
- **LPDDR2 mode:** Only burst length 4 is supported.

---

### 35.4.10 Exclusive Accesses

MMDC contains 4 exclusive monitors (configured in `MAEXIDR0` / `MAEXIDR1`).

Requirements for successful exclusive access:
- Aligned access
- AXI single access (burst length ≤ 1)
- AXI size ≤ 64 bits
- Non-cacheable
- Matching exclusive monitor ID

---

## 35.5 Performance

### 35.5.1 Arbitration and Reordering

**Dynamic Score Calculation:**

```
final_score[3:0] = QoS + access_hit_score + page_hit_score + dynamic_jump_score
                   (clipped to max 0xF)
```

**Scoring Factors:**

| Factor | Register Field | Description |
|---|---|---|
| Page Hit | `MAARCR[ARCR_PAG_HIT]` | Added if access targets an open DDR row |
| Access Hit | `MAARCR[ARCR_ACC_HIT]` | Added if access type matches previous |
| Dynamic Jump | `MAARCR[ARCR_DYN_JMP]` | Incremented each time access is not chosen |
| QoS | AXI sideband `awqos/arqos` | Driven by AXI master |

#### Real-Time Channel Mode
Accesses with `QoS = 0xF` bypass all other pending requests (`MAARCR[ARCR_RCH_EN] = 1`).

#### Guarding (Aging) Mechanism
When dynamic jump reaches `ARCR_DYN_MAX`, a guarding counter increments. When it reaches `ARCR_GUARD`, the access gains highest priority.

---

### 35.5.2 Prediction Mechanism

Enabled via `MDMISC[MIF3_MODE]`. Predicts chip-select, bank, and row address ahead of dispatch. Three levels:

1. Access in first stage of pipeline
2. Valid access on AXI bus
3. Next miss access from arbitration queue

---

## 35.6 MMDC Debug

### 35.6.1 Hardware Debug Monitor

Enabled by setting `MADPCR0[DBG_EN] = 1`.

Output bus `ipp_do_ddr_debug[50:0]` layout:

```
MMDC_DEBUG[50:0] = {1'b0, valid_strobe, acc_id[15:0], access_type, addr[31:0]}
```

| Field | Bits | Description |
|---|---|---|
| acc_addr | [31:0] | AXI address of selected access |
| acc_type | 1 | 0 = write, 1 = read |
| acc_id | [15:0] | AXI transaction ID |
| valid_strobe | 1 | Valid request indicator (1 cycle) |

### 35.6.2 Step-By-Step (SBS) Software Monitor

- Enable: `MADPCR0[SBS_EN] = 1`
- Trigger one access: `MADPCR0[SBS] = 1` (auto-clears)
- Access attributes captured in `MASBS0` and `MASBS1`

---

## 35.7 MMDC Profiling

Profiling counters (all 32-bit):

| Register | Description |
|---|---|
| MADPSR0 | Total cycle count |
| MADPSR1 | Busy cycle count |
| MADPSR2 | Total read access count |
| MADPSR3 | Total write access count |
| MADPSR4 | Total read bytes |
| MADPSR5 | Total write bytes |

**Control:**
- `MADPCR0[DBG_EN]` – Enable profiling
- `MADPCR0[PRF_FRZ]` – Freeze profiling
- `MADPCR0[DBG_RST]` – Reset all counters

**AXI ID filtering** via `MADPCR1`:
```
Monitor if: (AXI_ID & PRF_AXI_ID_MASK) XNOR (PRF_AXI_ID & PRF_AXI_ID_MASK)
```

---

## 35.8 LPDDR2 Refresh Rate Update and Timing Derating

MR4 read sequence:
1. Set `MAPSR` to `0x00010107`
2. Set `MDPDC` to `0x00020076`
3. Issue MRR command to read MR4
4. Write `MDPDC` to `0x00025576` (re-enable)
5. Write `MAPSR` to `0x00010106` (re-enable)

Derating update: set `MDMR4[UPDATE_DE_REQ]`, poll `MDMR4[UPDATE_DE_ACK]`.

---

## 35.9 DLL Switching

### DLL Off Mode (DDR3 only, < 125 MHz)

**DLL On → DLL Off:**
1. Assert CON_REQ, wait CON_ACK
2. Disable conflicting power-down timers
3. Precharge all banks
4. MRW to MR1: disable RTT Nom, set DLL ON bit
5. MRW to MR2: set CWL = 6
6. MRW to MR0: set CL = 6
7. Deassert CON_REQ
8. Enter self-refresh; change frequency; exit self-refresh
9. Assert CON_REQ, wait CON_ACK
10. Enable pull-down resistors on DQS
11. Update `tCWL`, `tCL`; disable ODT; disable DQS gating
12. Deassert CON_REQ

---

## 35.10 ODT Configuration

- `MDOTC` controls ODT timing.
- `tODTLon` = WL − 2 (must match `MDCFG1[tCWL]`).
- `MPODTCTRL` controls assertion behavior per read/write, active/passive CS.

---

## 35.11 Calibration Process

> **Note:** Disable power saving features before calibration (`MDPDC[PWDTn]`, `MDPDC[PRCTn]`, `MAPSR[PSD]`).

### Calibration Types

| Calibration | Purpose |
|---|---|
| ZQ (external DDR) | Calibrate DDR device drive strength |
| ZQ (i.MX pads) | Calibrate DDR I/O pad drive strength |
| Read DQS Gating | Align DQS gate with read preamble (DDR3 only) |
| Read Data | Align read DQS with read data byte |
| Write Data | Align write DQS with write data byte |
| Write Leveling | Align write DQS with DDR clock (CK) |
| Read Fine Tuning | Per-bit delay adjustment (up to 7 units) |
| Write Fine Tuning | Per-bit delay adjustment (up to 3 units) |

### 35.11.1 Delay-Line

- Default: 1/4 clock cycle delay
- At maximum frequency: configurable up to 1/2 clock cycle
- Automatic measurement during refresh interval maintains accuracy

### 35.11.2 ZQ Calibration

Two types:
- **ZQ Long:** At power-up, self-refresh exit, or slow power-down exit
- **ZQ Short:** Periodic, configured by `MPZQHWCTRL[ZQ_HW_PER]`

`MPZQHWCTRL[ZQ_MODE]`:

| Value | Mode |
|---|---|
| 0x0 | No ZQ calibration |
| 0x1 | ZQ to i.MX pad + ZQ Long to DDR at self-refresh exit |
| 0x2 | ZQ Short/Long to DDR only (periodic + self-refresh exit) |
| 0x3 | Both i.MX pad and DDR device (periodic + self-refresh exit) |

### 35.11.6 Write Leveling

Total delay = `(WL_DL_ABS_OFFSET/256 × cycle) + (WL_HC_DEL × half cycle) + (WL_CYC_DEL × cycle)`

**HW Write Leveling Steps:**
1. Configure DDR device to write leveling mode (MRS)
2. Set `MDSCR[WL_EN] = 1`
3. Set `MPWLGCR[HW_WL_EN] = 1`
4. HW automatically sweeps delay, finds 0→1 transition, stores result
5. Issue MRS to exit write leveling mode
6. Clear `MDSCR[WL_EN]`

### 35.11.7 Write Fine Tuning

Per-bit DQ/DM delay relative to DQS. Up to 3 delay units (~30–35 ps each). Controlled by `MPWRDQBYnDL` registers.

### 35.11.8 Read Fine Tuning

Per-bit DQ delay relative to DQS. Up to 6 delay units (+/-100 ps). Controlled by `MPRDDQBYnDL` registers.

### 35.11.9 ZQ Fine Tuning

Offset range: −7 to +7 applied to PU/PD values.

- `MPPDCMPR2[ZQ_PU_OFFSET]`
- `MPPDCMPR2[ZQ_PD_OFFSET]`
- `MPPDCMPR2[ZQ_OFFSET_EN]`

### 35.11.10 Duty Cycle Adjustment

Controlled by `MPDCCR` for SDCLKx and SDQSx signals.

---

## 35.12 MMDC Memory Map / Register Definition

### Register Map Summary

| Address | Register | Access | Reset Value |
|---|---|---|---|
| 21B_0000h | MMDC_MDCTL | R/W | 0311_0000h |
| 21B_0004h | MMDC_MDPDC | R/W | 0003_0012h |
| 21B_0008h | MMDC_MDOTC | R/W | 1227_2000h |
| 21B_000Ch | MMDC_MDCFG0 | R/W | 3236_22D3h |
| 21B_0010h | MMDC_MDCFG1 | R/W | B6B1_8A23h |
| 21B_0014h | MMDC_MDCFG2 | R/W | 00C7_0092h |
| 21B_0018h | MMDC_MDMISC | R/W | 0000_1600h |
| 21B_001Ch | MMDC_MDSCR | R/W | 0000_0000h |
| 21B_0020h | MMDC_MDREF | R/W | 0000_C000h |
| 21B_002Ch | MMDC_MDRWD | R/W | 0F9F_26D2h |
| 21B_0030h | MMDC_MDOR | R/W | 009F_0E0Eh |
| 21B_0034h | MMDC_MDMRR | R | 0000_0000h |
| 21B_0038h | MMDC_MDCFG3LP | R/W | 0000_0000h |
| 21B_003Ch | MMDC_MDMR4 | R/W | 0000_0000h |
| 21B_0040h | MMDC_MDASP | R/W | 0000_003Fh |
| 21B_0400h | MMDC_MAARCR | R/W | 5142_01F0h |
| 21B_0404h | MMDC_MAPSR | R/W | 0000_1007h |
| 21B_0408h | MMDC_MAEXIDR0 | R/W | 0020_0000h |
| 21B_040Ch | MMDC_MAEXIDR1 | R/W | 0060_0040h |
| 21B_0410h | MMDC_MADPCR0 | R/W | 0000_0000h |
| 21B_0414h | MMDC_MADPCR1 | R/W | 0000_0000h |
| 21B_0418h | MMDC_MADPSR0 | R | 0000_0000h |
| 21B_041Ch | MMDC_MADPSR1 | R | 0000_0000h |
| 21B_0420h | MMDC_MADPSR2 | R | 0000_0000h |
| 21B_0424h | MMDC_MADPSR3 | R | 0000_0000h |
| 21B_0428h | MMDC_MADPSR4 | R | 0000_0000h |
| 21B_042Ch | MMDC_MADPSR5 | R | 0000_0000h |
| 21B_0430h | MMDC_MASBS0 | R | 0000_0000h |
| 21B_0434h | MMDC_MASBS1 | R | 0000_0000h |
| 21B_0440h | MMDC_MAGENP | R/W | 0000_0000h |
| 21B_0800h | MMDC_MPZQHWCTRL | R/W | A138_0000h |
| 21B_0804h | MMDC_MPZQSWCTRL | R/W | 0000_0000h |
| 21B_0808h | MMDC_MPWLGCR | R/W | 0000_0000h |
| 21B_080Ch | MMDC_MPWLDECTRL0 | R/W | 0000_0000h |
| 21B_0810h | MMDC_MPWLDECTRL1 | R/W | 0000_0000h |
| 21B_0814h | MMDC_MPWLDLST | R | 0000_0000h |
| 21B_0818h | MMDC_MPODTCTRL | R/W | 0000_0000h |
| 21B_081Ch | MMDC_MPRDDQBY0DL | R/W | 0000_0000h |
| 21B_0820h | MMDC_MPRDDQBY1DL | R/W | 0000_0000h |
| 21B_082Ch | MMDC_MPWRDQBY0DL | R/W | 0000_0000h |
| 21B_0830h | MMDC_MPWRDQBY1DL | R/W | 0000_0000h |
| 21B_0834h | MMDC_MPWRDQBY2DL | R/W | 0000_0000h |
| 21B_0838h | MMDC_MPWRDQBY3DL | R/W | 0000_0000h |
| 21B_083Ch | MMDC_MPDGCTRL0 | R/W | 0000_0000h |
| 21B_0840h | MMDC_MPDGCTRL1 | R/W | 0000_0000h |
| 21B_0844h | MMDC_MPDGDLST0 | R | 0000_0000h |
| 21B_0848h | MMDC_MPRDDLCTL | R/W | 4040_4040h |
| 21B_084Ch | MMDC_MPRDDLST | R | 0000_0000h |
| 21B_0850h | MMDC_MPWRDLCTL | R/W | 4040_4040h |
| 21B_0854h | MMDC_MPWRDLST | R | 0000_0000h |
| 21B_0858h | MMDC_MPSDCTRL | R/W | 0000_0000h |
| 21B_085Ch | MMDC_MPZQLP2CTL | R/W | 1B5F_0109h |
| 21B_0860h | MMDC_MPRDDLHWCTL | R/W | 0000_0000h |
| 21B_0864h | MMDC_MPWRDLHWCTL | R/W | 0000_0000h |
| 21B_0868h | MMDC_MPRDDLHWST0 | R | 0000_0000h |
| 21B_0870h | MMDC_MPWRDLHWST0 | R | 0000_0000h |
| 21B_0878h | MMDC_MPWLHWERR | R/W | 0000_0000h |
| 21B_087Ch | MMDC_MPDGHWST0 | R | 0000_0000h |
| 21B_0880h | MMDC_MPDGHWST1 | R | 0000_0000h |
| 21B_0884h | MMDC_MPDGHWST2 | R | 0000_0000h |
| 21B_0888h | MMDC_MPDGHWST3 | R | 0000_0000h |
| 21B_088Ch | MMDC_MPPDCMPR1 | R/W | 0000_0000h |
| 21B_0890h | MMDC_MPPDCMPR2 | R/W | 0040_0000h |
| 21B_0894h | MMDC_MPSWDAR0 | R/W | 0000_0000h |
| 21B_0898h–21B_08B4h | MMDC_MPSWDRDRn (0–7) | R | FFFF_FFFFh |
| 21B_08B8h | MMDC_MPMUR0 | R/W | 0000_0000h |
| 21B_08BCh | MMDC_MPWRCADL | R/W | 0000_0000h |
| 21B_08C0h | MMDC_MPDCCR | R/W | 2492_2492h |

---

### 35.12.1 MMDC_MDCTL – Core Control Register (0x21B_0000)

| Field | Bits | Description |
|---|---|---|
| SDE_0 | [31] | Enable CS0 (0=Disabled, 1=Enabled) |
| SDE_1 | [30] | Enable CS1 (0=Disabled, 1=Enabled) |
| ROW | [26:24] | Row address width (000=11bit … 101=16bit) |
| COL | [22:20] | Column address width (0x0=9bit, 0x1=10bit, 0x2=11bit, 0x3=8bit, 0x4=12bit) |
| BL | [19] | Burst Length (0=BL4, 1=BL8) |
| DSIZ | [17:16] | DDR data bus size (0=16-bit) |

---

### 35.12.2 MMDC_MDPDC – Power Down Control Register (0x21B_0004)

| Field | Bits | Description |
|---|---|---|
| PRCT_1 | [30:28] | Precharge timer for CS1 |
| PRCT_0 | [26:24] | Precharge timer for CS0 |
| tCKE | [18:16] | CKE minimum pulse width |
| PWDT_1 | [15:12] | Power down timer for CS1 |
| PWDT_0 | [11:8] | Power down timer for CS0 |
| SLOW_PD | [7] | 0=Fast, 1=Slow power down (DDR3) |
| BOTH_CS_PD | [6] | Both CS must be idle before power down |
| tCKSRX | [5:3] | Clock cycles before self-refresh exit |
| tCKSRE | [2:0] | Clock cycles after self-refresh entry |

---

### 35.12.7 MMDC_MDMISC – Miscellaneous Register (0x21B_0018)

| Field | Bits | Description |
|---|---|---|
| CS0_RDY | [31] | CS0 device ready status |
| CS1_RDY | [30] | CS1 device ready status |
| CK1_GATING | [21] | Gate secondary DDR clock |
| CALIB_PER_CS | [20] | Calibration target CS (0=CS0, 1=CS1) |
| ADDR_MIRROR | [19] | Address mirroring enable |
| LHD | [18] | Latency hiding disable (debug) |
| WALAT | [17:16] | Write additional latency (0–3 cycles) |
| BI_ON | [12] | Bank interleaving on |
| LPDDR2_S2 | [11] | LPDDR2 S2 device type |
| MIF3_MODE | [10:9] | Command prediction level (00=off … 11=full) |
| RALAT | [8:6] | Read additional latency (0–7 cycles) |
| DDR_4_BANK | [5] | 0=8 banks, 1=4 banks |
| DDR_TYPE | [4:3] | 0x0=DDR3, 0x1=LPDDR2 |
| RST | [1] | Software reset (auto-clears) |

---

### 35.12.8 MMDC_MDSCR – Special Command Register (0x21B_001C)

| Field | Bits | Description |
|---|---|---|
| CMD_ADDR_MSB_MR_OP | [31:24] | Command address MSB / MRW operand |
| CMD_ADDR_LSB_MR_ADDR | [23:16] | Command address LSB / MRR/MRW address |
| CON_REQ | [15] | Configuration request |
| CON_ACK | [14] | Configuration acknowledge (read-only) |
| MRR_READ_DATA_VALID | [10] | MRR data valid (LPDDR2 only) |
| WL_EN | [9] | DQS pad direction for write leveling |
| CMD | [6:4] | Command (0=Normal, 2=Auto-Refresh, 3=MRS/MRW, 4=ZQ, 5=Precharge all, 6=MRR) |
| CMD_CS | [3] | Target chip select (0=CS0, 1=CS1) |
| CMD_BA | [2:0] | Bank address |

---

### 35.12.9 MMDC_MDREF – Refresh Control Register (0x21B_0020)

| Field | Bits | Description |
|---|---|---|
| REF_CNT | [31:16] | Refresh counter (DDR clock periods, used when REF_SEL=2) |
| REF_SEL | [15:14] | 0=64kHz, 1=32kHz, 2=REF_CNT, 3=disabled |
| REFR | [13:11] | Number of refreshes per cycle (0=1 … 7=8) |
| START_REF | [0] | Manual refresh trigger (auto-clears) |

---

### 35.12.16 MMDC_MAARCR – AXI Reordering Control Register (0x21B_0400)

| Field | Bits | Description |
|---|---|---|
| ARCR_SEC_ERR_LOCK | [31] | Lock ARCR_SEC_ERR_EN |
| ARCR_SEC_ERR_EN | [30] | Security violation → SLV Error (1) or OKAY (0) |
| ARCR_EXC_ERR_EN | [28] | Exclusive violation → SLV Error (1) or OKAY (0) |
| ARCR_RCH_EN | [24] | Real-time channel enable (QoS=0xF bypass) |
| ARCR_PAG_HIT | [22:20] | Page hit score |
| ARCR_ACC_HIT | [18:16] | Access hit score |
| ARCR_DYN_JMP | [11:8] | Dynamic jump increment per miss |
| ARCR_DYN_MAX | [7:4] | Maximum dynamic score (default 15) |
| ARCR_GUARD | [3:0] | Guard count before highest priority granted |

---

### 35.12.17 MMDC_MAPSR – Power Saving Control Register (0x21B_0404)

| Field | Bits | Description |
|---|---|---|
| DVACK | [25] | DVFS/self-refresh acknowledge (read-only) |
| LPACK | [24] | Low-power acknowledge (read-only) |
| DVFS | [21] | DVFS/self-refresh request |
| LPMD | [20] | LPMD request |
| PST | [15:8] | Auto power-save timer (× 64 cycles) |
| WIS | [6] | Write idle status |
| RIS | [5] | Read idle status |
| PSS | [4] | Power saving status |
| PSD | [0] | Auto power saving disable (default=1/disabled) |

---

### 35.12.31 MMDC_MPZQHWCTRL – ZQ HW Control Register (0x21B_0800)

| Field | Bits | Description |
|---|---|---|
| ZQ_EARLY_COMPARATOR_EN_TIMER | [31:27] | Comparator warm-up timer |
| TZQ_CS | [25:23] | ZQ short calibration cycles |
| TZQ_OPER | [22:20] | ZQ long calibration cycles |
| TZQ_INIT | [19:17] | ZQ init calibration cycles |
| ZQ_HW_FOR | [16] | Force one-time HW ZQ calibration |
| ZQ_HW_PD_RES | [15:11] | Pull-down calibration result |
| ZQ_HW_PU_RES | [10:6] | Pull-up calibration result |
| ZQ_HW_PER | [5:2] | ZQ periodic calibration interval |
| ZQ_MODE | [1:0] | ZQ calibration mode |

---

### 35.12.44 MMDC_MPDGCTRL0 – Read DQS Gating Control 0 (0x21B_083C)

| Field | Bits | Description |
|---|---|---|
| RST_RD_FIFO | [31] | Reset read data FIFO (self-clears) |
| DG_CMP_CYC | [30] | Compare after 32 (1) or 16 (0) cycles |
| DG_DIS | [29] | Disable read DQS gating |
| HW_DG_EN | [28] | Start HW DQS gating calibration (auto-clears) |
| DG_HC_DEL1 | [27:24] | Half-cycle delay for Byte1 (0=0 … 0xD=6.5 cycles) |
| DG_EXT_UP | [23] | Extend upper boundary mode |
| DG_DL_ABS_OFFSET1 | [22:16] | Absolute delay offset for Byte1 |
| HW_DG_ERR | [12] | HW DQS gating error flag |
| DG_HC_DEL0 | [11:8] | Half-cycle delay for Byte0 |
| DG_DL_ABS_OFFSET0 | [6:0] | Absolute delay offset for Byte0 |

---

### 35.12.73 MMDC_MPMUR0 – Measure Unit Register (0x21B_08B8)

| Field | Bits | Description |
|---|---|---|
| MU_UNIT_DEL_NUM | [25:16] | Measured delay units per cycle (read-only) |
| FRC_MSR | [11] | Force measurement on delay-lines (self-clears) |
| MU_BYP_EN | [10] | Enable bypass mode (debug) |
| MU_BYP_VAL | [9:0] | Bypass delay unit value |

---

### 35.12.75 MMDC_MPDCCR – Duty Cycle Control Register (0x21B_08C0)

| Field | Bits | Description |
|---|---|---|
| RD_DQS1_FT_DCC | [24:22] | Read DQS1 duty cycle (001/010/100) |
| RD_DQS0_FT_DCC | [21:19] | Read DQS0 duty cycle |
| CK_FT1_DCC | [18:16] | Secondary DDR clock duty cycle |
| CK_FT0_DCC | [14:12] | Primary DDR clock duty cycle |
| WR_DQS1_FT_DCC | [5:3] | Write DQS1 duty cycle |
| WR_DQS0_FT_DCC | [2:0] | Write DQS0 duty cycle |

> Duty cycle options: `001`=48.5/51.5%, `010`=50% (default), `100`=51.5/48.5%

---

*Source: i.MX 6ULL Applications Processor Reference Manual, Rev. 1, 11/2017 – NXP Semiconductors*