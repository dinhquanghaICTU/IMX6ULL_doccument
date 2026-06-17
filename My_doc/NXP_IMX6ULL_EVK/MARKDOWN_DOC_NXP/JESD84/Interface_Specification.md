# JEDEC Standard No. 84-A43 — MMC/eMMC Electrical Interface Specification

---

## 1. Scope

This document provides a comprehensive definition of the MMC/eMMC Electrical Interface, its environment, and handling. It also provides design guidelines and defines a tool box of macro functions and algorithms intended to reduce design-in costs.

---

## 2. Normative Reference

The following normative documents contain provisions that, through reference in this text, constitute provisions of this standard. For dated references, subsequent amendments to, or revisions of, any of these publications do not apply. However, parties to agreements based on this standard are encouraged to investigate the possibility of applying the most recent editions of the normative documents indicated below. For undated references, the latest edition of the normative document referred to applies.

---

## 3. Terms and Definitions

For the purposes of this publication, the following abbreviations for common terms apply:

| Term | Definition |
|------|-----------|
| **Block** | A number of bytes; basic data transfer unit |
| **Broadcast** | A command sent to all cards on the MultiMediaCard bus¹ |
| **CID** | Card IDentification number register |
| **CLK** | Clock signal |
| **CMD** | Command line or MultiMediaCard bus command (if extended CMDXX) |
| **CRC** | Cyclic Redundancy Check |
| **CSD** | Card Specific Data register |
| **DAT** | Data line |
| **DSR** | Driver Stage Register |
| **eMMC** | Embedded MultiMediaCard |
| **Flash** | A type of multiple time programmable non volatile memory |
| **Group** | A number of write blocks; composite erase and write protect unit |
| **LOW, HIGH** | Binary interface states with defined assignment to a voltage level |
| **NSAC** | Defines the worst case for the clock rate dependent factor of the data access time |
| **MSB, LSB** | The Most Significant Bit or Least Significant Bit |
| **OCR** | Operation Conditions Register |
| **open-drain** | A logical interface operation mode. An external resistor or current source is used to pull the interface level to HIGH; the internal transistor pushes it to LOW |
| **payload** | Net data |
| **push-pull** | A logical interface operation mode; a complementary pair of transistors is used to push the interface level to HIGH or LOW |
| **RCA** | Relative Card Address register |
| **ROM** | Read Only Memory |
| **stuff bit** | Filling 0 bits to ensure fixed length frames for commands and responses |
| **SPI** | Serial Peripheral Interface |
| **TAAC** | Defines the time dependent factor of the data access time |
| **three-state driver** | A driver stage which has three output driver states: HIGH, LOW and high impedance (which means that the interface does not have any influence on the interface level) |
| **token** | Code word representing a command |
| **VDD** | + Power supply |
| **VSS** | Power supply ground |

> ¹ Broadcast occurs only in MultiMediaCard systems supporting versions prior to 4.0. In version 4.0 and later only one card can be present on the bus.

---

## 4. General Description

The MultiMediaCard is a universal low cost data storage and communication media. It is designed to cover a wide area of applications such as smart phones, cameras, organizers, PDAs, digital recorders, MP3 players, pagers, electronic toys, etc. Targeted features are high mobility and high performance at a low cost price. These features include low power consumption and high data throughput at the memory card interface.

The MultiMediaCard communication is based on an advanced 13-pin bus. The communication protocol is defined as a part of this standard and referred to as the MultiMediaCard mode.

To provide for the forecasted migration of CMOS power (VDD) requirements and for compatibility and integrity of MultiMediaCard systems, two types of MultiMediaCards are defined in this standard specification, which differ only in the valid range of system VDD. These two card types are referred to as **High Voltage MultiMediaCard** and **Dual Voltage MultiMediaCard**.

### Document Structure

| Section | Content |
|---------|---------|
| Section 5 | MultimediaCard Features |
| Section 6 | General overview of system components: card, bus, and host |
| Section 7 | Common MultiMediaCard characteristics |
| Section 8 | Card registers |
| Section 10 | Error protection techniques |
| Section 11 | Physical and mechanical properties; minimal requirements of card slots and cartridges |
| Section 12 | MultiMediaCard bus as a universal communication interface and electrical parameters |
| Section 13 | Standard compliance criteria for cards and hosts |
| Section 14 | Three basic file formats for high data interchangeability |
| Annex A | Additional informative application notes for circuit and system designers |
| Annex B | Major changes between the previous and current version of this specification |

> **Note:** The SPI mode is removed from this standard.

**Terminology conventions used in this document:**
- **"Shall"** or **"will"** — denotes a mandatory provision of the standard.
- **"Should"** — denotes a provision that is recommended but not mandatory.
- **"May"** — denotes a feature whose presence does not preclude compliance, that may or may not be present at the option of the implementor.

---

## 5. System Features

The MultiMediaCard System has a wide variety of system features serving several purposes, including:

- Covering a broad category of applications from smart phones and PDAs to digital recorders and toys
- Facilitating the work of designers who seek to develop applications with their own advanced and enhanced features
- Maintaining compatibility and compliance with current electronic, communication, data and error handling standards

### Main Features

The MultiMediaCard System:

- Is targeted for portable and stationary applications
- Has defined System Voltage (VDD) Ranges (see Table 1)
- Includes MMCplus and MMCmobile definitions
- Is designed for read-only, read/write and I/O cards
- Supports card clock frequencies of 0–20 MHz, 0–26 MHz or 0–52 MHz
- Has a maximum data rate up to **416 Mbits/sec**
- Has a defined minimum performance
- Maintains card support for three different data bus width modes: **1-bit** (default), **4-bit**, and **8-bit**
- Includes definition for higher than 2 GB of density of memories
- Includes password protection of data
- Supports basic file formats for high data interchangeability
- Includes application specific commands
- Enables correction of memory field errors
- Has built-in write protection features (permanent or temporary)
- Includes a simple erase mechanism
- Maintains full backward compatibility with previous MultiMediaCard systems (1-bit data bus, multi-card systems)

### Table 1 — MultiMediaCard Voltage Modes

| Mode | High Voltage MultiMediaCard (V) | Dual Voltage MultiMediaCard (V) |
|------|--------------------------------|--------------------------------|
| Communication | 2.7 – 3.6 | 1.70 – 1.95, 2.7 – 3.6¹ |
| Memory Access | 2.7 – 3.6 | 1.70 – 1.95, 2.7 – 3.6 |

> ¹ VDD range: 1.95 V – 2.7 V is **not** supported.

### Additional Features

- Ensures new hosts retain full compatibility with previous versions of MultiMediaCards (backward compatibility)
- Supports two form factors:
  - Normal size: **24 mm × 32 mm × 1.4 mm**
  - Reduced size: **24 mm × 18 mm × 1.4 mm**
- Supports multiple command sets
- Includes attributes of the available operation modes
- Provides a possibility for the host to make sudden power failure safe-update operations for the data content
- Enhanced power saving via a **sleep functionality**
- Introduces **Boot Operation Mode** for a simple boot sequence method
- Provides a new CID Register setting to recognize either eMMC or a card
- Obsoletes the SPI Mode
- Defines I/O voltage (VCCQ) and core voltage (VCC) separately for eMMC
- Includes eMMC BGA Form Factors:
  - 11.5 mm × 13 mm × 1.3 mm
  - 12 mm × 16 mm × 1.4 mm
  - 12 mm × 18 mm × 1.4 mm
- Defines Erase-unit size and Erase timeout for high-capacity memory
- Provides access size register indicating one (or multiple) programmable boundary unit(s) of device
- Obsoletes the Absolute Minimum Performance
- Introduces eMMC OCR setting and response
- Defines WP group size for high-capacity devices
- Introduces optional **Alternate Boot Operation Mode**