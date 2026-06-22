# Flow cách Yocto dùng tool để build image i.MX cho Boot ROM parse

File bbappend của em:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-bsp/u-boot/u-boot-imx_%.bbappend
```

Lần theo path này sẽ ra flow tạo image U-Boot cho i.MX6ULL.

File này không trực tiếp pack ra `u-boot.imx`. Nó có nhiệm vụ đưa defconfig của em vào source U-Boot và patch lại file DCD/image config của hãng:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/board/freescale/mx6ullevk/imximage.cfg
```

File `imximage.cfg` này chứa các thông tin để `mkimage` tạo ra format mà Boot ROM NXP hiểu được:

```txt
IMAGE_VERSION 2
BOOT_FROM sd
DATA 4 ...
DATA 4 ...
```

Trong đó các dòng `DATA 4 ...` chính là DCD dùng để Boot ROM init DDR.

---

## 1. Đi từ defconfig của em

Defconfig của em nằm ở:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-bsp/u-boot/files/okmx6ull_s_emmc_defconfig
```

Bên trong có các config quan trọng:

```txt
CONFIG_ARM=y
CONFIG_ARCH_MX6=y
CONFIG_MX6ULL=y
CONFIG_TARGET_MX6ULL_14X14_EVK=y
```

Mấy config này nói với U-Boot build system rằng:

```txt
đây là ARM
đây là dòng i.MX6
đây là i.MX6ULL
target board đang dùng là mx6ull_14x14_evk
```

---

## 2. Kconfig chọn board và file imximage.cfg

Vì defconfig bật:

```txt
CONFIG_TARGET_MX6ULL_14X14_EVK=y
```

nên Kconfig này được active:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/board/freescale/mx6ullevk/Kconfig
```

Nó có nội dung:

```kconfig
if TARGET_MX6ULL_14X14_EVK || TARGET_MX6ULL_9X9_EVK

config SYS_BOARD
	default "mx6ullevk"

config SYS_VENDOR
	default "freescale"

config SYS_CONFIG_NAME
	default "mx6ullevk"

config IMX_CONFIG
	default "board/freescale/mx6ullevk/imximage.cfg"

config SYS_TEXT_BASE
	default 0x87800000
endif
```

Chỗ này không pack image. Nó chỉ chọn các giá trị default cho board:

```txt
SYS_BOARD       = mx6ullevk
SYS_VENDOR      = freescale
SYS_CONFIG_NAME = mx6ullevk
IMX_CONFIG      = board/freescale/mx6ullevk/imximage.cfg
SYS_TEXT_BASE   = 0x87800000
```

---

## 3. Kconfig sinh ra .config

Trong Kconfig, tên option là:

```kconfig
config IMX_CONFIG
```

Nhưng khi export ra `.config`, Kconfig tự thêm prefix `CONFIG_`, nên nó thành:

```txt
CONFIG_IMX_CONFIG="board/freescale/mx6ullevk/imximage.cfg"
```

File `.config` nằm ở:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/build/okmx6ull_s_emmc_defconfig/.config
```

Dòng quan trọng:

```txt
CONFIG_IMX_CONFIG="board/freescale/mx6ullevk/imximage.cfg"
```

Nói ngắn gọn:

```txt
config IMX_CONFIG trong Kconfig
        |
        v
CONFIG_IMX_CONFIG trong .config
```

---

## 4. Makefile lấy CONFIG_IMX_CONFIG để tạo u-boot.cfgout

Makefile của i.MX nằm ở:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/arch/arm/mach-imx/Makefile
```

Nó lấy config image bằng dòng:

```make
IMX_CONFIG = $(CONFIG_IMX_CONFIG:"%"=%)
```

Dòng này lấy:

```txt
CONFIG_IMX_CONFIG="board/freescale/mx6ullevk/imximage.cfg"
```

bỏ dấu nháy đi, thành:

```txt
IMX_CONFIG = board/freescale/mx6ullevk/imximage.cfg
```

Sau đó rule này tạo file `u-boot.cfgout`:

```make
%.cfgout: $(IMX_CONFIG) FORCE
	$(Q)mkdir -p $(dir $@)
	$(call if_changed_dep,cpp_cfg)
```

Tức là:

```txt
imximage.cfg
        |
        v
u-boot.cfgout
```

`u-boot.cfgout` là file config đã qua C preprocessor. Nó là input thật được truyền cho `mkimage` bằng option `-n`.

File gốc `imximage.cfg` vẫn còn các đoạn `#include`, `#ifdef`, `#elif`, `#else`:

```c
#include <config.h>

#ifdef CONFIG_QSPI_BOOT
BOOT_FROM	qspi
#elif defined(CONFIG_NOR_BOOT)
BOOT_FROM	nor
#else
BOOT_FROM	sd
#endif
```

Sau khi chạy rule `%.cfgout`, build system dùng C preprocessor để xử lý các điều kiện này.

> **Ghi chú về thiết bị boot:** Trước khi đến bước này, `defconfig` đã cung cấp các lựa chọn dùng để build image. C preprocessor đọc các macro `CONFIG_*` được sinh từ `.config` rồi chọn đúng một dòng `BOOT_FROM`.
>
> ```txt
> CONFIG_QSPI_BOOT=y  -> BOOT_FROM qspi
> CONFIG_NOR_BOOT=y   -> BOOT_FROM nor
> không bật hai config trên -> BOOT_FROM sd
> ```
>
> Với cấu hình boot từ eMMC của board em, image đi vào nhánh cuối và nhận:
>
> ```txt
> BOOT_FROM sd
> ```
>
> Trong `imximage`, từ khóa `sd` được dùng chung cho kiểu đóng gói SD/eMMC vì cả hai đi qua giao diện USDHC và dùng cùng IVT offset/initial load layout. Điều này không có nghĩa eMMC trở thành SD; nó chỉ có nghĩa `mkimage` dùng layout `sd` để tạo image cho cả SD và eMMC.
>
> `BOOT_FROM sd` chỉ quyết định cách **đóng gói** `u-boot.imx`. Khi board chạy thật, Boot ROM vẫn xác định thiết bị boot thực tế từ BOOT_MODE pin/eFuse. Cấu hình phần cứng và layout image phải khớp nhau.

Với board của em, nếu không bật:

```txt
CONFIG_QSPI_BOOT
CONFIG_NOR_BOOT
```

thì nhánh cuối được chọn:

```txt
BOOT_FROM sd
```

Vì vậy trong file build output:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/build/okmx6ull_s_emmc_defconfig/u-boot.cfgout
```

sẽ thấy dòng đã được resolve:

```txt
BOOT_FROM sd
```

Nói ngắn gọn:

```txt
imximage.cfg      file gốc, còn #ifdef/#include/macro
        |
        |  rule %.cfgout chạy cpp_cfg
        v
u-boot.cfgout     file đã preprocess, mkimage đọc file này
```

Sau đó lệnh tạo image dùng:

```sh
mkimage -n u-boot.cfgout ...
```

chứ không truyền trực tiếp raw `imximage.cfg`.

Lệnh `mkimage` đã được Make expand đầy đủ và lưu tại:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/build/okmx6ull_s_emmc_defconfig/.u-boot.imx.cmd
```

Path raw:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/build/okmx6ull_s_emmc_defconfig/.u-boot.imx.cmd
```

Nơi định nghĩa rule và các tham số để Make sinh ra lệnh trên:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/arch/arm/mach-imx/Makefile
```

Trong đó:

```make
MKIMAGEFLAGS_u-boot.imx = -n $(filter-out $(PLUGIN).bin $(QSPI_HEADER) $< $(PHONY),$^) \
	-T $(IMAGE_TYPE) -e $(CONFIG_SYS_TEXT_BASE)

u-boot.imx: u-boot.bin u-boot.cfgout $(PLUGIN).bin $(QSPI_HEADER) FORCE
	$(call if_changed,mkimage)
```

---

## 5. Makefile chọn IMAGE_TYPE = imximage

Trong cùng file:

```txt
arch/arm/mach-imx/Makefile
```

có đoạn:

```make
ifeq ($(CONFIG_ARCH_IMX8), y)
IMAGE_TYPE := imx8image
else ifeq ($(CONFIG_ARCH_IMX8M), y)
IMAGE_TYPE := imx8mimage
else
IMAGE_TYPE := imximage
endif
```

Board của em là i.MX6ULL, không phải i.MX8 hay i.MX8M, nên nó chọn:

```txt
IMAGE_TYPE := imximage
```

Sau đó nó dùng biến này trong flags:

```make
MKIMAGEFLAGS_u-boot.imx = -n $(filter-out $(PLUGIN).bin $(QSPI_HEADER) $< $(PHONY),$^) \
	-T $(IMAGE_TYPE) -e $(CONFIG_SYS_TEXT_BASE)
u-boot.imx: MKIMAGEOUTPUT = u-boot.imx.log
```

Với board của em, dòng này sẽ expand thành:

```txt
-n u-boot.cfgout -T imximage -e 0x87800000
```

Trong đó:

```txt
-n u-boot.cfgout     file config image/DCD
-T imximage          dùng handler imximage trong tools/imximage.c
-e 0x87800000        entry point của U-Boot
```

---

## 6. Lệnh mkimage thật sự được gọi

Build sinh ra file:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/build/okmx6ull_s_emmc_defconfig/.u-boot.imx.cmd
```

Bên trong có lệnh thật:

```sh
./tools/mkimage -n u-boot.cfgout -T imximage -e 0x87800000 -d u-boot.bin u-boot.imx >u-boot.imx.log && cat u-boot.imx.log
```

Đây là lệnh tạo ra:

```txt
u-boot.imx
```

từ:

```txt
u-boot.bin
u-boot.cfgout
```

---

## 7. mkimage.c nhận lệnh -T imximage trước

Lệnh thật ở trên chạy chương trình:

```txt
tools/mkimage
```

Source chính của chương trình này nằm ở:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/mkimage.c
```

`tools/imximage.c` không có `main()`. Nó chỉ là module xử lý format i.MX.

Hàm `main()` thật nằm trong `tools/mkimage.c`:

```c
int main(int argc, char **argv)
{
	...
	process_args(argc, argv);

	/* set tparams as per input type_id */
	tparams = imagetool_get_type(params.type);
	...
}
```

Trước đó, `process_args()` parse option `-T imximage`:

```c
case 'T':
	if (strcmp(optarg, "list") == 0) {
		show_valid_options(IH_TYPE);
		exit(EXIT_SUCCESS);
	}
	type = genimg_get_type_id(optarg);
	if (type < 0) {
		show_valid_options(IH_TYPE);
		usage("Invalid image type");
	}
	break;
```

Với lệnh:

```sh
-T imximage
```

nó biến chuỗi `imximage` thành image type ID:

```txt
IH_TYPE_IMXIMAGE
```

### 7.1. `genimg_get_type_id()` lấy `IH_TYPE_IMXIMAGE` ở đâu

Trong:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/include/image.h
```

chỉ có prototype:

```c
int genimg_get_type_id(const char *name);
```

Prototype chỉ báo cho compiler biết hàm tồn tại. Phần định nghĩa thật nằm trong:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/boot/image.c
```

```c
int genimg_get_type_id(const char *name)
{
	return get_table_entry_id(uimage_type, "Image", name);
}
```

Trong cùng file có bảng ánh xạ:

```c
static const table_entry_t uimage_type[] = {
	...
	{
		IH_TYPE_IMXIMAGE,
		"imximage",
		"Freescale i.MX Boot Image",
	},
	...
};
```

Mỗi phần tử có dạng:

```txt
ID                  tên ngắn       tên mô tả
IH_TYPE_IMXIMAGE    "imximage"     "Freescale i.MX Boot Image"
```

Với option:

```sh
-T imximage
```

thì:

```c
optarg = "imximage";
type = genimg_get_type_id(optarg);
```

tương đương:

```c
type = genimg_get_type_id("imximage");
```

`genimg_get_type_id()` gọi:

```c
get_table_entry_id(uimage_type, "Image", "imximage");
```

Hàm `get_table_entry_id()` duyệt toàn bộ bảng:

```c
for (t = table; t->id >= 0; ++t) {
	if (t->sname &&
	    !strcasecmp(t->sname, name))
		return t->id;
}
```

Khi tìm thấy phần tử:

```c
{ IH_TYPE_IMXIMAGE, "imximage", ... }
```

nó trả về:

```c
return IH_TYPE_IMXIMAGE;
```

Do đó kết quả cuối cùng là:

```c
type = IH_TYPE_IMXIMAGE;
```

Giá trị enum `IH_TYPE_IMXIMAGE` được khai báo trong:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/include/image.h
```

Flow:

```txt
-T imximage
      |
      v
optarg = "imximage"
      |
      v
genimg_get_type_id("imximage")
      |
      v
get_table_entry_id(uimage_type, ...)
      |
      v
duyệt bảng uimage_type[]
      |
      v
tìm thấy "imximage" -> IH_TYPE_IMXIMAGE
      |
      v
type = IH_TYPE_IMXIMAGE
```

Sau đó:

```c
tparams = imagetool_get_type(params.type);
```

sẽ đi tìm handler nào support `IH_TYPE_IMXIMAGE`.

### 7.2. Từ `IH_TYPE_IMXIMAGE` tìm sang handler trong `tools/imximage.c`

Sau khi `process_args()` chạy xong:

```c
params.type = IH_TYPE_IMXIMAGE;
```

`main()` trong `tools/mkimage.c` gọi:

```c
tparams = imagetool_get_type(params.type);
```

Tương đương:

```c
tparams = imagetool_get_type(IH_TYPE_IMXIMAGE);
```

Path của `mkimage.c`:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/mkimage.c
```

Hàm `imagetool_get_type()` nằm trong:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imagetool.c
```

Code chính:

```c
struct image_type_params *imagetool_get_type(int type)
{
	struct image_type_params **curr;
	struct image_type_params **start = __start_image_type;
	struct image_type_params **end = __stop_image_type;

	for (curr = start; curr != end; curr++) {
		if ((*curr)->check_image_type) {
			if (!(*curr)->check_image_type(type))
				return *curr;
		}
	}

	return NULL;
}
```

Nó không nhảy thẳng vào `tools/imximage.c`. Nó duyệt tất cả handler đã được đăng ký trong linker section:

```txt
image_type
```

Giới hạn của section được linker cung cấp bằng hai symbol:

```txt
__start_image_type
__stop_image_type
```

Cuối file:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imximage.c
```

có macro đăng ký handler:

```c
U_BOOT_IMAGE_TYPE(
	imximage,
	"Freescale i.MX Boot Image support",
	0,
	NULL,
	imximage_check_params,
	imximage_verify_header,
	imximage_print_header,
	imximage_set_header,
	NULL,
	imximage_check_image_types,
	NULL,
	imximage_generate
);
```

Macro `U_BOOT_IMAGE_TYPE()` được định nghĩa trong:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imagetool.h
```

Lúc compile `tools/mkimage`, macro này mở rộng gần giống:

```c
static struct image_type_params image_type_imximage = {
	.name = "Freescale i.MX Boot Image support",
	.check_params = imximage_check_params,
	.verify_header = imximage_verify_header,
	.print_header = imximage_print_header,
	.set_header = imximage_set_header,
	.check_image_type = imximage_check_image_types,
	.vrec_header = imximage_generate,
};

static struct image_type_params *image_type_ptr_imximage
	__attribute__((section("image_type"))) =
	&image_type_imximage;
```

Dòng:

```c
__attribute__((section("image_type")))
```

đưa con trỏ tới `image_type_imximage` vào section `image_type`. Vì thế `imagetool_get_type()` có thể tìm thấy handler này khi duyệt section.

Khi vòng lặp đến handler `imximage`, nó gọi:

```c
imximage_check_image_types(IH_TYPE_IMXIMAGE);
```

Hàm kiểm tra trong `tools/imximage.c`:

```c
static int imximage_check_image_types(uint8_t type)
{
	if (type == IH_TYPE_IMXIMAGE)
		return EXIT_SUCCESS;
	else
		return EXIT_FAILURE;
}
```

Do type đang đúng bằng:

```c
IH_TYPE_IMXIMAGE
```

hàm trả về:

```c
EXIT_SUCCESS /* bằng 0 */
```

Nên điều kiện trong `imagetool_get_type()` đúng:

```c
if (!(*curr)->check_image_type(type))
	return *curr;
```

Kết quả:

```c
tparams = &image_type_imximage;
```

Từ đây `mkimage.c` mới gọi các callback trong `tools/imximage.c` thông qua `tparams`:

```c
tparams->check_params(...);  /* imximage_check_params() */
tparams->vrec_header(...);   /* imximage_generate() */
tparams->set_header(...);    /* imximage_set_header() */
tparams->print_header(...);  /* imximage_print_header() */
```

Flow đầy đủ:

```txt
params.type = IH_TYPE_IMXIMAGE
        |
        v
imagetool_get_type(IH_TYPE_IMXIMAGE)
        |
        v
duyệt từ __start_image_type đến __stop_image_type
        |
        v
đến handler image_type_imximage
        |
        v
imximage_check_image_types(IH_TYPE_IMXIMAGE)
        |
        v
return EXIT_SUCCESS
        |
        v
tparams = &image_type_imximage
        |
        +-- imximage_check_params()
        +-- imximage_generate()
        +-- imximage_set_header()
        `-- imximage_print_header()
```

Nút nối từ `IH_TYPE_IMXIMAGE` sang handler `tools/imximage.c` là:

```txt
imagetool_get_type()
        +
linker section image_type
        +
imximage_check_image_types()
```

Nói ngắn gọn:

```txt
Makefile
        |
        v
tools/mkimage -T imximage
        |
        v
tools/mkimage.c: main()
        |
        v
process_args() parse -T imximage
        |
        v
params.type = IH_TYPE_IMXIMAGE
        |
        v
imagetool_get_type(params.type)
```

---

## 8. Handler imximage được đăng ký trong tools/imximage.c

File handler i.MX nằm ở:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imximage.c
```

có macro:

```c
U_BOOT_IMAGE_TYPE(
	imximage,
	"Freescale i.MX Boot Image support",
	0,
	NULL,
	imximage_check_params,
	imximage_verify_header,
	imximage_print_header,
	imximage_set_header,
	NULL,
	imximage_check_image_types,
	NULL,
	imximage_generate
);
```

Macro này đăng ký image type tên là:

```txt
imximage
```

Nó không chạy ngay tại chỗ này. Macro này chỉ tạo ra một `struct image_type_params` để đăng ký với tool `mkimage`.

Định nghĩa macro nằm ở:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imagetool.h
```

Đoạn macro thật trong `tools/imagetool.h`:

```c
#define U_BOOT_IMAGE_TYPE( \
		_id, \
		_name, \
		_header_size, \
		_header, \
		_check_params, \
		_verify_header, \
		_print_header, \
		_set_header, \
		_extract_subimage, \
		_check_image_type, \
		_fflag_handle, \
		_vrec_header \
	) \
	static struct image_type_params __cat(image_type_, _id) = \
	{ \
		.name = _name, \
		.header_size = _header_size, \
		.hdr = _header, \
		.check_params = _check_params, \
		.verify_header = _verify_header, \
		.print_header = _print_header, \
		.set_header = _set_header, \
		.extract_subimage = _extract_subimage, \
		.check_image_type = _check_image_type, \
		.fflag_handle = _fflag_handle, \
		.vrec_header = _vrec_header \
	}; \
	static struct image_type_params *SECTION(image_type) __used \
		__cat(image_type_ptr_, _id) = &__cat(image_type_, _id)
```

Ở đây:

```txt
_id = imximage
```

nên:

```c
__cat(image_type_, _id)
```

sẽ thành:

```txt
image_type_imximage
```

và:

```c
__cat(image_type_ptr_, _id)
```

sẽ thành:

```txt
image_type_ptr_imximage
```

`SECTION(image_type)` cũng là macro trong `tools/imagetool.h`:

```c
#define SECTION(name) __attribute__((section(#name)))
```

nên:

```c
SECTION(image_type)
```

sẽ thành:

```c
__attribute__((section("image_type")))
```

Vì vậy đoạn:

```c
U_BOOT_IMAGE_TYPE(
	imximage,
	...
	imximage_check_image_types,
	...
	imximage_generate
);
```

sau khi preprocessor expand sẽ tương đương ý nghĩa với:

```c
static struct image_type_params image_type_imximage = {
	.name = "Freescale i.MX Boot Image support",
	.header_size = 0,
	.hdr = NULL,
	.check_params = imximage_check_params,
	.verify_header = imximage_verify_header,
	.print_header = imximage_print_header,
	.set_header = imximage_set_header,
	.extract_subimage = NULL,
	.check_image_type = imximage_check_image_types,
	.fflag_handle = NULL,
	.vrec_header = imximage_generate,
};

static struct image_type_params *image_type_ptr_imximage
	__attribute__((section("image_type"))) __used
	= &image_type_imximage;
```

Nghĩa là khi build `tools/mkimage`, handler `imximage` được nhét sẵn vào section đặc biệt tên:

```txt
image_type
```

Sau đó lúc runtime, `imagetool_get_type()` sẽ duyệt từ:

```txt
__start_image_type
```

đến:

```txt
__stop_image_type
```

để tìm các handler đã được nhét vào section `image_type`.

Ý nghĩa thực tế của đoạn trên là tạo ra một handler gần giống như:

```c
.name             = "Freescale i.MX Boot Image support";
.header_size      = 0;
.hdr              = NULL;
.check_params     = imximage_check_params;
.verify_header    = imximage_verify_header;
.print_header     = imximage_print_header;
.set_header       = imximage_set_header;
.extract_subimage = NULL;
.check_image_type = imximage_check_image_types;
.fflag_handle     = NULL;
.vrec_header      = imximage_generate;
```

Nên khi `mkimage` chạy với:

```sh
-T imximage
```

nó sẽ gọi `imagetool_get_type()` để tìm handler nào support type `imximage`.

Luồng tìm handler nằm ở:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/tools/imagetool.c
```

Nó scan các handler đã đăng ký, rồi gọi:

```txt
imximage_check_image_types()
```

Nếu type đang build là `IH_TYPE_IMXIMAGE`, nó sẽ chọn đúng handler `imximage`.

Các callback quan trọng:

```txt
imximage_check_params()
```

Hàm này kiểm tra tham số của lệnh `mkimage` có hợp lệ không. Với `imximage`, nó cần có config image truyền qua option `-n`, tức là:

```txt
-n u-boot.cfgout
```

```txt
imximage_generate()
```

Hàm này chạy sớm để tạo vùng header động cho i.MX image. Nó parse `u-boot.cfgout`, đọc các dòng như:

```txt
IMAGE_VERSION 2
BOOT_FROM sd
DATA 4 ...
```

Từ đó nó tính ra:

```txt
imximage_ivt_offset     = 0x400
imximage_init_loadsize  = 0x1000
```

Sau đó nó cấp phát vùng header để lát nữa nhét IVT, Boot Data và DCD vào.

```txt
imximage_set_header()
```

Đây là hàm điền nội dung thật vào header. Nó tạo các field mà Boot ROM sẽ đọc:

```txt
IVT.entry
IVT.self
IVT.dcd_ptr
IVT.boot_data_ptr
BootData.start
BootData.size
```

Với `IMAGE_VERSION 2`, bên trong `imximage_set_header()` sẽ gọi tiếp:

```txt
set_imx_hdr_v2()
```

Đây là đoạn tạo format IVT v2 cho i.MX6ULL.

```txt
imximage_print_header()
```

Hàm này in thông tin ra log sau khi tạo image. Output nằm trong:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/build/okmx6ull_s_emmc_defconfig/u-boot.imx.log
```

Ví dụ các dòng kiểu:

```txt
Image Type:   Freescale IMX Boot Image
Image Ver:    2
Mode:         DCD
Data Size:    ...
Load Address: ...
Entry Point:  ...
```

```txt
imximage_verify_header()
```

Hàm này dùng khi kiểm tra hoặc list một image đã có, ví dụ khi `mkimage` cần verify header. Nó không phải bước chính để tạo IVT mới.

Tóm tắt đoạn này:

```txt
                              +----------------------+
                              |  u-boot.cfgout       |
                              |  IMAGE_VERSION 2     |
                              |  BOOT_FROM sd        |
                              |  DATA 4 ...          |
                              +----------+-----------+
                                         |
                                         | -n u-boot.cfgout
                                         v
+----------------------+       +----------------------+
| U_BOOT_IMAGE_TYPE    |       | tools/mkimage        |
| đăng ký callback     |       | chương trình chạy    |
| imximage             |       | thật sự              |
+----------+-----------+       +----------+-----------+
           |                              |
           | -T imximage                 |
           +----------------------------->|
                                          v
                              +----------------------+
                              | imagetool_get_type() |
                              | tìm handler imximage |
                              +----------+-----------+
                                         |
                                         v
                              +----------------------+
                              | imximage_check_params|
                              | check tham số mkimage|
                              +----------+-----------+
                                         |
                                         v
                              +----------------------+
                              | imximage_generate()  |
                              | parse cfgout lần 1   |
                              | lấy version/boot_from|
                              | tính header size     |
                              | malloc header tạm    |
                              +----------+-----------+
                                         |
                                         v
                              +----------------------+
                              | mkimage ghi          |
                              | header tạm           |
                              | + u-boot.bin         |
                              | ra u-boot.imx        |
                              +----------+-----------+
                                         |
                                         v
                              +----------------------+
                              | imximage_set_header()|
                              | parse cfgout lần 2   |
                              | nhét DCD             |
                              | set IVT/Boot Data    |
                              +----------+-----------+
                                         |
                                         v
                              +----------------------+
                              | set_imx_hdr_v2()     |
                              | điền IVT.entry       |
                              | IVT.self             |
                              | IVT.dcd_ptr          |
                              | IVT.boot_data_ptr    |
                              | BootData.start       |
                              +----------+-----------+
                                         |
                                         v
                              +----------------------+
                              | imximage_print_header|
                              | ghi u-boot.imx.log   |
                              +----------------------+
```

Nhìn theo vai trò:

```txt
tools/mkimage        thằng điều phối
U_BOOT_IMAGE_TYPE    bảng callback để mkimage tìm đúng handler
u-boot.cfgout        dữ liệu config để handler parse
u-boot.bin           payload U-Boot thật
u-boot.imx           output cuối cùng cho Boot ROM đọc
```

---

## 9. imximage.c parse BOOT_FROM để lấy IVT offset và initial load size

Trong `imximage.cfg` có:

```txt
BOOT_FROM sd
```

Với eMMC, U-Boot/NXP vẫn dùng chung token `sd`, vì SD/eMMC đều thuộc nhóm SD/MMC/eSD/eMMC/SDXC trong RM.

Trong `tools/imximage.c`, nó xử lý ở:

```c
case CMD_BOOT_FROM:
	imximage_ivt_offset = get_table_entry_id(imximage_boot_offset,
				"imximage boot option", token);
	if (imximage_ivt_offset == -1) {
		fprintf(stderr, "Error: %s[%d] -Invalid boot device"
			"(%s)\n", name, lineno, token);
		exit(EXIT_FAILURE);
	}

	imximage_init_loadsize =
		get_table_entry_id(imximage_boot_loadsize,
				   "imximage boot option", token);

	if (imximage_init_loadsize == -1) {
		fprintf(stderr,
			"Error: %s[%d] -Invalid boot device(%s)\n",
			name, lineno, token);
		exit(EXIT_FAILURE);
	}
```

Với token:

```txt
sd
```

nó trả ra:

```txt
imximage_ivt_offset    = 0x400
imximage_init_loadsize = 0x1000
```

Ý nghĩa:

```txt
0x400  = IVT offset trong image
0x1000 = initial load region size = 4KB
```

Đây là giá trị NXP quy định trong RM cho SD/MMC/eMMC.

---

## 9. set_imx_hdr_v2 tạo IVT, Boot Data và con trỏ DCD

Sau khi parse cfg xong, `imximage_set_header()` sẽ gọi:

```c
(*set_imx_hdr)(imxhdr, dcd_len, params->ep, imximage_ivt_offset);
```

Vì image version là 2, `set_imx_hdr` trỏ tới:

```c
set_imx_hdr_v2()
```

Đoạn quan trọng:

```c
if (!hdr_v2->boot_data.plugin) {
	fhdr_v2->entry = entry_point;
	fhdr_v2->reserved1 = 0;
	fhdr_v2->reserved1 = 0;

	hdr_base = entry_point - imximage_init_loadsize +
		flash_offset;
	fhdr_v2->self = hdr_base;
	if (dcd_len > 0)
		fhdr_v2->dcd_ptr = hdr_base +
			offsetof(imx_header_v2_t, data);
	else
		fhdr_v2->dcd_ptr = 0;

	fhdr_v2->boot_data_ptr = hdr_base
			+ offsetof(imx_header_v2_t, boot_data);
	hdr_v2->boot_data.start = entry_point - imximage_init_loadsize;

	fhdr_v2->csf = 0;

	header_size_ptr = &hdr_v2->boot_data.size;
	csf_ptr = &fhdr_v2->csf;
}
```

Với board của em:

```txt
entry_point              = 0x87800000
imximage_init_loadsize   = 0x1000
flash_offset             = 0x400
```

Công thức tổng quát trong tool:

```txt
BootData.start = entry_point - imximage_init_loadsize

IVT.self / hdr_base = BootData.start + imximage_ivt_offset
                    = entry_point - imximage_init_loadsize + flash_offset
```

Trong đó:

```txt
entry_point             địa chỉ nhảy vào U-Boot, tức _start
imximage_init_loadsize  vùng initial load mà Boot ROM đọc trước
flash_offset            offset của IVT trong initial load region
BootData.start          địa chỉ bắt đầu image khi load vào DDR
hdr_base / IVT.self     địa chỉ runtime của IVT/header trong DDR
```

Tính ra:

```txt
boot_data.start = entry_point - imximage_init_loadsize
                = 0x87800000 - 0x1000
                = 0x877ff000

hdr_base        = entry_point - imximage_init_loadsize + flash_offset
                = 0x87800000 - 0x1000 + 0x400
                = 0x877ff400
```

Trong đó:

```txt
0x877ff000 = đầu image trong DDR sau khi Boot ROM load full image
0x877ff400 = IVT/header runtime address trong DDR
0x87800000 = entry/_start của U-Boot
```

Lưu ý: `boot_data.start` không phải địa chỉ trên eMMC. Nó là địa chỉ DDR mà Boot ROM sẽ load image vào sau khi DCD init DDR xong.

---

## 10. Linker script, start.S và IVT.entry liên quan như nào

Chỗ này phải tách rõ 2 thời điểm:

```txt
build-time  = lúc build U-Boot trên PC
runtime     = lúc board boot thật
```

File linker script của U-Boot ARM:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/arch/arm/cpu/u-boot.lds
```

Trong đó có:

```ld
ENTRY(_start)
```

`ENTRY(_start)` không phải lệnh chạy trên board. Nó là chỉ dẫn cho linker ở lúc build:

```txt
ELF entry symbol là _start
```

Symbol `_start` được định nghĩa trong:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/arch/arm/cpu/armv7/start.S
```

Luồng build:

```txt
start.S
        |
        | assembler
        v
start.o có symbol _start
        |
        v
linker dùng u-boot.lds
        |
        v
ENTRY(_start) chọn _start làm entry symbol của ELF
        |
        v
u-boot ELF
        |
        v
u-boot.bin
```

Boot ROM không hiểu tên `_start`. Boot ROM chỉ đọc địa chỉ số trong IVT:

```txt
IVT.entry = 0x87800000
```

Địa chỉ này được đưa vào IVT từ flow `mkimage`:

```txt
CONFIG_SYS_TEXT_BASE = 0x87800000
        |
        v
Makefile truyền -e 0x87800000 cho mkimage
        |
        v
mkimage: params->ep = 0x87800000
        |
        v
set_imx_hdr_v2(): fhdr_v2->entry = entry_point
        |
        v
IVT.entry = 0x87800000
```

Luồng runtime:

```txt
Boot ROM đọc IVT.entry
        |
        v
jump tới 0x87800000
        |
        v
code tại _start trong start.S bắt đầu chạy
```

Tóm lại:

```txt
u-boot.lds / ENTRY(_start)  dùng lúc build để linker biết entry symbol.
IVT.entry                  dùng lúc boot để Boot ROM biết địa chỉ nhảy vào.
_start                     là symbol trong start.S, không phải thứ Boot ROM đọc theo tên.
```

Hai bên phải khớp:

```txt
_start được link ở 0x87800000
IVT.entry cũng là 0x87800000
```

Nếu lệch, Boot ROM sẽ jump sai địa chỉ.

---

## 11. Boot Data size được tính như nào

Sau khi `header_size_ptr` trỏ tới:

```c
&hdr_v2->boot_data.size
```

`imximage_set_header()` gán:

```c
*header_size_ptr = ROUND((sbuf->st_size + imximage_ivt_offset), 4096);
```

Tức là size image được tính từ:

```txt
u-boot.bin size + IVT offset
```

rồi round lên bội số 4096.

Với image của em từng dump ra:

```txt
BootData.start = 0x877ff000
BootData.size  = 0x0008d000
```

Tức là Boot ROM sẽ load full image vào DDR:

```txt
0x877ff000 .. 0x8788c000
```

---

## 12. Layout của u-boot.imx

Nhìn tổng quan, `u-boot.imx` được pack theo dạng:

```txt
u-boot.imx
|
|-- padding trước IVT
|
|-- IVT / flash_header_v2_t
|     |-- header
|     |-- entry
|     |-- dcd_ptr --------+
|     |-- boot_data_ptr --|------+
|     |-- self            |      |
|     |-- csf             |      |
|                         |      |
|-- Boot Data <-----------+------+
|
|-- DCD table <-----------+
|
|-- padding cho đủ initial load size
|
|-- U-Boot code (_start)
```

Trong đó:

```txt
IVT / flash_header_v2_t
```

là cấu trúc chính mà Boot ROM đọc đầu tiên. Nó chứa `entry` và các con trỏ tới `Boot Data`, `DCD`, `CSF`.

```txt
Boot Data / boot_data_t
```

chứa địa chỉ bắt đầu image, size của image và cờ plugin.

```txt
DCD table / dcd_v2_t
```

chứa các lệnh `DATA 4 ...` để Boot ROM ghi register, ví dụ init DDR.

Theo offset trong file/image:

```txt
offset 0x0000  đầu image
offset 0x0400  IVT
offset 0x0420  Boot Data
offset 0x042c  DCD
offset 0x1000  U-Boot code / _start
```

Theo địa chỉ DDR runtime sau khi full image được load:

```txt
0x877ff000  đầu image / BootData.start
0x877ff400  IVT / header / self
0x877ff420  Boot Data
0x877ff42c  DCD
0x87800000  entry / _start
```

IVT field order:

```txt
0x877ff400  header        = 0x402000d1
0x877ff404  entry         = 0x87800000
0x877ff408  reserved1     = 0x00000000
0x877ff40c  dcd_ptr       = 0x877ff42c
0x877ff410  boot_data_ptr = 0x877ff420
0x877ff414  self          = 0x877ff400
0x877ff418  csf           = 0x00000000
0x877ff41c  reserved2     = 0x00000000
```

Boot Data:

```txt
0x877ff420  boot_data.start  = 0x877ff000
0x877ff424  boot_data.size   = 0x0008d000
0x877ff428  boot_data.plugin = 0x00000000
```

---

## 13. Boot ROM dùng các thông tin này như nào

Trước DCD, DDR chưa dùng được. Vì vậy Boot ROM không thể đọc trực tiếp các địa chỉ DDR như:

```txt
0x877ff400
0x877ff42c
0x87800000
```

Lúc đầu, với SD/eMMC, Boot ROM đọc initial region:

```txt
0x1000 bytes = 4KB
```

vào OCRAM/internal buffer.

Trong 4KB này:

```txt
offset 0x400 = IVT
offset 0x420 = Boot Data
offset 0x42c = DCD
```

Boot ROM có thể suy ra offset từ các địa chỉ runtime:

```txt
IVT offset      = self          - BootData.start = 0x877ff400 - 0x877ff000 = 0x400
BootData offset = boot_data_ptr - BootData.start = 0x877ff420 - 0x877ff000 = 0x420
DCD offset      = dcd_ptr       - BootData.start = 0x877ff42c - 0x877ff000 = 0x42c
Entry offset    = entry         - BootData.start = 0x87800000 - 0x877ff000 = 0x1000
```

Nên trước khi DDR sống:

```txt
dcd_ptr = 0x877ff42c
```

là địa chỉ runtime/DDR tương lai. Boot ROM dùng nó để suy ra:

```txt
DCD nằm tại offset 0x42c trong initial buffer OCRAM
```

Sau khi Boot ROM chạy DCD, DDR mới dùng được. Lúc đó Boot ROM load full image vào:

```txt
BootData.start = 0x877ff000
```

rồi jump vào:

```txt
entry = 0x87800000
```

---

## 14. Sau khi U-Boot chạy: bootcmd, mmcdev và boot.scr

Các phần trên là flow tạo `u-boot.imx` và flow Boot ROM load U-Boot.

Sau khi Boot ROM jump vào:

```txt
entry = 0x87800000
```

thì code U-Boot bắt đầu chạy từ `_start`, đi qua init CPU, init C runtime, `board_init_f()`, relocation, `board_init_r()`. Sau khi U-Boot init xong, nó mới chạy biến môi trường:

```txt
bootcmd
```

`bootcmd` là script chính quyết định U-Boot sẽ load kernel, DTB và rootfs như nào.

Với board của em, trong defconfig có:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/recipes-bsp/u-boot/files/okmx6ull_s_emmc_defconfig
```

Dòng:

```txt
CONFIG_BOOTCOMMAND="run findfdt;mmc dev ${mmcdev};mmc dev ${mmcdev}; if mmc rescan; then if run loadbootscript; then run bootscript; else if run loadimage; then run mmcboot; else run netboot; fi; fi; else run netboot; fi"
```

Khi build ra `.config`, dòng này nằm ở:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/build/okmx6ull_s_emmc_defconfig/.config
```

### 14.1. `mmcdev` là gì

`mmcdev` là biến môi trường default của U-Boot. Nó được hãng/board config sẵn trong:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/build-fb/tmp/work/okmx6ull_s_emmc-poky-linux-gnueabi/u-boot-imx/2022.04-r0/git/include/configs/mx6ullevk.h
```

Đoạn default env:

```c
"mmcdev="__stringify(CONFIG_SYS_MMC_ENV_DEV)"\0" \
"mmcpart=1\0" \
"mmcroot=" CONFIG_MMCROOT " rootwait rw\0" \
```

Và giá trị `CONFIG_SYS_MMC_ENV_DEV` là:

```c
#define CONFIG_SYS_MMC_ENV_DEV 1 /* USDHC2 */
```

Nên default:

```txt
mmcdev=1
```

Ý nghĩa:

```txt
mmcdev=1  chọn MMC device số 1, thường là eMMC/USDHC2 trên board này
mmcpart=1 chọn partition số 1, tức phân vùng /boot FAT
```

Nếu trên board đã từng `saveenv`, env lưu trong eMMC có thể override giá trị default này. Kiểm tra runtime bằng:

```bash
printenv mmcdev
printenv bootcmd
```

### 14.2. Vì sao cần `mmc dev ${mmcdev}`

Trong `bootcmd` có:

```bash
mmc dev ${mmcdev}
```

Nếu:

```txt
mmcdev=1
```

thì nó expand thành:

```bash
mmc dev 1
```

Lệnh này bảo U-Boot chọn thiết bị MMC/eMMC số 1 làm device đang active.

Ví dụ board có thể có:

```txt
mmc 0  SD card / USDHC1
mmc 1  eMMC    / USDHC2
```

Nếu không chọn đúng `mmc dev`, các lệnh sau có thể đọc nhầm thiết bị:

```bash
mmc rescan
fatload mmc ${mmcdev}:${mmcpart} ${loadaddr} boot.scr
fatload mmc ${mmcdev}:${mmcpart} ${loadaddr} zImage
fatload mmc ${mmcdev}:${mmcpart} ${fdt_addr} ${fdt_file}
```

Tóm lại:

```txt
mmcdev      biến lưu số device cần boot
mmc dev 1   chọn eMMC/USDHC2 làm device active
mmc rescan  quét lại device đó
fatload     đọc file từ partition của device đó
```

### 14.3. bootcmd chạy theo thứ tự nào

`bootcmd` của em:

```bash
run findfdt;
mmc dev ${mmcdev};
mmc dev ${mmcdev};
if mmc rescan; then
    if run loadbootscript; then
        run bootscript;
    else
        if run loadimage; then
            run mmcboot;
        else
            run netboot;
        fi;
    fi;
else
    run netboot;
fi
```

Vẽ ASCII:

```txt
bootcmd
 |
 |-- run findfdt
 |     `-- chọn tên file DTB, ví dụ imx6ull-14x14-evk.dtb
 |
 |-- mmc dev ${mmcdev}
 |     `-- chọn eMMC/SD device cần boot
 |
 |-- mmc rescan
 |     `-- quét lại device đó
 |
 |-- run loadbootscript
 |     `-- thử load boot.scr từ partition boot
 |
 |-- nếu có boot.scr:
 |       run bootscript
 |       `-- source boot.scr
 |           `-- chạy logic boot trong boot.scr
 |
 `-- nếu không có boot.scr:
         run loadimage
         `-- load zImage

         run mmcboot
         |-- run mmcargs
         |     `-- set bootargs cho kernel
         |
         |-- run loadfdt
         |     `-- load DTB
         |
         `-- bootz ${loadaddr} - ${fdt_addr}
             `-- jump vào Linux kernel
```

### 14.4. boot.scr liên quan gì với bootcmd

Trong default env có:

```c
"loadbootscript=" \
    "fatload mmc ${mmcdev}:${mmcpart} ${loadaddr} ${script};\0" \
"bootscript=echo Running bootscript from mmc ...; " \
    "source\0" \
```

Nếu:

```txt
mmcdev=1
mmcpart=1
script=boot.scr
```

thì:

```bash
run loadbootscript
```

sẽ tương đương:

```bash
fatload mmc 1:1 ${loadaddr} boot.scr
```

Nó tìm file `boot.scr` trong partition 1 của eMMC.

Nếu load được `boot.scr`, U-Boot chạy:

```bash
run bootscript
```

tức là:

```bash
source
```

`source` sẽ thực thi script vừa được load vào `${loadaddr}`.

Vì vậy:

```txt
bootcmd  là script chính nằm trong U-Boot env
boot.scr là script phụ nằm trên phân vùng /boot
```

Quan hệ:

```txt
bootcmd
 |
 |-- ưu tiên tìm boot.scr
 |
 |-- nếu có boot.scr:
 |       boot.scr quyết định load zImage nào, DTB nào, rootfs nào
 |
 `-- nếu không có boot.scr:
         U-Boot dùng logic default:
         load zImage + load DTB + bootz
```

### 14.5. Nếu không có boot.scr thì U-Boot load zImage và DTB như nào

Default env có:

```c
"loadimage=fatload mmc ${mmcdev}:${mmcpart} ${loadaddr} ${image}\0"
"loadfdt=fatload mmc ${mmcdev}:${mmcpart} ${fdt_addr} ${fdt_file}\0"
```

Nếu:

```txt
mmcdev=1
mmcpart=1
image=zImage
```

thì:

```bash
run loadimage
```

tương đương:

```bash
fatload mmc 1:1 ${loadaddr} zImage
```

Sau đó `mmcboot` chạy:

```bash
run mmcargs
run loadfdt
bootz ${loadaddr} - ${fdt_addr}
```

Trong đó:

```txt
mmcargs  set bootargs cho kernel
loadfdt  load file DTB vào RAM
bootz    nhảy vào kernel zImage
```

### 14.6. Liên hệ với file .wks

File partition layout của em:

```txt
/home/quanghaictu/learn_yocto/imx-yocto-imx6ull/meta-okmx6ull/wic/okmx6ull-forlinx.wks
```

Trong đó:

```wks
part /boot --source bootimg-partition --ondisk mmcblk --fstype=vfat --label BOOT --active --align 8192 --size 120

part / --source rootfs --ondisk mmcblk --fstype=ext4 --label rootfs_A --align 8192 --fixed-size 512M

part --source rootfs --ondisk mmcblk --fstype=ext4 --label rootfs_B --align 8192 --fixed-size 512M
```

Nghĩa là image eMMC có layout:

```txt
mmc 1:1  /boot     FAT   chứa boot.scr, zImage, DTB
mmc 1:2  rootfs_A  ext4  rootfs slot A
mmc 1:3  rootfs_B  ext4  rootfs slot B
```

Nên khi U-Boot chạy:

```bash
fatload mmc 1:1 ${loadaddr} boot.scr
fatload mmc 1:1 ${loadaddr} zImage
fatload mmc 1:1 ${fdt_addr} ${fdt_file}
```

nó đang đọc từ partition `/boot` trong `.wks`.

Còn rootfs kernel mount sau đó do `bootargs` quyết định, ví dụ:

```txt
root=/dev/mmcblk1p2
```

thì Linux mount rootfs slot A.

Nếu muốn boot slot B thì logic boot phải đổi thành:

```txt
root=/dev/mmcblk1p3
```

Thường phần đổi slot A/B nên để trong `boot.scr` hoặc logic OTA, vì `boot.scr` dễ thay đổi hơn so với rebuild U-Boot.

---

## 15. Tóm tắt cuối

Flow tạo `u-boot.imx`:

```txt
u-boot-imx_%.bbappend
        |
        v
copy okmx6ull_s_emmc_defconfig vào source U-Boot
patch board/freescale/mx6ullevk/imximage.cfg
        |
        v
defconfig bật CONFIG_TARGET_MX6ULL_14X14_EVK
        |
        v
board/freescale/mx6ullevk/Kconfig
        |
        v
CONFIG_IMX_CONFIG="board/freescale/mx6ullevk/imximage.cfg"
CONFIG_SYS_TEXT_BASE=0x87800000
        |
        v
arch/arm/mach-imx/Makefile
        |
        v
IMX_CONFIG = board/freescale/mx6ullevk/imximage.cfg
IMAGE_TYPE = imximage
        |
        v
tools/mkimage -n u-boot.cfgout -T imximage -e 0x87800000 -d u-boot.bin u-boot.imx
        |
        v
tools/imximage.c
        |
        v
u-boot.imx có IVT + BootData + DCD + U-Boot code
```

Flow Boot ROM đọc `u-boot.imx`:

```txt
Boot ROM đọc 4KB đầu từ eMMC vào OCRAM/internal buffer
        |
        v
tìm IVT tại offset 0x400
        |
        v
đọc Boot Data và DCD trong initial buffer
        |
        v
chạy DCD để init DDR
        |
        v
load full image vào DDR tại 0x877ff000
        |
        v
jump vào entry 0x87800000
        |
        v
U-Boot _start chạy
```
