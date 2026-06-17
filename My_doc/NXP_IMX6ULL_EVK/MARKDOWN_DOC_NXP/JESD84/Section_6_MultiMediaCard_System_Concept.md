# Section 6 — MultiMediaCard System Concept

The main design goal of the MultiMediaCard system is to provide a very low cost mass storage product, implemented as a 'card' with a simple controlling unit, and a compact, easy-to-implement interface. These requirements lead to a reduction of the functionality of each card to an absolute minimum.

Nevertheless, since the complete MultiMediaCard system has to have the functionality to execute tasks (at least for the high end applications), such as error correction and standard bus connectivity, the system concept is described next. It is based on modularity and the capability of reusing hardware over a large variety of cards.

### Four Typical MultiMediaCard System Architectures

| Type | Description | Data Rate |
|------|-------------|-----------|
| **Software emulation** | Bus protocol emulated in software using up to 10 port pins of a microcontroller. No additional hardware required. | ~100–300 kbit/s (reduced) |
| **Point-to-point linkage** | Full data rate with additional hardware | Full |
| **Simple bus** | Full data rate, part of a set of addressable units | Full |
| **PC bus** | Full data rate, addressable, extended functionality (e.g. DMA) | Full |

> The various systems, although different in their feature set, share a basic common functionality. Functions are organized in hierarchical layers of abstract ('virtual') components — a logical classification covering a wide variety of implementations, without implying any specific design or rules for hardware/software partitioning.

---

## 6.1 Higher Than a Density of 2 GB

The maximum density possible in versions up to v4.1 of this specification was limited in practice to 2 GB due to the following reasons:

- Existing 32-bit byte-address argument in the command frame (max 4 GB addressable)
- Existing formula for calculating card density (max 4 GB could be indicated)
- Capability of the FAT16 File System to address up to 2 GB per partition

The lowest common denominator — **2 GB** — set the limit. Implementation of higher than 2 GB density is **not backwards compatible** with lower densities. Changes introduced:

1. The address argument for >2 GB density is changed to **sector address** (512-byte sectors) instead of byte address.
2. Card density is read from the **EXT_CSD register** instead of the CSD register.
3. The system implementation must include a **file system capable of handling sector-type addresses**.

---

## 6.2 MMCplus and MMCmobile

Two card types are defined to describe R/W or ROM cards with specifically defined mandatory features and attributes. Only cards meeting the respective requirements are eligible to carry the name and logo.

| Type | Form Factor | Voltage | Bus Width | Clock |
|------|-------------|---------|-----------|-------|
| **MMCplus** | Normal size | 2.7–3.6 V | ×1 / ×4 / ×8 | 26 MHz (52 MHz optional) |
| **MMCmobile** | Reduced size | 1.70–1.95 V and 2.7–3.6 V | ×1 / ×4 / ×8 | 26 MHz (52 MHz optional), min 2.4 MB/s read/write |

Both implementations are **backwards compatible** with MMCA System Specification versions 3.xx in max 20 MHz clock frequency mode.

---

## 6.3 Card Concept

The MultiMediaCard transfers data via a configurable number of data bus signals.

### Communication Signals

- **CLK** — Each cycle directs a one-bit transfer on the command and all data lines. Frequency may vary between zero and the maximum clock frequency.
- **CMD** — Bidirectional command channel for card initialization and command transfer. Two operation modes:
  - **Open-drain** — for initialization mode
  - **Push-pull** — for fast command transfer
  Commands are sent host → card; responses are sent card → host.
- **DAT0–DAT7** — Bidirectional data channels operating in push-pull mode. Only one side (card or host) drives at a time.
  - Default after power-up or reset: only **DAT0** is used.
  - Wider bus can be configured: **DAT0–DAT3** (4-bit) or **DAT0–DAT7** (8-bit).
  - The card includes internal pull-ups for DAT1–DAT7.
  - Entering 4-bit mode: pull-ups on DAT1–DAT3 are disconnected.
  - Entering 8-bit mode: pull-ups on DAT1–DAT7 are disconnected.

### Card Classes

| Class | Description |
|-------|-------------|
| **ROM** | Manufactured with fixed data content. Used for software, audio, video distribution. |
| **R/W** | Flash, OTP, or MTP. Sold blank; used for mass storage, video/audio/image recording. |
| **I/O** | Intended for communication (e.g. modems); typically has an additional interface link. |

### Table 3 — MultiMediaCard Interface Pin Configuration

| Name | Type | Description |
|------|------|-------------|
| CLK | I | Clock |
| DAT0¹ | I/O/PP | Data |
| DAT1 | I/O/PP | Data |
| DAT2 | I/O/PP | Data |
| DAT3 | I/O/PP | Data |
| DAT4 | I/O/PP | Data |
| DAT5 | I/O/PP | Data |
| DAT6 | I/O/PP | Data |
| DAT7 | I/O/PP | Data |
| CMD | I/O/PP/OD | Command/Response |
| VCC | S | Supply voltage for NAND (BGA) |
| VCCQ | S | Supply voltage for MMC interface (BGA) |
| VDD | S | Supply voltage (card) |
| VSS | S | Supply voltage ground for NAND (BGA) |
| VSS1 | S | Supply voltage ground (card) |
| VSS2 | S | Supply voltage ground (card) |
| VSSQ | S | Supply voltage ground for MMC interface (BGA) |

> **Type legend:** I: input; O: output; PP: push-pull; OD: open-drain; NC: Not connected (or logical high); S: power supply.  
> ¹ DAT0–DAT7 lines for read-only cards are output only.

### Table 4 — MultiMediaCard Registers

| Name | Width (bytes) | Description | Implementation |
|------|--------------|-------------|----------------|
| CID | 16 | Card IDentification number — individual card identifier | Mandatory |
| RCA | 2 | Relative Card Address — dynamically assigned by host during initialization | Mandatory |
| DSR | 2 | Driver Stage Register — configures card output drivers | Optional |
| CSD | 16 | Card Specific Data — information about card operation conditions | Mandatory |
| OCR | 4 | Operation Conditions Register — identifies the voltage type of the card via broadcast command | Mandatory |
| EXT_CSD | 512 | Extended Card Specific Data — card capabilities and selected modes. Introduced in spec v4.0 | Mandatory |

> The host may reset the card by switching the power supply off and back on. The card shall have its own power-on detection circuitry. No explicit reset signal is necessary. The card can also be reset by a special command.

### 6.3.1 Form Factors

See Chapter 8 for form factor details.

---

## 6.4 Bus Concept

The MultiMediaCard bus is designed to connect solid-state mass-storage memory or I/O devices (in card format) to multimedia applications. It is a **single master bus with a single slave**.

- **Bus master** — the MultiMediaCard bus controller
- **Bus slave** — a single mass storage card (ROM, OTP, Flash, etc.) or an I/O card with its own on-card controller

The bus also includes power connections to supply the cards. Payload data transfer between host and card can be **bidirectional**.

### 6.4.1 Bus Lines

| Group | Lines | Purpose |
|-------|-------|---------|
| Power supply | VSS1, VSS2, VDD | Supply cards |
| Power supply (eMMC) | VSS, VSSQ, VCC, VCCQ | Supply eMMC |
| Data transfer | CMD, DAT0–DAT7 | Bidirectional communication |
| Clock | CLK | Synchronize data transfer |

### 6.4.2 Bus Protocol

After power-on reset, the host initializes the card via the MultiMediaCard bus protocol. Messages are represented by the following tokens:

- **Command** — starts an operation; sent from host to card via the CMD line.
- **Response** — sent from card to host as an answer to a command; transferred via the CMD line.
- **Data** — transferred between card and host via data lines; can use 1 (DAT0), 4 (DAT0–DAT3), or 8 (DAT0–DAT7) lines.

Card addressing uses a **session address** assigned during initialization by the bus controller. Cards are identified by their unique **CID number** (contains 24-bit MID and OID fields defined by MMCA/JEDEC).

### Data Transfer Command Types

| Type | Description |
|------|-------------|
| **Sequential commands**¹ | Initiate a continuous data stream; terminated only by a stop command on the CMD line. Minimizes command overhead. |
| **Block-oriented commands** | Send a data block followed by CRC bits. Supports single or multiple block transmission (read and write). Multiple block transmission terminated by a stop command. |

> ¹ Sequential commands are supported only in 1-bit bus mode, to maintain compatibility with previous versions of this specification.

### Token Formats

**Command token** (48 bits total):

| Field | Size | Value |
|-------|------|-------|
| Start bit | 1 bit | Always `0` |
| Transmitter bit | 1 bit | `1` = host command |
| Content (command + address/parameter) | 39 bits | — |
| CRC | 7 bits | — |
| End bit | 1 bit | Always `1` |

**Response token:**

| Type | Length | Content |
|------|--------|---------|
| R1, R3, R4, R5 | 48 bits | Mirrored command and status info / OCR register / RCA |
| R2 | 136 bits | CID or CSD register |

> Each token is protected by CRC bits so that transmission errors can be detected and the operation may be repeated. Sequential data transfers do not include CRC protection (no predefined end). Block data CRC uses a **16-bit CCITT polynomial**.

---

## 6.5 Controller Concept

The MultiMediaCard controller is the link between the application and the MultiMediaCard bus. Basic requirements:

- Protocol translation from MultiMediaCard bus to application bus
- Data buffering to enable minimal data access latency
- Macros for common complex command sequences

The controller is divided into two major parts:

- **Application adapter** — application-oriented part (bus slave and bridge into the MultiMediaCard system; can be extended to bus master with DMA support)
- **MultiMediaCard adapter** — MultiMediaCard-oriented part (only bus master on the MMC bus; controls all bus activity; slave to application adapter; supports all MMC bus commands plus macro commands; includes error correction capability)

The two parts communicate across an internal **adapter interface**, which is directly accessible in low-cost point-to-point systems where the controller is reduced to just the MultiMediaCard adapter.

### 6.5.1 Application Adapter Requirements

The application adapter makes the MultiMediaCard system plug-and-play in standard bus environments. Each environment requires a unique application adapter. To reduce the bill of materials, it is recommended to integrate an existing application adapter with the MultiMediaCard adapter module.

The **application adapter extension** enhances the adapter from a bus slave to a bus master, enabling bidirectional DMA transfers.

### 6.5.2 MultiMediaCard Adapter Architecture

The adapter is divided into two major parts:

**Controller:**
- Macro unit
- Power management

**Data path:**
- Adapter interface
- ECC unit
- Read cache
- Write buffer
- CRC unit
- MultiMediaCard bus interface

Key implementation notes:

- The **data path units** should be implemented in hardware to guarantee full system capabilities.
- The **controller part** may be implemented in hardware or software depending on application architecture.
- The **data path width** should be a byte; all data-handling units should work on bytes or blocks of bytes.
- The **MultiMediaCard bus interface** handles transport management: start/end bits, CRC protection, and stuffing bits for fixed-length frames.
- The adapter interface must handle **asynchronous mode** via handshake signals (STB, ACK) or the host may poll the busy/not-busy state in synchronous mode.
- **Write buffer and read cache** are recommended to improve system-level performance:
  - The MMC bus transfers data at up to 416 Mbit/s, which may be slower than the CPU bus; write buffers free CPU time while the adapter handles transfers.
  - The **read cache** improves random-access read latency by caching a full block; repeated accesses and read-modify-write operations benefit significantly from the SRAM swapper.