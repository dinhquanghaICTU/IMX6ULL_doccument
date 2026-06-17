# i.MX 6ULL Applications Processor Reference Manual - Index

Index này gom các chapter đã tách từ *i.MX 6ULL Applications Processor Reference Manual* để dễ tra cứu nhanh theo từng khối chức năng.

## Danh Sách Chapter

| Chapter | Nội dung ngắn gọn |
|---|---|
| [Chapter 5: Fusemap](Chapter_5_Fusemap.md) | Bảng fuse boot của i.MX6ULL: chọn thiết bị boot, cấu hình QSPI/EIM/Serial-ROM/SD/MMC/NAND và các fuse liên quan bảo mật, clock, pad setting. |
| [Chapter 6: External Memory Controllers](Chapter_6_External_Memory_Controllers.md) | Tổng quan các bộ điều khiển bộ nhớ ngoài, chủ yếu MMDC cho DDR và EIM cho PSRAM/NOR Flash, kèm tính năng và cấu hình boot cơ bản. |
| [Chapter 8: System Boot](Chapter_8_System_Boot.md) | Luồng boot từ POR qua Boot ROM, chọn boot mode bằng BOOT_MODE/eFUSE/GPIO, serial downloader, DCD/plugin, HAB và fallback boot. |
| [Chapter 21: External Interface Module (EIM)](Chapter_21_External_Interface_Module_EIM.md) | Chi tiết module EIM: chip select, bus address/data, async/sync mode, burst clock, boot mode, tín hiệu ngoài và timing/register liên quan. |
| [Chapter 35: Multi Mode DDR Controller (MMDC)](Chapter_35_Multi_Mode_DDR_Controller_MMDC.md) | Bộ điều khiển DDR hỗ trợ DDR3/DDR3L/LPDDR2: kiến trúc MMDC core/PHY, tín hiệu DDR, clock, luồng read/write, calibration và power saving. |
| [Chapter 38: On-Chip RAM Memory Controller (OCRAM)](Chapter_38_On_Chip_RAM_Memory_Controller_OCRAM.md) | Controller OCRAM 128 KB trên AXI bus: tổ chức bank, arbitration read/write, wait-state, pipeline và cấu hình timing qua IOMUXC_GPR. |
| [Chapter 58: Ultra Secured Digital Host Controller (uSDHC)](<Chapter_58_Ultra_Secured_Digital_Host_Controller_(uSDHC).md>) | Host controller cho SD/SDIO/MMC: kiến trúc khối, bus host-card, clock/DLL, DMA/PIO, command/data path, interrupt và register chức năng. |
| [Ghi chú eFuse boot uSDHC/eMMC](efuse.md) | Giải thích các trường boot configuration liên quan lựa chọn SD/eMMC, bus width, tốc độ, reset, điện áp, cổng uSDHC và delay khi boot. |

## Gợi Ý Đọc Nhanh

- Cần hiểu boot từ SD/eMMC/QSPI/NAND: đọc [Chapter 8](Chapter_8_System_Boot.md) trước, rồi đối chiếu [Chapter 5](Chapter_5_Fusemap.md).
- Cần cấu hình DDR: đọc [Chapter 35](Chapter_35_Multi_Mode_DDR_Controller_MMDC.md), sau đó xem tổng quan ở [Chapter 6](Chapter_6_External_Memory_Controllers.md).
- Cần làm việc với NOR/PSRAM qua bus ngoài: đọc [Chapter 21](Chapter_21_External_Interface_Module_EIM.md).
- Cần boot hoặc giao tiếp SD/eMMC: đọc [Chapter 58](<Chapter_58_Ultra_Secured_Digital_Host_Controller_(uSDHC).md>), kết hợp fuse boot trong [Chapter 5](Chapter_5_Fusemap.md).
- Cần tra nhanh cấu hình eFuse boot SD/eMMC: đọc [Ghi chú eFuse boot uSDHC/eMMC](efuse.md).
