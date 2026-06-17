# CÁCH FLASH FIRMWARE GO/C VÀO NOR

## 1. Flash firmware vào NOR bằng UUU

Sau khi build file go hoặc c, bạn đặt các file đó cùng cấp với uuu.exe (ví dụ: file `firmware`). Tạo file script `script_firmware.uuu`:

```bash
# vẫn như mọi khi nạp uboot lên Ram sử dụng serial download port.
SDP: boot -f u-boot-imx6ull14x14evk_sd.imx

# dùng uboot command để detect ra nor flash
FB[-t 15000]: ucmd sf probe

# erase vùng flash trước khi ghi (từ 0xA11000, độ dài 0x110000)
FB[-t 15000]: ucmd sf erase 0xA11000 0x110000

# set biến môi trường fastboot_buffer, chỉ định vùng 0x84000000 trên RAM làm buffer
FB[-t 15000]: ucmd setenv fastboot_buffer 0x84000000

# download file firmware từ laptop, lưu vào buffer trên RAM
FB[-t 15000]: download -f firmware

# ghi từ buffer RAM xuống NOR, bắt đầu từ địa chỉ 0xA11174
# ${fastboot_bytes} là biến tự động chứa kích thước file đã download
FB[-t 15000]: ucmd sf write 0x84000000 0xA11174 ${fastboot_bytes}

FB: done
```

**Giải thích quy trình:**

1. **`setenv fastboot_buffer 0x84000000`**: Thiết lập buffer RAM tại địa chỉ `0x84000000`
2. **`download -f firmware`**: Tải file `firmware` từ laptop → RAM `0x84000000`
3. **`sf write 0x84000000 0xA11174 ${fastboot_bytes}`**: Ghi từ RAM → NOR flash tại offset `0xA11174`

---

## 2. Đọc firmware từ NOR trên tầng application

Ý tưởng: đọc từ MTD (memory technology device) → RAM, sau đó CPU có thể thực thi file firmware đó.

```c
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

/* 
 * Các define constants 
 */
#define FIRMWARE_OFFSET    0xA11174  // offset trên NOR flash cần đọc
#define FIRMWARE_SIZE      1111124   // size của firmware file
#define NOR_DEVICE         "/dev/mtd0"       // device file đại diện cho NOR flash
#define FIRMWARE_TMPFILE   "/tmp/firmware_loaded"  // file tạm trên RAM

/*
 * Hàm đọc firmware từ NOR flash lên buffer RAM
 * Quy trình:
 *   1. open(NOR_DEVICE, O_RDONLY) - mở device file NOR flash
 *   2. lseek() - di chuyển đến offset FIRMWARE_OFFSET
 *   3. read() - đọc FIRMWARE_SIZE bytes vào buf
 */
static int read_firmware_from_nor(unsigned char *buf, size_t buf_size) {
    int fd;
    ssize_t nread;
    
    if (buf_size < FIRMWARE_SIZE) {
        fprintf(stderr, "Error: Buffer too small. Need %d bytes, have %zu\n", 
                FIRMWARE_SIZE, buf_size);
        return -1;
    }
    
    fd = open(NOR_DEVICE, O_RDONLY);
    if (fd < 0) {
        fprintf(stderr, "Error: Cannot open %s: %s\n", NOR_DEVICE, strerror(errno));
        return -1;
    }
    
    if (lseek(fd, FIRMWARE_OFFSET, SEEK_SET) == (off_t)-1) {
        fprintf(stderr, "Error: lseek to 0x%x failed: %s\n", 
                FIRMWARE_OFFSET, strerror(errno));
        close(fd);
        return -1;
    }
    
    nread = read(fd, buf, FIRMWARE_SIZE);
    if (nread != FIRMWARE_SIZE) {
        fprintf(stderr, "Error: Read failed. Got %zd bytes, expected %d\n", 
                nread, FIRMWARE_SIZE);
        close(fd);
        return -1;
    }

    close(fd);
    return 0;
}

/*
 * Hàm ghi firmware từ buffer vào file tạm /tmp/firmware_loaded
 * Mục đích: tạo file thực thi được (executable) để chạy firmware
 */
static int write_firmware_to_tmp(const unsigned char *buf) {
    int fd;
    
    // Mở/tạo file với quyền rwx-r-xr-x (0755)
    fd = open(FIRMWARE_TMPFILE, O_WRONLY | O_CREAT | O_TRUNC, 0755);
    if (fd < 0) {
        fprintf(stderr, "Error: Cannot create %s: %s\n", 
                FIRMWARE_TMPFILE, strerror(errno));
        return -1;
    }
    
    if (write(fd, buf, FIRMWARE_SIZE) != FIRMWARE_SIZE) {
        fprintf(stderr, "Error: Write to %s failed: %s\n", 
                FIRMWARE_TMPFILE, strerror(errno));
        close(fd);
        return -1;
    }
    
    close(fd);
    return 0;
}

/*
 * Kiểm tra xem buffer có phải là file ELF hợp lệ không
 * ELF magic number: 0x7F 'E' 'L' 'F' ở 4 byte đầu
 */
static void check_elf_magic(const unsigned char *buf) {
    if (buf[0] == 0x7f && buf[1] == 'E' && buf[2] == 'L' && buf[3] == 'F') {
        printf("✓ Firmware is valid ELF file\n");
        unsigned char elf_class = buf[4];
        unsigned char elf_data = buf[5];
        unsigned int entry = *(unsigned int*)(buf + 8);
        printf("  ELF Class: %s-bit\n", elf_class == 1 ? "32" : "64");
        printf("  Endianness: %s\n", elf_data == 1 ? "Little-endian" : "Big-endian");
        printf("  Entry point: 0x%x\n", entry);
    } else {
        printf("⚠ Warning: No ELF magic at start!\n");
        printf("  First bytes: ");
        for (int i = 0; i < 16 && i < FIRMWARE_SIZE; i++) {
            printf("%02x ", buf[i]);
        }
        printf("\n");
    }
}

/*
 * Main function - quy trình load và chạy firmware từ NOR:
 *   1. Đọc firmware từ NOR flash (offset 0xA11174) lên RAM buffer
 *   2. Validate ELF header
 *   3. Ghi buffer ra file tạm /tmp/firmware_loaded
 *   4. Chạy file tạm bằng execl()
 */
int main() {
    unsigned char *firmware_buf;
    
    printf("=== Firmware Loader from NOR ===\n");
    printf("NOR device: %s\n", NOR_DEVICE);
    printf("Firmware offset: 0x%x\n", FIRMWARE_OFFSET);
    printf("Firmware size: %d bytes\n\n", FIRMWARE_SIZE);

    // Kiểm tra quyền root (cần để đọc /dev/mtd0)
    if (geteuid() != 0) {
        fprintf(stderr, "Error: This program needs root privileges\n");
        fprintf(stderr, "Please run with sudo\n");
        return 1;
    }

    // Cấp phát buffer cho firmware
    firmware_buf = malloc(FIRMWARE_SIZE);
    if (!firmware_buf) {
        fprintf(stderr, "Error: Out of memory\n");
        return 1;
    }

    // Step 1: Đọc từ NOR flash
    printf("Step 1: Reading firmware from NOR...\n");
    if (read_firmware_from_nor(firmware_buf, FIRMWARE_SIZE) != 0) {
        free(firmware_buf);
        return 1;
    }
    printf("✓ Read %d bytes from NOR\n\n", FIRMWARE_SIZE);

    // Step 1.5: Validate ELF header
    check_elf_magic(firmware_buf);
    printf("\n");

    // Step 2: Ghi ra file tạm
    printf("Step 2: Writing firmware to %s...\n", FIRMWARE_TMPFILE);
    if (write_firmware_to_tmp(firmware_buf) != 0) {
        free(firmware_buf);
        return 1;
    }
    printf("✓ Written to %s\n\n", FIRMWARE_TMPFILE);

    // Step 3: Thực thi firmware
    printf("Step 3: Executing firmware...\n");
    printf("----------------------------------------\n");
    
    free(firmware_buf);

    // Thay thế process hiện tại bằng firmware
    execl(FIRMWARE_TMPFILE, "firmware", NULL);

    // Nếu execl() trả về -> lỗi
    fprintf(stderr, "Error: execl failed: %s\n", strerror(errno));
    return 1;
}
```