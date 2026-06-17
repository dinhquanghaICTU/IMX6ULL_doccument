# CÁC BƯỚC SETUP MÔI TRƯỜNG CHO MÁY HOST

Tham khảo của forlinx:
https://docs.forlinx.net/nxp/okmx6ull-c/OKMX6ULL-C_Linux4_1_15_User_Compilation_Manual.html#loading-the-existing-ubuntu-development-environment

---

## 1.1 Cài đặt SDK

- Đầu tiên muốn tải được thực thi được files script này phải tải xuống từ:
  https://onedrive.live.com/?redeem=aHR0cHM6Ly8xZHJ2Lm1zL2YvYy80ZTdjYWNlYmNmYWJjMmUwL0Vxa3hoWjVrdUxaS3NybENlOWhsVUFBQkhfUnB1YnRncmROb2tJdkRCX1pYSGc%5FZT1GTkxyRFA&id=4E7CACEBCFABC2E0%21s9e8531a9b8644ab6b2b9427bd8655000&cid=4E7CACEBCFABC2E0

  `(OKMX6ULL-C&FETMX6ULL-C/OKMX6ULL-C_Qt5.6+Linux4.1.15_R2/Linux/Testing demo/qt5.6.rar)`

- Giải nén ra ta sẽ có files script này:

```bash
./fsl-imx-x11-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-toolchain-4.1.15-2.0.0.sh
```

- Lệnh này để cài toolchain build cho dòng `cortexa7hf`
- Cài thư viện C chuẩn `glibc` và `Qt5`
- `fsl-imx` là target tới hãng sản xuất
- BSP version support `2.0.0`
- Linux kernel version `4.1.15`

---

## 1.2 Cài đặt biến môi trường

> ⚠️ Mỗi lần muốn biên dịch phải dán lại lệnh này — nó chỉ có hiệu lực tại terminal đang dùng

```bash
. /opt/fsl-imx-x11/4.1.15-2.0.0/environment-setup-cortexa7hf-neon-poky-linux-gnueabi
```

Nó sẽ tự động thêm các biến môi trường này vào để biên dịch chương trình cho ARM:

```bash
export CC=arm-poky-linux-gnueabi-gcc        # C compiler
export CXX=arm-poky-linux-gnueabi-g++       # C++ compiler
export LD=arm-poky-linux-gnueabi-ld         # Linker
export AR=arm-poky-linux-gnueabi-ar         # Archiver
export CROSS_COMPILE=arm-poky-linux-gnueabi-
export ARCH=arm
export PATH=/opt/fsl-imx-x11/4.1.15-2.0.0/sysroots/x86_64.../bin:$PATH
```

---

## 1.3 Biên dịch kernel

- Cần phải tải `linux-4.1.15.tar.bz2`:
  https://onedrive.live.com/?redeem=aHR0cHM6Ly8xZHJ2Lm1zL2YvYy80ZTdjYWNlYmNmYWJjMmUwL0Vxa3hoWjVrdUxaS3NybENlOWhsVUFBQkhfUnB1YnRncmROb2tJdkRCX1pYSGc%5FZT1GTkxyRFA&id=4E7CACEBCFABC2E0%21s9e8531a9b8644ab6b2b9427bd8655000&cid=4E7CACEBCFABC2E0

  `(OKMX6ULL-C&FETMX6ULL-C/OKMX6ULL-C_Qt5.6+Linux4.1.15_R2/Linux/Source code)`

- Sau đó chuyển sang sudo để có quyền truy cập đầy đủ files hệ thống:

```bash
sudo su
```

- Tiếp theo giải nén kernel source:

```bash
tar xvf linux-4.1.15.tar.bz2
```

- Sau đó chuyển đến thư mục đó để chuẩn bị build để phù hợp với kiến trúc ARM:

```bash
cd linux-4.1.15
```

- Đặt lại biến môi trường để build:

```bash
. /opt/fsl-imx-x11/4.1.15-2.0.0/environment-setup-cortexa7hf-neon-poky-linux-gnueabi
```

- Bây giờ là đến phần build:

```bash
./imx6ull_c_build.sh
```

> 💡 Nói chung đoạn này script của forlinx làm hết rồi chỉ việc cầm vào compile

---

## 1.4 Compile cho C → ARM

- Tạo ra file C, ví dụ `hello.c`:

```bash
$CC hello.c -o hello
```

- Kiểm tra:

```bash
file hello
```

- Nó hiện như này là thành công:

```
ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV),
dynamically linked, interpreter
/lib/ld-linux-armhf.so.3, for GNU/Linux 2.6.32,
BuildID[sha1]=400fbba6005ea8e7344df7080ab10d9ef54e3a45, not stripped
```

---

## 1.5 Compile cho Golang

- Cài golang cho máy host:

```bash
sudo apt install golang-go
```

- Tạo file golang và compile, ví dụ `test_golang.go`:

```bash
GOOS=linux GOARCH=arm GOARM=7 go build -o firmware test_golang.go
```

- Kiểm tra:

```bash
file firmware
```

- Kết quả như này là thành công:

```
ELF 32-bit LSB executable, ARM
```