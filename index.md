# DOC_IMX6ULL - Index

File này dùng để định hướng nhanh cho toàn bộ thư mục tài liệu. Khi AI hoặc người đọc cần tìm thông tin, nên bắt đầu từ đây trước để biết tài liệu nào là tài liệu chính, tài liệu nào là tài liệu phụ để tra cứu thêm.

---

## 1. `My_doc`

[`My_doc/`](My_doc/) là thư mục tài liệu chính mình tự tổng hợp lại theo project, board và workflow thực tế.

Nên ưu tiên đọc thư mục này trước khi đi sang tài liệu phụ, vì trong đây có các ghi chú đã được lọc lại theo đúng việc đang làm với i.MX6ULL, OKM6ULL-S và MYC-Y6ULX.

### OKM6ULL-S

[`My_doc/FORLINX_OKM6ULL-S/`](My_doc/FORLINX_OKM6ULL-S/) là nhánh chính đang dùng cho board OKM6ULL-S.

Các tài liệu nên đọc trước:

- [Build SDK, kernel, dtb, rootfs, wic](My_doc/FORLINX_OKM6ULL-S/my_doc/AI_flow_gennerate_pass/How_to_build_SDK.md)
- [Flash OKM6ULL-S bằng UUU](My_doc/FORLINX_OKM6ULL-S/my_doc/AI_flow_gennerate_pass/How_to_flash_OKM6ULL-S.md)
- [Ghi chú eMMC trên OKMX6ULL-S](My_doc/FORLINX_OKM6ULL-S/my_doc/AI_flow_gennerate_pass/emmc_in_OKMX6ULL-S.md)
- [Custom U-Boot cho SOM Forlinx](My_doc/FORLINX_OKM6ULL-S/my_doc/AI_flow_gennerate_pass/how_to_custom_uboot_for_SOM_forlinx.md)
- [Build U-Boot Yocto Forlinx](My_doc/FORLINX_OKM6ULL-S/my_doc/build_uboot_yocto_forlinx.md)
- [Tổng quan board theo tài liệu Forlinx](My_doc/FORLINX_OKM6ULL-S/doc_forlinx/software/about.md)
- [Quick start OKM6ULL-S](My_doc/FORLINX_OKM6ULL-S/doc_forlinx/software/Quick_start.md)
- [Programming system của Forlinx](My_doc/FORLINX_OKM6ULL-S/doc_forlinx/software/Programming_system.md)
- [Check function bằng command](My_doc/FORLINX_OKM6ULL-S/doc_forlinx/software/Check_function_using_command.md)
- [Development environment](My_doc/FORLINX_OKM6ULL-S/doc_forlinx/how_to_build_SDK/Development_Environment.md)

### IMX6ULL

[`My_doc/NXP_IMX6ULL_EVK/`](My_doc/NXP_IMX6ULL_EVK/) là nhánh ghi chú chung cho chip i.MX6ULL, không khóa riêng vào một board.

Các tài liệu đáng chú ý:

- [`MY_MARKDOWN/`](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/) — Ghi chú tự tổng hợp theo workflow đang làm.
- [Setup build image bằng Yocto/NXP](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/build_image/general_setup.md)
- [Flow tạo `u-boot.imx` cho i.MX6ULL](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/flow_create_uboot_imx6ull/flow_create_uboot_imx6ull.md) — Lần theo `defconfig`, `Kconfig`, `Makefile`, `mkimage`, `imximage.c`, IVT, Boot Data và DCD.
- [Flow sau khi Boot ROM jump vào U-Boot `_start`](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/flow_jump_uboot/flow_jump_uboot.md) — Lần theo `_start`, `start.S`, `crt0.S`, `board_init_f`, relocation, `board_init_r`, `main_loop`, `bootcmd`, `bootz/bootm` và jump vào kernel.
- [Flash bằng UUU](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/uuu_flash/uuu_flash.md)
- [Flash firmware NOR bằng UUU](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/uuu_flash/uuu_flash_firmware_nor.md)
- [Fastboot](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/boot_script/Fastboot.md)
- [Boot script index](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/boot_script/index.md)
- [Boot script introduction](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/boot_script/introduction.md)
- [imx_usb_loader](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/boot_script/imx_usb_loader.md)
- [imx_loader step use](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/boot_script/imx_loader/step_use.md)
- [Setup cross compilation C/Golang](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/cross_compiler_C_GOLANG/setup_Cross-compilation_Environment.md)
- [`MARKDOWN_DOC_NXP/`](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/) — Tài liệu NXP đã tách thành markdown để tra cứu theo chapter/chủ đề.
- [So sánh UUU với imx_loader](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/Compare_uuu_with_IMX_Loader/Compare_uuu_with_IMX_Loader.md)
- [i.MX 6ULL Applications Processor Reference Manual index](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/index.md)
- [Chapter 8 - System Boot](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/Chapter_8_System_Boot.md)
- [Chapter 35 - MMDC](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/Chapter_35_Multi_Mode_DDR_Controller_MMDC.md)
- [Chapter 38 - OCRAM](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/Chapter_38_On_Chip_RAM_Memory_Controller_OCRAM.md)
- [Chapter 58 - uSDHC](<My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/Chapter_58_Ultra_Secured_Digital_Host_Controller_(uSDHC).md>)
- [Ghi chú eFuse boot uSDHC/eMMC](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/efuse.md) — Giải thích các trường fuse chọn thiết bị boot, bus width, tốc độ, reset, điện áp và cổng uSDHC.
- [Boot process i.MX6ULL eMMC DDR3L](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/01_boot_process_imx6ull_emmc_ddr3l.md)
- [i.MX 6ULL Applications Processor Reference Manual PDF](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/DOC_NXP/IMX6ULLRM.pdf) — Reference Manual đầy đủ về kiến trúc, ngoại vi, thanh ghi và bộ điều khiển của i.MX6ULL.
- [i.MX 6ULL Hardware Development Guide index](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/Hardware_Development_Guide_for_the_i.MX_6ULL_Applications_Processor/index.md) — Hướng dẫn checklist thiết kế, layout PCB, board bring-up, mô hình IBIS, công cụ sản xuất và kiểm tra BSDL.
- [i.MX6ULL examples index](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/Example/index.md) — Các ghi chú và ví dụ cấu hình thực tế cho i.MX6ULL/OKMX6ULL-S.
- [Cấu hình DCD DDR3L cho OKMX6ULL-S](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/Example/config_DCD_OKMX6ULL-S.md) — Ghi chú cấu trúc DDR3L, MMDC, AXI và timing DDR.
- [JESD84 eMMC interface](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/JESD84/Interface_Specification.md)
- [`HARDWARE/SCHEMATIC/`](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/HARDWARE/SCHEMATIC/) — Thư mục sơ đồ nguyên lý tham khảo của board i.MX6ULL EVK.
- [i.MX6ULL EVK schematic PDF](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/HARDWARE/SCHEMATIC/imx6ull_a0_0211.pdf) — Sơ đồ kết nối nguồn, DDR3L, eMMC, Ethernet, USB và các ngoại vi trên board tham khảo.

### MYC-Y6ULX

[`My_doc/SOM_MYC-Y6ULX/`](My_doc/SOM_MYC-Y6ULX/) là nhánh tài liệu cho board MYC-Y6ULX.

Các tài liệu đáng chú ý:

- [Software development guide index](My_doc/SOM_MYC-Y6ULX/MYC-Y6ULX_DOC_HW/MYD-Y6ULX_Software_Development_Guide/index.md)
- [Software development overview](My_doc/SOM_MYC-Y6ULX/MYC-Y6ULX_DOC_HW/MYD-Y6ULX_Software_Development_Guide/Overview.md)
- [Development environment](My_doc/SOM_MYC-Y6ULX/MYC-Y6ULX_DOC_HW/MYD-Y6ULX_Software_Development_Guide/Development_Environment.md)
- [Build filesystem với Yocto](My_doc/SOM_MYC-Y6ULX/MYC-Y6ULX_DOC_HW/MYD-Y6ULX_Software_Development_Guide/Build_the_File_SystemwithYocto.md)
- [Burn system image](My_doc/SOM_MYC-Y6ULX/MYC-Y6ULX_DOC_HW/MYD-Y6ULX_Software_Development_Guide/How_to_Burn_SystemImage.md)
- [Modify BSP](My_doc/SOM_MYC-Y6ULX/MYC-Y6ULX_DOC_HW/MYD-Y6ULX_Software_Development_Guide/How_to_Modify_BoardLevel_SupportPackage.md)
- [Fit hardware platform](My_doc/SOM_MYC-Y6ULX/MYC-Y6ULX_DOC_HW/MYD-Y6ULX_Software_Development_Guide/How_to_Fit_Your_HardwarePlatform.md)
- [Pinout MYC-Y6ULX](My_doc/SOM_MYC-Y6ULX/MYC-Y6ULX_DOC_HW/MYC-Y6ULX_PINOUT.md)

---

## 2. `Phu_doc`

[`Phu_doc/`](Phu_doc/) là thư mục tài liệu phụ để tra cứu kiến thức nền.

Không nên đọc từ đầu hết thư mục này nếu chỉ muốn làm việc với OKM6ULL-S. Dùng nó như tài liệu tham khảo khi cần hiểu sâu hơn về Yocto, Linux kernel, driver, device tree, U-Boot, IPC, process, thread, filesystem, network.

### Yocto

[`Phu_doc/docs/yocto_docs/`](Phu_doc/docs/yocto_docs/) chứa tài liệu Yocto đã tách theo chủ đề.

Điểm bắt đầu:

- [Yocto docs index](Phu_doc/docs/yocto_docs/INDEX.md)
- [Quick build](Phu_doc/docs/yocto_docs/01_quick_build.md)
- [Overview and concepts](Phu_doc/docs/yocto_docs/04_overview_and_concepts.md)
- [BSP developer guide](Phu_doc/docs/yocto_docs/07_bsp_developer_guide.md)
- [Setting up development tasks](Phu_doc/docs/yocto_docs/08a_setting_up.md)
- [Building images](Phu_doc/docs/yocto_docs/08h_building_images.md)
- [Kernel development](Phu_doc/docs/yocto_docs/09_kernel_development.md)
- [WKS/WIC reference](Phu_doc/docs/yocto_docs/06j_wks_reference.md)

### Linux Driver Và Kernel

Các tài liệu nền về Linux driver, kernel module, device model, interrupt, memory, DMA, USB, block, network driver.

- [Linux Device Drivers 3rd - index](Phu_doc/docs/linux_device_drivers_3rd_book/chapters/INDEX.md)
- [Essential Linux Device Drivers - index](Phu_doc/docs/essential_linux_device_drivers_book/chapters/INDEX.md)
- [Kernel module lesson](Phu_doc/docs/lessons/08_kernel_module/kernel_module.md)
- [Character device driver lesson](Phu_doc/docs/lessons/09_character_driver/character_device_driver.md)
- [Device tree lesson](Phu_doc/docs/lessons/10_device_tree/device_tree.md)
- [I2C lesson](Phu_doc/docs/lessons/11_i2c/i2c.md)
- [U-Boot lesson](Phu_doc/docs/lessons/15_uboot/uboot.md)

### Linux Programming

Các tài liệu nền về lập trình Linux user space: process, thread, IPC, file I/O, socket, signal, memory.

- [Linux Programming Interface - index](Phu_doc/docs/linux_programming_interface_book/chapters/INDEX.md)
- [Linux programming training](Phu_doc/docs/lessons/01_getting_familiar_with_linux_programming/Linux_Programming_Training_Complete.md)
- [Process lesson](Phu_doc/docs/lessons/04_process/process_lecture.md)
- [Multithread lesson](Phu_doc/docs/lessons/03_multi_thread_programming/multithread-lecture.md)
- [IPC lesson](Phu_doc/docs/lessons/07_ipc/ipc_lecture.md)
- [Debugging on Linux](Phu_doc/docs/lessons/06_debugging_technic/debugging_on_linux.md)

### BeagleBone Black Và AM335x

Nhánh này không phải trọng tâm i.MX6ULL, nhưng hữu ích để tham khảo device tree, pin muxing, GPIO, I2C, UART, MMC, USB, Ethernet.

- [BeagleBone Black hardware docs](Phu_doc/docs/beaglebone_black_docs/hw-docs/index.md)
- [AM335x reference manual index](Phu_doc/docs/beaglebone_black_docs/hw-docs/am33xx_reference_manual/index.md)
- [BBB P8 header pinout](Phu_doc/docs/beaglebone_black_docs/hw-docs/bbb_p8_header_pinout.md)
- [BBB P9 header pinout](Phu_doc/docs/beaglebone_black_docs/hw-docs/bbb_p9_header_pinout.md)
- [Pin muxing lesson](Phu_doc/docs/lessons/12_pin_muxing/Pin_Muxing_BBB.md)

---

## 3. Cách Đọc Nhanh Cho AI

Nếu câu hỏi liên quan trực tiếp OKM6ULL-S:

1. Đọc [`My_doc/FORLINX_OKM6ULL-S/my_doc/AI_flow_gennerate_pass/How_to_build_SDK.md`](My_doc/FORLINX_OKM6ULL-S/my_doc/AI_flow_gennerate_pass/How_to_build_SDK.md)
2. Đọc [`My_doc/FORLINX_OKM6ULL-S/my_doc/AI_flow_gennerate_pass/How_to_flash_OKM6ULL-S.md`](My_doc/FORLINX_OKM6ULL-S/my_doc/AI_flow_gennerate_pass/How_to_flash_OKM6ULL-S.md)
3. Nếu cần đối chiếu hãng, đọc [`My_doc/FORLINX_OKM6ULL-S/doc_forlinx/software/`](My_doc/FORLINX_OKM6ULL-S/doc_forlinx/software/)

Nếu câu hỏi liên quan `.wic`, Yocto, image, rootfs:

1. Đọc [`My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/build_image/general_setup.md`](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/build_image/general_setup.md)
2. Đọc [`Phu_doc/docs/yocto_docs/08h_building_images.md`](Phu_doc/docs/yocto_docs/08h_building_images.md)
3. Đọc [`Phu_doc/docs/yocto_docs/06j_wks_reference.md`](Phu_doc/docs/yocto_docs/06j_wks_reference.md)

Nếu câu hỏi liên quan flow tạo `u-boot.imx`, IVT, Boot Data, DCD:

1. Đọc [`My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/flow_create_uboot_imx6ull/flow_create_uboot_imx6ull.md`](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/flow_create_uboot_imx6ull/flow_create_uboot_imx6ull.md)
2. Đọc [`My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/Chapter_8_System_Boot.md`](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/Chapter_8_System_Boot.md)
3. Đọc [`My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/Example/config_DCD_OKMX6ULL-S.md`](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/Example/config_DCD_OKMX6ULL-S.md)

Nếu câu hỏi liên quan U-Boot chạy gì sau `_start`:

1. Đọc [`My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/flow_jump_uboot/flow_jump_uboot.md`](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/flow_jump_uboot/flow_jump_uboot.md)
2. Đọc [`My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/flow_create_uboot_imx6ull/flow_create_uboot_imx6ull.md`](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/flow_create_uboot_imx6ull/flow_create_uboot_imx6ull.md)
3. Đọc [`My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/Chapter_8_System_Boot.md`](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/i.MX_6ULL_Applications_Processor_Reference_Manual/Chapter_8_System_Boot.md)

Nếu câu hỏi liên quan flash bằng UUU:

1. Đọc [`My_doc/FORLINX_OKM6ULL-S/my_doc/AI_flow_gennerate_pass/How_to_flash_OKM6ULL-S.md`](My_doc/FORLINX_OKM6ULL-S/my_doc/AI_flow_gennerate_pass/How_to_flash_OKM6ULL-S.md)
2. Đọc [`My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/uuu_flash/uuu_flash.md`](My_doc/NXP_IMX6ULL_EVK/MY_MARKDOWN/uuu_flash/uuu_flash.md)
3. Đọc [`My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/Compare_uuu_with_IMX_Loader/Compare_uuu_with_IMX_Loader.md`](My_doc/NXP_IMX6ULL_EVK/MARKDOWN_DOC_NXP/Compare_uuu_with_IMX_Loader/Compare_uuu_with_IMX_Loader.md)

Nếu câu hỏi liên quan driver/kernel/module:

1. Đọc [`Phu_doc/docs/lessons/08_kernel_module/kernel_module.md`](Phu_doc/docs/lessons/08_kernel_module/kernel_module.md)
2. Đọc [`Phu_doc/docs/linux_device_drivers_3rd_book/chapters/INDEX.md`](Phu_doc/docs/linux_device_drivers_3rd_book/chapters/INDEX.md)
3. Đọc [`Phu_doc/docs/essential_linux_device_drivers_book/chapters/INDEX.md`](Phu_doc/docs/essential_linux_device_drivers_book/chapters/INDEX.md)

---

## 4. Quy Ước

- `My_doc`: tài liệu chính, ưu tiên đọc trước.
- `Phu_doc`: tài liệu phụ, dùng để tra cứu sâu.
- Các link trong file này dùng đường dẫn tương đối từ thư mục gốc `IMX6ULL_doccument`.
- Khi thêm tài liệu mới, nên cập nhật lại `index.md` để AI dễ lần theo đúng tài liệu.
