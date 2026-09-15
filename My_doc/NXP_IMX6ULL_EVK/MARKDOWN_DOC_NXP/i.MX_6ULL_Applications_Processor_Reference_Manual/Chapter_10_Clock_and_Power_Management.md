# Chapter 10: Clock and Power Management

---

## 10.3 Clock Management

### 10.3.1 Centralized Components of Clock Management System

The clock generation and management system is built around the **CCM** (Clock Controller Module) and **LPCG** (Low Power Clock Gating) blocks.

A high-level block diagram of the clock management system in the SoC environment is shown in the figure below:

```text
                  +-------------------------------------------------------------+
                  |                      Clock Generation                       |
                  |                                                             |
OSC 32.768K ----->|  32K_CLK                                                    |
OSC 24MHz ------->|  24M_CLK                                                    |
ENET REF_CLK ---->|                                                             |
                  |  PLLs:                                                      |
                  |  - ARM_PLL (PLL1)        - USB1_PLL & PFDs (PLL3)           |
                  |  - SYS_PLL & PFDs (PLL2) - AUDIO_PLL (PLL4)                 |
                  |  - VIDEO_PLL (PLL5)      - ENET_PLL (PLL6)                  |
                  |  - USB2_PLL (PLL7)                                          |
                  +------------------------------+------------------------------+
                                                 |
                                                 v
                  +-------------------------------------------------------------+
                  |                             CCM                             |
                  |        (Clock Selection and Root Generation Logic)          |
                  |                                                             |
                  |  - Root Clocks: ARM_CLK, Root 1, Root 2, ..., Root xxx      |
                  |  - Frequency Change / Stop Request / Acknowledge            |
                  |  - Manages RUN, WAIT, STOP modes via GPC, PMU, and SRC      |
                  +------------------------------+------------------------------+
                                                 | Root Clocks
                                                 v
                  +-------------------------------------------------------------+
                  |                            LPCG                             |
                  |                 (Clock Gating Logic Units)                  |
                  |                                                             |
                  |  - Mod_1_CLK1/2/X_enable    - Mod_K_CLK1/2/Y_enable         |
                  +------------------------------+------------------------------+
                                                 | Gated Clocks
                                                 v
                            +--------------------+--------------------+
                            |                                         |
                            v                                         v
                      +-----------+                             +-----------+
                      |  Module 1 |                             |  Module K |
                      +-----------+                             +-----------+
```
*Figure 10-2. Clock Management System*

A high-level block diagram of primary clock generation:
```text
  OSC 24M ───┬──► ARM PLL (PLL1) ───────────► ref_armpll_clk (up to 1.3 GHz)
             ├──► 528 PLL (PLL2 / SYS_PLL) ─┬─► ref_528pll_clk (528 MHz)
             │                              ├─► 528 PFD0..3 ──► ref_528pfd0..3_clk
             ├──► USB1 PLL (PLL3 / 480_PLL) ┬─► ref_480pll_clk (480 MHz)
             │                              ├─► 480 PFD0..3 ──► ref_480pfd0..3_clk
             ├──► AUDIO PLL (PLL4) ─────────┴─► ref_audpll_clk (650–1300 MHz, /1/2/4)
             ├──► VIDEO PLL (PLL5) ───────────► ref_vidpll_clk (650–1300 MHz, /1/2/4/8/16)
             ├──► ENET PLL (PLL6) ────────────► ref_enetpll_clk (500 MHz -> 25/50/100/125 MHz)
             └──► USB2 PLL (PLL7) ────────────► ref_usb2pll_clk (480 MHz)
```
*Figure 10-3. Primary Clock Generation*

---

### 10.3.2 Clock Generation

The clock generation section includes the components detailed in the following sections.

#### 10.3.2.1 Crystal Oscillator (XTALOSC)
The Crystal Oscillator block is comprised of both the high-frequency oscillator (typical frequency is **24 MHz**) and the low-frequency real-time clock oscillator (typical frequency of **32.768 kHz**). Each of these oscillators is implemented as a biased amplifier that, when combined with a suitable external quartz crystal and external load capacitors, implements an oscillator.

#### 10.3.2.2 Low Voltage Differential Signaling (LVDS) I/O Ports
There is one LVDS I/O port used for clock generation. The low jitter differential I/O port is provided to input and output clocks. It can take input clocks from outside of the SoC and provide them to the PLLs or to the other modules, or it can take the outputs of the PLLs and provide them outside of the SoC as a functional or reference clock.

#### 10.3.2.3 PLLs (Phase-Locked Loops)
Seven PLLs are included in the clock generation section. Two of these PLLs are each equipped with four Phase Fractional Dividers (PFDs) in order to generate additional frequencies.

> [!NOTE]
> **Phase Fractional Dividers (PFD):**
> Each PFD works independently by interpolating the VCO of the PLL to which it is connected. It effectively takes the PLL VCO frequency and produces $\frac{18}{N} \times F_{\text{vco}}$ at its output, where $N$ ranges from $12$ to $35$. 
> 
> PFD is a completely digital design with no analog components or feedback loops. The frequency switch time is much faster than a PLL because keeping the base PLL locked and changing the integer $N$ only changes the logical combination of the interpolated outputs of the VCO. The PFD allows configuration to be safely changed **"on-the-fly"** without disabling/enabling the output clock.

The seven PLLs are listed below:

1. **PLL1 (ARM_PLL)**:
   * Clocks the ARM core complex.
   * Programmable integer frequency multiplier capable of output frequency up to **1.3 GHz** (note that chip max supported frequency is 1.0 GHz / 792 MHz for i.MX6ULL).
2. **PLL2 (System_PLL / 528_PLL)**:
   * Fixed multiplier of 22, producing **528 MHz** output frequency with 24 MHz reference from XTALOSC.
   * Drives four PFDs (**PLL2_PFD0 – PLL2_PFD3**).
   * Used as inputs for system buses (AXI, AHB, IPG), internal processing logic, DDR interface (MMDC), NAND/NOR interfaces. Supports dynamic frequency scaling.
3. **PLL3 (USB1_PLL / 480_PLL)**:
   * Used in conjunction with USB PHY 1 (USBPHY1 / OTG PHY).
   * Fixed multiplier of 20, resulting in **480 MHz** VCO frequency with 24 MHz oscillator.
   * Drives four PFDs (**PLL3_PFD0 – PLL3_PFD3**).
   * Provides constant frequency clock roots for UART, serial interfaces, audio interfaces, etc.
4. **PLL4 (Audio PLL)**:
   * Fractional multiplier PLL generating low-jitter, high-precision audio clocks with standardized frequencies.
   * VCO range: **650 MHz – 1300 MHz** (frequency resolution better than 1 Hz).
   * Equipped with output dividers: `/1`, `/2`, `/4`.
5. **PLL5 (Video PLL)**:
   * Fractional multiplier PLL generating display and video clocks.
   * VCO range: **650 MHz – 1300 MHz** (resolution < 1 Hz).
   * Equipped with output dividers: `/1`, `/2`, `/4`, `/8`, `/16`.
6. **PLL6 (ENET_PLL)**:
   * Fixed multiplier of $20 + \frac{5}{6}$, producing **500 MHz** VCO with 24 MHz input.
   * Generates 25/50 MHz for external Ethernet, 125 MHz for RGMII/RMII, and 100 MHz for general purpose.
7. **PLL7 (USB2_PLL)**:
   * Exclusively provides **480 MHz** clock to USB2 PHY (USBPHY2). Fixed multiplier of 20.

---

#### 10.3.2.3.1 General PLL Control and Status Functions
* **Bypass Mode**: Passes input reference clock directly to the PLL output (`BYPASS = 1`).
* **Output Disabled Mode**: Output is completely gated (`ENABLE = 0`).
* **Power Down Mode**: Most of the PLL circuitry is switched off to save power.
* **PLL Lock**: Monitored via "PLL Lock" bits before enabling clock distribution.

---

### 10.3.2.4 CCM (Clock Controller Module)

CCM includes:
* **Clock Root Generation Logic**: Secondary clock source selection and programmable dividers for core, system buses (AXI, AHB, IPG), baud clocks, and peripheral modules.
* **Power Mode Coordination**: Works with GPC, PMU, and SRC to manage **RUN, WAIT, and STOP** power modes.
* **On-The-Fly Frequency Scaling**:
  * ARM core clock scaling without interruption.
  * DDR memory controller clock scaling (MMDC handshake & Self-refresh entry/exit).
  * Peripheral root clock dividers.

> [!WARNING]
> On-the-fly frequency changing for synchronous interfaces (UART, CAN, I2S/Audio, Display) may cause synchronization/data loss and should not be performed while active.

---

### 10.3.2.5 Low Power Clock Gating Unit (LPCG)

The LPCG receives root clocks from the CCM and splits them into individually gated clock branches for each IP block.

Clock enable signals come from three sources:
1. **Clock enable from CCM**: Based on system power mode and `CGR` register bits.
2. **Clock enable from the peripheral block**: Generated by the block's internal activity.
3. **Clock enable from SRC**: Force-enables clock during system reset.

---

### 10.3.3 Peripheral Components of Clock Management System

#### 10.3.3.1 Interface and Functional Clocks
* **Bus Interface Clock**: Ensures communication between block and system buses; supplies configuration registers. Fed by CCM/LPCG.
* **Functional Clock**: Supplies the functional core of the IP block. Can be asynchronous and independent from the bus interface clock.

#### 10.3.3.2 Block Level Clock Management
* **Master Clock Protocol**: Used by bus masters (e.g., uSDHC) to request/release clocks dynamically from CCM/LPCG.
* **Slave Clock Protocol**: CCM requests slave modules (e.g., CAN, GPT, EPIT) to acknowledge before gating or changing clocks.

#### 10.3.3.3 Clock Domains & Dependencies
Blocks are grouped into clock domains controlled by LPCG gating cells to efficiently minimize dynamic power consumption. When domain $X$ depends on domain $Y$, domain $Y$ must remain active whenever domain $X$ is active.

---

## 10.4 Power Management

### 10.4.1 Centralized Components of Power Management System

The power generation and management system is built around the **PMU** (Power Management Unit) and **GPC** (General Power Controller) blocks.

```text
                                  +-------------------+
                                  |    ON/OFF Button  |
                                  +---------+---------+
                                            |
                                            v
+-------------------+             +-------------------+             +-------------------+
|       SNVS        |<----------->|        PMU        |<----------->|        GPC        |
| (Real-Time Clock, |             | (LDO Regulators,  |             | (Power Gating &   |
| Tamper, Low Power)|             | Switches, Bandgap)|             | Wakeup Controller)|
+-------------------+             +---------+---------+             +---------+---------+
                                            |                                 |
                                            | Power Rails                     | Isolation/Gate
                                            v                                 v
                              +----------------------------------------------------+
                              |                   Power Domains                    |
                              |  - ARM Core Platform (VDD_ARM)                     |
                              |  - ARM Memory Arrays (L1/L2 Cache)                 |
                              |  - SOC_PD (Peripherals: MMDC, USB, ENET, LCDIF...) |
                              |  - Always-On SNVS Domain                           |
                              +----------------------------------------------------+
```
*Figure 10-4. Power Management System Architecture*

---

### 10.4.1.1 Integrated PMU (Power Management Unit)

The integrated PMU simplifies external power supply design by generating internal rails from 2 or 3 primary supplies:

```text
VDD_SNVS_IN (Coin Cell / 3.3V) ──► LDO_SNVS ──► SNVS / RTC Core (Always-On)
VDD_HIGH_IN (2.8V - 3.3V) ───────┬─► LDO_2P5  ──► 2.5V (NVCC_DRAM pre-drivers, Analog PHYs)
                                 └─► LDO_1P1  ──► 1.1V (PLLs, OSC24M, USB PHY digital)
USB_VBUS (5V OTG1/OTG2) ───────────► LDO_USB  ──► 3.0V (USB PHY transceivers)
VDD_SOC_IN (1.2V - 1.4V) ──────────► LDO_SOC  ──► VDD_SOC (Internal SoC Logic, Memory)
VDD_ARM_IN (1.2V - 1.4V) ──────────► LDO_ARM  ──► VDD_ARM (Cortex-A7 Core Platform)
```
*Figure 10-5. i.MX 6ULL Power Tree*

#### PMU Regulators Detail:
1. **Digital LDO Regulators (`LDO_ARM`, `LDO_SOC`)**:
   * **Internal Bypass Mode**: Regulation FET fully ON, external voltage passed directly with minimal loss (switches in < 100 µs).
   * **Power Gate Mode**: Regulation FET switched OFF to eliminate leakage.
   * **Analog Regulation Mode**: Regulates output voltage in programmable **25 mV steps** for DVFS.
2. **Analog LDO Regulators (`LDO_1P1`, `LDO_2P5`)**:
   * `LDO_1P1`: Produces nominal 1.1V for PLLs and 24 MHz oscillator.
   * `LDO_2P5`: Produces nominal 2.5V. Includes a **Weak 2.5V Regulator (~40 Ω)** to maintain state in low power modes while disabling the main bandgap.
3. **USB LDO (`LDO_USB`)**:
   * Regulates 5V VBUS down to 3.0V for USB transceivers with auto power-muxing between VBUS1 and VBUS2.
4. **SNVS Regulator (`LDO_SNVS`)**:
   * Powers RTC and tamper detection from coin cell / battery.

---

### 10.4.1.2 GPC (General Power Controller)
* **Power Gating Controller (PGC)**: Switches power to ARM core and `SOC_PD` domains; controls power-up/down delays and isolation cells.
* **Wake-Up Interrupt Controller (WIC)**: Detects up to 128 masked/unmasked interrupts to wake the SoC from deep sleep when the main GIC is disabled.

### 10.4.1.3 SRC (System Reset Controller)
Handles POR (Power-On Reset), Warm Reset, Cold Reset, and interacts with external PMIC via `POR_B` and `PMIC_ON_REQ`.

---

### 10.4.1.4 Power Domains

| Power Domain | Components Included | DVFS / Power Gating Support |
| :--- | :--- | :--- |
| **ARM Core** | Cortex-A7 Core Platform | DVFS & Power Gating |
| **ARM Memory Array** | L1 / L2 Cache Arrays | Power Gating / Retention |
| **SOC_PD** | MMDC, APBH-DMA, CSI, ENET, LCDIF, PXP, NAND, SDMA, uSDHC, USB | Power Gating |
| **Main SoC Logic** | Internal SoC buses, IPG, AXI | Voltage Scaling in Static mode |
| **SNVS Low Power** | Real-Time Clock, Tamper Logic, LPSR GPIOs | Always-On (Coin cell) |
| **Analog Domain** | PLLs, LDOs, USB PHYs | Constant clean voltage |

---

### 10.4.1.7 System Low Power Modes Definition

#### Table 10-1: Low Power Mode Definition (LDO Enabled Mode)

| Subsystem / Block | System IDLE | Low Power IDLE | SUSPEND (Deep Sleep) |
| :--- | :--- | :--- | :--- |
| **CCM LPM Mode** | `WAIT` | `WAIT` | `STOP` |
| **ARM Core** | Low Voltage | Power Down | Power Down |
| **L1 Cache** | ON | Power Down | Power Down |
| **L2 Cache** | ON | ON | Power Down |
| **SoC Domain** | Nominal Voltage | Nominal Voltage | Standby Voltage |
| **SOC_PD Domain** | ON | ON | ON / Power Down |
| **PLLs** | ON / Power Down | Power Down | Power Down |
| **24M XTAL** | ON | OFF | OFF |
| **RC OSC** | OFF | ON | OFF |
| **DRAM (MMDC)** | Self-Refresh (Auto) | Self-Refresh (SW) | Self-Refresh (SW) |
| **DRAM I/O Low Power** | No | Yes | Yes |
| **LDO_ARM** | ON | Power Gate | Power Gate |
| **LDO_SOC** | ON | ON | Digital Bypass |
| **LDO_2P5 / LDO_1P1** | ON | OFF | OFF |
| **WEAK_2P5 / WEAK_1P1** | OFF | ON | OFF |
| **Bandgap** | ON | ON | OFF |
| **AHB Clock** | 24 MHz | 3 MHz | OFF |
| **IPG Clock** | 12 MHz | 1.5 MHz | OFF |
| **PER Clock** | 24 MHz | 1 MHz | OFF |
| **GPIO Wakeup** | Yes | Yes | Yes |
| **RTC Wakeup** | Yes | Yes | Yes |
| **USB Remote Wakeup** | Yes | Yes | Yes (needs SOC_PD ON) |

---

#### Table 10-2: Low Power Mode Definition (LDO Bypass Mode)

| Subsystem / Block | System IDLE | Low Power IDLE | SUSPEND (Deep Sleep) |
| :--- | :--- | :--- | :--- |
| **CCM LPM Mode** | `WAIT` | `WAIT` | `STOP` |
| **ARM Core** | Low Voltage | Power Down | Power Down |
| **L1 Cache** | Low Voltage | Power Down | Power Down |
| **L2 Cache** | ON | ON | Power Down |
| **SoC Domain** | Nominal Voltage | Nominal Voltage | Standby Voltage |
| **SOC_PD Domain** | ON | ON | ON / Power Down |
| **PLLs** | ON / Power Down | Power Down | Power Down |
| **24M XTAL** | ON | OFF | OFF |
| **RC OSC** | OFF | ON | OFF |
| **DRAM (MMDC)** | Self-Refresh (Auto) | Self-Refresh (SW) | Self-Refresh (SW) |
| **DRAM I/O Low Power** | No | Yes | Yes |
| **LDO_ARM** | Digital Bypass | Power Gate | Power Gate |
| **LDO_SOC** | Digital Bypass | Digital Bypass | Digital Bypass |
| **LDO_2P5 / LDO_1P1** | ON | OFF | OFF |
| **WEAK_2P5 / WEAK_1P1** | OFF | ON | OFF |
| **Bandgap** | ON | OFF | OFF |
| **Low Power Bandgap** | OFF | ON | OFF |
| **AHB Clock** | 24 MHz | 3 MHz | OFF |
| **IPG Clock** | 12 MHz | 1.5 MHz | OFF |
| **PER Clock** | 24 MHz | 1 MHz | OFF |
| **GPIO Wakeup** | Yes | Yes | Yes |
| **RTC Wakeup** | Yes | Yes | Yes |

---

#### Table 10-3: STOP Mode Configuration (`PMU_MISC0[STOP_MODE_CONFIG]`)

| Block | `STOP_MODE_CONFIG = 0` | `STOP_MODE_CONFIG = 1` |
| :--- | :--- | :--- |
| **`reg1p1`** | OFF | ON |
| **`reg2p5`** | OFF | ON |
| **`reg3p0`** | OFF / ON (crude local ref if VBUS present) | OFF / ON (analog central bandgap if VBUS present) |
| **`reg_core`** | Bypassed if not power-gated | Bypassed if not power-gated |
| **`reg_soc`** | Bypassed | Bypassed |
| **Bandgap** | OFF | Functional |
| **Temp Sensor** | OFF | OFF |
| **All PLLs** | OFF | OFF |
| **OSC24M** | OFF | Controlled by CCM configuration |

---

### 10.4.2 Power Saving Techniques Summary

#### Table 10-4: Power Saving Design / Architecture Matrix

| Technique | Active SoC Power | Standby SoC Power | System Power |
| :--- | :---: | :---: | :---: |
| **Temperature Monitoring & Throttling (TEMPMON)** | ✔ | | ✔ |
| **ARM Core SRPG (Software State Retention)** | | ✔ | ✔ |
| **ARM Core Power Gating** | | ✔ | ✔ |
| **Clock Gating (Automatic Dynamic & Forced)** | ✔ | ✔ | ✔ |
| **Integrated PMU (Efficiency, Low IR Drop)** | ✔ | ✔ | ✔ |
| **L2 Cache State Retention** | | ✔ | ✔ |
| **Low Power DDR (LPDDR2, DDR3 Self-Refresh & DLL-Off)** | ✔ | ✔ | ✔ |

---

### 10.4.2.3 Peripheral Power Management

1. **Main Memory (MMDC / DDR3 / LPDDR2)**:
   * **Automatic Self-Refresh**: MMDC puts DDR into self-refresh if idle for 1024 clock cycles (configurable).
   * **DDR3 DLL-Off Mode**: Lowers frequency below 396 MHz, disabling high-power termination and reducing I/O drive strength.
   * **DDR I/O Floating**: Floats I/O pads during Suspend to prevent leakage.
2. **I/O Power Reduction**:
   * Disable unused Pull-Up/Pull-Down resistors.
   * Reduce drive strength to minimum or configure unused pins as inputs.
   * Put unused PHYs into lowest power state.

---

### 10.4.3 Example of External Power Supply Interface

```text
+-------------------------------------------------------------------------------+
|                            i.MX 6ULL Application Processor                     |
|                                                                               |
|  DCDC Core (1.2-1.4V) ──────► VDD_ARM_IN ──► LDO_ARM ──► ARM Core             |
|                       └─────► VDD_SOC_IN ──► LDO_SOC ──► SoC Logic, Memories  |
|                                                                               |
|  DCDC High (3.0-3.3V) ──────► VDD_HIGH_IN ─┬─► LDO_2P5 ─► 2.5V (eFUSE, PLL)   |
|                                            └─► LDO_1P1 ─► 1.1V (OSC24M, PLL)  |
|                                                                               |
|  DCDC DRAM (1.35-1.5V) ─────► NVCC_DRAM (DRAM I/O)                            |
|  USB 5V Supply ─────────────► VDD_USB_CAP (LDO_USB)                           |
|  Coin Cell / Batt (3V) ─────► VDD_SNVS_IN ──► LDO_SNVS ─► SNVS / RTC (32kHz)  |
|                                                                               |
|  Signals to PMIC:                                                             |
|  - PMIC_ON_REQ (Power enable)        - PMIC_STBY_REQ (Standby voltage select) |
|  - POR_B (Power-On Reset)            - ONOFF (Hardware button input)          |
+-------------------------------------------------------------------------------+
```
*Figure 10-10. Supplying i.MX 6ULL Power Using Integrated PMU*

---

## 10.5 ONOFF (Button)

The chip supports an external button input to request SoC power state changes (ON / OFF) via the PMU and SNVS_LP logic:

* **Dumb PMIC Mode**: Uses `pmic_en_b` as a level signal for ON/OFF.
  * **Debounce**: 0 ms, 50 ms, 100 ms, 500 ms (generates `set_pwr_off_irq`).
  * **Off-to-On Time**: 0 ms, 50 ms, 100 ms, 500 ms (press duration to turn ON).
  * **Max Timeout**: 5 s, 10 s, 15 s, or disabled (long-press to force power down).
* **Smart PMIC Mode**: Issues a pulse signal on `pmic_en_b` to interface with smart PMIC controllers.

```text
             +-----------------------------------------+
             |                                         |
             |  +-----------------------------------+  |
             |  |               RESET               |  |
             |  +-----------------+-----------------+  |
             |                    |                    |
             |                    v                    |
             |              +-----------+              |
             |              |    OFF    |              |
             |              +-----+-----+              |
             |                    |                    |
             |    Button press    |   Button press     |
             |    > Off-to-On     |   > Max Timeout    |
             |    or Wakeup       |   or SW Shutdown   |
             |                    v                    |
             |              +-----------+              |
             |              |    ON     |              |
             |              +-----------+              |
             +-----------------------------------------+
```
*Figure 10-11. Dumb PMIC Mode State Machine*
