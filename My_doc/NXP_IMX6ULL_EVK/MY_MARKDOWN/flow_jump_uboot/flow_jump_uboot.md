# Flow sau khi Boot ROM nhảy vào U-Boot `_start`

Tài liệu này đi tiếp sau flow tạo `u-boot.imx`.

Flow trước đó:

```txt
Boot ROM
        |
        v
đọc IVT / Boot Data / DCD
        |
        v
chạy DCD để init DDR
        |
        v
load full image vào DDR
        |
        v
jump vào IVT.entry = 0x87800000
```

Ở phía U-Boot, địa chỉ:

```txt
0x87800000
```

chính là `_start`, được linker script khai báo:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/arch/arm/cpu/u-boot.lds
```

```ld
ENTRY(_start)
```

Code `_start` thực tế nằm ở:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/arch/arm/cpu/armv7/start.S
```

---

## 1. Tổng quan flow lớn

```txt
Boot ROM jump IVT.entry
        |
        v
0x87800000 / _start
        |
        v
arch/arm/cpu/armv7/start.S
        |
        |  save boot params
        |  set CPU mode SVC
        |  disable IRQ/FIQ
        |  set vector base
        |  low level CPU init
        v
bl _main
        |
        v
arch/arm/lib/crt0.S
        |
        |  setup stack
        |  setup gd
        |  board_init_f()
        |  relocate U-Boot
        |  clear BSS
        v
board_init_r()
        |
        v
common/board_r.c
        |
        |  init malloc
        |  init driver model
        |  init board
        |  init MMC/env/console/devices
        v
run_main_loop()
        |
        v
common/main.c: main_loop()
        |
        |  bootdelay_process()
        |  lấy bootcmd
        v
autoboot_command()
        |
        v
run_command_list(bootcmd)
        |
        v
load kernel + dtb
        |
        v
bootz / bootm
        |
        v
boot_jump_linux()
        |
        v
jump vào Linux kernel
```

---

## 2. `start.S`: điểm CPU bắt đầu chạy U-Boot

File:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/arch/arm/cpu/armv7/start.S
```

Đoạn đầu:

```asm
reset:
	/* Allow the board to save important registers */
	b	save_boot_params
save_boot_params_ret:
```

Ý nghĩa:

```txt
Boot ROM nhảy vào entry
        |
        v
U-Boot bắt đầu ở vector reset/_start
        |
        v
nhảy qua save_boot_params
        |
        v
quay lại save_boot_params_ret
```

`save_boot_params` là weak symbol:

```asm
ENTRY(save_boot_params)
	b	save_boot_params_ret
ENDPROC(save_boot_params)
	.weak	save_boot_params
```

Nếu board cần lưu thông tin Boot ROM truyền qua thanh ghi `r0-r3`, board có thể override hàm này. Nếu không override thì nó chỉ nhảy về lại `save_boot_params_ret`.

---

## 3. `start.S`: setup CPU mode, interrupt, vector

Sau khi quay lại `save_boot_params_ret`, U-Boot setup CPU cơ bản.

### 3.1. Chuyển CPU về SVC mode và tắt IRQ/FIQ

```asm
mrs	r0, cpsr
and	r1, r0, #0x1f
teq	r1, #0x1a
bicne	r0, r0, #0x1f
orrne	r0, r0, #0x13
orr	r0, r0, #0xc0
msr	cpsr,r0
```

Ý nghĩa:

```txt
set CPU mode = SVC32
disable IRQ
disable FIQ
```

Lý do: U-Boot mới vào, chưa setup interrupt controller, stack, exception handler đầy đủ. Tắt interrupt để không nhảy lung tung.

### 3.2. Set vector base

```asm
ldr	r0, =_start
mcr	p15, 0, r0, c12, c0, 0	@ Set VBAR
```

Ý nghĩa:

```txt
VBAR = _start
```

Tức là exception vector base trỏ về vùng vector của U-Boot.

### 3.3. Low-level CPU init

```asm
bl	cpu_init_cp15
bl	cpu_init_crit
```

Ý nghĩa tổng quát:

```txt
setup CP15
cache/MMU state cơ bản
low-level CPU/SoC init nếu config cho phép
```

Với flow DCD, DDR đã được Boot ROM init trước khi nhảy vào U-Boot. U-Boot vẫn cần setup lại trạng thái CPU cho môi trường chạy C của nó.

Cuối `start.S`:

```asm
bl	_main
```

Từ đây nhảy sang:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/arch/arm/lib/crt0.S
```

---

## 4. `crt0.S`: chuẩn bị môi trường C

File:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/arch/arm/lib/crt0.S
```

Entry:

```asm
ENTRY(_main)
```

`crt0.S` là cầu nối từ assembly sang C.

Nhiệm vụ chính:

```txt
setup stack tạm
setup global data pointer gd
gọi board_init_f()
relocate U-Boot
clear BSS
gọi board_init_r()
```

---

## 5. `_main`: setup stack và `gd`

Đoạn đầu:

```asm
ldr	r0, =(CONFIG_SYS_INIT_SP_ADDR)
bic	r0, r0, #7
mov	sp, r0
bl	board_init_f_alloc_reserve
mov	sp, r0
mov	r9, r0
bl	board_init_f_init_reserve
```

Ý nghĩa:

```txt
CONFIG_SYS_INIT_SP_ADDR     địa chỉ stack tạm
sp                          stack pointer
r9                          giữ con trỏ gd trên ARM
board_init_f_alloc_reserve  reserve chỗ cho gd/malloc early
board_init_f_init_reserve   init vùng gd ban đầu
```

Sau đó:

```asm
mov	r0, #0
bl	board_init_f
```

Tức là gọi:

```c
board_init_f(0);
```

File:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/common/board_f.c
```

---

## 6. `board_init_f()`: init giai đoạn đầu

Code:

```c
void board_init_f(ulong boot_flags)
{
	gd->flags = boot_flags;
	gd->have_console = 0;

	if (initcall_run_list(init_sequence_f))
		hang();
}
```

Nó chạy list:

```c
static const init_fnc_t init_sequence_f[] = {
	setup_mon_len,
	fdtdec_setup,
	initf_malloc,
	log_init,
	initf_bootstage,
	arch_cpu_init,
	mach_cpu_init,
	initf_dm,
	board_early_init_f,
	timer_init,
	env_init,
	init_baud_rate,
	serial_init,
	console_init_f,
	display_options,
	print_cpuinfo,
	show_board_info,
	announce_dram_init,
	dram_init,
	setup_dest_addr,
	reserve_uboot,
	reserve_malloc,
	reserve_board,
	reserve_global_data,
	reserve_fdt,
	reserve_stacks,
	dram_init_banksize,
	show_dram_config,
	setup_bdinfo,
	reloc_fdt,
	setup_reloc,
	clear_bss,
	NULL,
};
```

Danh sách trên đã rút gọn để dễ đọc. Ý nghĩa chính:

```txt
init early malloc/log/bootstage
init CPU/SoC/DM sớm
init timer/env/serial console giai đoạn đầu
đọc thông tin DRAM
tính vùng RAM để relocate U-Boot
reserve malloc/gd/fdt/stack
setup thông tin relocation
```

Điểm quan trọng:

```txt
board_init_f() chưa phải U-Boot fully running.
Nó chuẩn bị dữ liệu để relocate và chạy board_init_r().
```

---

## 7. Relocate U-Boot

Sau `board_init_f()` quay về `crt0.S`, U-Boot proper sẽ relocate.

Trong `crt0.S`:

```asm
ldr	r0, [r9, #GD_START_ADDR_SP]
mov	sp, r0
ldr	r9, [r9, #GD_NEW_GD]

ldr	r0, [r9, #GD_RELOC_OFF]
add	lr, lr, r0
ldr	r0, [r9, #GD_RELOCADDR]
b	relocate_code
```

Ý nghĩa:

```txt
sp = gd->start_addr_sp
gd = gd->new_gd
r0 = gd->relocaddr
nhảy vào relocate_code()
```

`relocate_code()` copy U-Boot từ vị trí hiện tại sang địa chỉ relocation trong DDR.

Sau khi relocate xong, code quay lại label:

```asm
here:
	bl	relocate_vectors
	bl	c_runtime_cpu_setup
	CLEAR_BSS
```

Ý nghĩa:

```txt
relocate vector
setup CPU runtime sau relocation
clear BSS
```

Sau đó gọi `board_init_r()`:

```asm
mov     r0, r9
ldr	r1, [r9, #GD_RELOCADDR]
ldr	pc, =board_init_r
```

Tức là:

```c
board_init_r(gd, gd->relocaddr);
```

---

## 8. `board_init_r()`: init đầy đủ sau relocation

File:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/common/board_r.c
```

Code:

```c
void board_init_r(gd_t *new_gd, ulong dest_addr)
{
	...
	if (initcall_run_list(init_sequence_r))
		hang();

	hang();
}
```

Nó chạy list:

```c
static init_fnc_t init_sequence_r[] = {
	initr_trace,
	initr_reloc,
	initr_caches,
	initr_reloc_global_data,
	initr_malloc,
	log_init,
	initr_bootstage,
	initr_dm,
	board_init,
	initr_dm_devices,
	stdio_init_tables,
	serial_initialize,
	initr_announce,
	power_init_board,
	initr_mmc,
	initr_env,
	stdio_add_devices,
	jumptable_init,
	console_init_r,
	arch_misc_init,
	misc_init_r,
	interrupt_init,
	board_late_init,
	initr_fastboot_setup,
	initr_net,
	run_main_loop,
};
```

Danh sách trên cũng đã rút gọn. Ý nghĩa chính:

```txt
enable cache runtime
init malloc chính
init driver model chính
init board
init MMC
load environment
init console đầy đủ
init device table
init fastboot/network nếu bật
vào main_loop()
```

Sau `board_init_r()`, U-Boot đã có console, env, MMC, command subsystem và các device cơ bản.

---

## 9. `run_main_loop()` và `main_loop()`

Trong `board_r.c`:

```c
static int run_main_loop(void)
{
	for (;;)
		main_loop();
	return 0;
}
```

File `main_loop()`:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/common/main.c
```

Code:

```c
void main_loop(void)
{
	const char *s;

	bootstage_mark_name(BOOTSTAGE_ID_MAIN_LOOP, "main_loop");

	cli_init();

	if (IS_ENABLED(CONFIG_USE_PREBOOT))
		run_preboot_environment_command();

	s = bootdelay_process();
	if (cli_process_fdt(&s))
		cli_secure_boot_cmd(s);

	autoboot_command(s);

	cli_loop();
	panic("No CLI available");
}
```

Flow:

```txt
main_loop()
        |
        v
cli_init()
        |
        v
run preboot nếu có
        |
        v
bootdelay_process()
        |
        v
lấy bootcmd/altbootcmd/failbootcmd
        |
        v
autoboot_command(s)
        |
        v
nếu không bị stop autoboot thì chạy bootcmd
        |
        v
nếu bị stop thì vào cli_loop()
```

---

## 10. `bootdelay_process()`: lấy `bootcmd`

File:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/common/autoboot.c
```

Đoạn chính:

```c
if (bootcount_error())
	s = env_get("altbootcmd");
else
	s = env_get("bootcmd");
```

Với i.MX/NXP còn có nhánh USB/UUU:

```c
if (is_boot_from_usb() && env_get("bootcmd_mfg")) {
	s = env_get("bootcmd_mfg");
	printf("Run bootcmd_mfg: %s\n", s);
}
```

Ý nghĩa:

```txt
boot bình thường       -> lấy bootcmd
bootcount lỗi          -> lấy altbootcmd
USB/mfgtools/UUU       -> có thể lấy bootcmd_mfg hoặc fastboot
```

Sau đó `main_loop()` gọi:

```c
autoboot_command(s);
```

---

## 11. `autoboot_command()`: chạy chuỗi lệnh boot

Code:

```c
void autoboot_command(const char *s)
{
	if (s && (stored_bootdelay == -2 ||
		 (stored_bootdelay != -1 && !abortboot(stored_bootdelay)))) {
		run_command_list(s, -1, 0);
	}
}
```

Ý nghĩa:

```txt
s = bootcmd
        |
        v
đợi bootdelay
        |
        v
nếu user không bấm phím stop autoboot
        |
        v
run_command_list(s)
```

`bootcmd` thường là chuỗi lệnh như:

```txt
load kernel vào RAM
load dtb vào RAM
set bootargs
bootz ${loadaddr} - ${fdt_addr}
```

U-Boot không tự hiểu rootfs bằng cách mount rootfs. Nó chỉ truyền `bootargs` cho kernel, ví dụ:

```txt
root=/dev/mmcblk1p2 rootwait rw
```

Kernel mới là thằng mount rootfs sau khi chạy.

---

## 12. `bootz`: chuẩn bị boot Linux zImage

File:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/cmd/bootz.c
```

Command:

```c
U_BOOT_CMD(
	bootz,	CONFIG_SYS_MAXARGS,	1,	do_bootz,
	"boot Linux zImage image from memory", bootz_help_text
);
```

Khi `bootcmd` có:

```txt
bootz ${loadaddr} - ${fdt_addr}
```

thì U-Boot gọi:

```c
do_bootz()
```

Flow:

```txt
do_bootz()
        |
        v
bootz_start()
        |
        |  lấy kernel address từ argv[0]
        |  bootz_setup()
        |  bootm_find_images()
        |  tìm/initrd/fdt
        v
bootm_disable_interrupts()
        |
        v
do_bootm_states()
        |
        |  BOOTM_STATE_OS_PREP
        |  BOOTM_STATE_OS_FAKE_GO
        |  BOOTM_STATE_OS_GO
        v
do_bootm_linux()
```

---

## 13. `boot_jump_linux()`: nhảy vào kernel

File:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/arch/arm/lib/bootm.c
```

Đoạn ARM 32-bit:

```c
void (*kernel_entry)(int zero, int arch, uint params);

kernel_entry = (void (*)(int, int, uint))images->ep;
...
if (CONFIG_IS_ENABLED(OF_LIBFDT) && images->ft_len)
	r2 = (unsigned long)images->ft_addr;
else
	r2 = gd->bd->bi_boot_params;

kernel_entry(0, machid, r2);
```

Với device tree:

```txt
r0 = 0
r1 = machid
r2 = địa chỉ FDT
pc = images->ep
```

Từ đây quyền điều khiển chuyển sang Linux kernel.

Sau lệnh này:

```txt
U-Boot không còn chạy nữa
kernel bắt đầu chạy
kernel đọc FDT
kernel init driver
kernel parse bootargs
kernel mount rootfs
kernel chạy init/systemd/busybox init
```

---

## 14. Flow đầy đủ từ `_start` tới kernel

```txt
Boot ROM
        |
        v
IVT.entry = 0x87800000
        |
        v
_start / reset
        |
        v
start.S
        |
        | save_boot_params
        | set SVC mode
        | disable IRQ/FIQ
        | set VBAR
        | cpu_init_cp15
        | cpu_init_crit
        v
_main / crt0.S
        |
        | setup stack
        | setup gd
        v
board_init_f()
        |
        | early malloc/log/timer/env/serial
        | dram_init
        | reserve relocation memory
        | setup_reloc
        v
relocate_code()
        |
        | copy U-Boot lên relocaddr
        | relocate vectors
        | clear BSS
        v
board_init_r()
        |
        | init malloc chính
        | init DM
        | board_init
        | init MMC
        | init env
        | init console
        | board_late_init
        v
run_main_loop()
        |
        v
main_loop()
        |
        | bootdelay_process()
        | env_get("bootcmd")
        v
autoboot_command()
        |
        | run_command_list(bootcmd)
        v
load kernel + dtb
        |
        v
bootz / bootm
        |
        v
boot_jump_linux()
        |
        v
kernel_entry(0, machid, fdt_addr)
        |
        v
Linux kernel
```

---

## 15. Tóm tắt đúng ý

```txt
Boot ROM chỉ đưa CPU tới U-Boot entry.
start.S setup CPU cực sớm.
crt0.S setup stack/gd để gọi C.
board_init_f() init sớm và tính relocation.
relocate_code() chuyển U-Boot tới vị trí chạy chính.
board_init_r() init đầy đủ device/env/console.
main_loop() lấy bootcmd.
autoboot_command() chạy bootcmd.
bootz/bootm chuẩn bị kernel + dtb.
boot_jump_linux() nhảy vào kernel.
Kernel mới đọc FDT sâu, init driver và mount rootfs.
```
