#!/usr/bin/env bash

set -Eeuo pipefail

# =========================================================
# AUTO SETUP + BUILD OKM6ULL-S
# =========================================================

CURRENT_USER="$(whoami)"
HOME_DIR="$HOME"

WORK_DIR="$HOME_DIR/work"
KERNEL_ARCHIVE="linux-4.1.15.tar.bz2"
TOOLCHAIN_SH="fsl-imx-x11-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-toolchain-4.1.15-2.0.0.sh"

KERNEL_URL="https://github.com/dinhquanghaICTU/IMX6ULL_doccument/releases/download/v1.0/linux-4.1.15.tar.bz2"

TOOLCHAIN_URL="https://github.com/dinhquanghaICTU/IMX6ULL_doccument/releases/download/v1.0/fsl-imx-x11-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-toolchain-4.1.15-2.0.0.sh"

TOOLCHAIN_DIR="/opt/fsl-imx-x11/4.1.15-2.0.0"

# =========================================================
# COLORS
# =========================================================

GREEN='\033[1;32m'
BLUE='\033[1;34m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# =========================================================
# LOG FUNCTIONS
# =========================================================

log_step() {
    echo
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================================${NC}"
}

log_ok() {
    echo -e "${GREEN}[OK] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

log_err() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# =========================================================
# START
# =========================================================

clear

echo -e "${GREEN}"
echo "======================================================="
echo "        OKM6ULL-S AUTO BUILD ENVIRONMENT"
echo "======================================================="
echo -e "${NC}"

echo "User        : $CURRENT_USER"
echo "Home        : $HOME_DIR"
echo "Work dir    : $WORK_DIR"

# =========================================================
# INSTALL REQUIRED PACKAGES
# =========================================================

log_step "INSTALL REQUIRED PACKAGES"

sudo apt update

sudo apt install -y \
    wget \
    tar \
    bzip2 \
    xz-utils \
    build-essential \
    libncurses5-dev \
    libncursesw5-dev \
    lzop \
    bc \
    u-boot-tools \
    fakeroot \
    parted \
    dosfstools \
    e2fsprogs

log_ok "Packages installed"

# =========================================================
# CREATE WORKSPACE
# =========================================================

log_step "CREATE WORKSPACE"

mkdir -p "$WORK_DIR"

cd "$WORK_DIR"

log_ok "Workspace ready"

# =========================================================
# DOWNLOAD FILES
# =========================================================

log_step "DOWNLOAD KERNEL + TOOLCHAIN"

if [ ! -f "$KERNEL_ARCHIVE" ]; then
    wget -O "$KERNEL_ARCHIVE" "$KERNEL_URL"
else
    log_warn "$KERNEL_ARCHIVE already exists"
fi

if [ ! -f "$TOOLCHAIN_SH" ]; then
    wget -O "$TOOLCHAIN_SH" "$TOOLCHAIN_URL"
else
    log_warn "$TOOLCHAIN_SH already exists"
fi

log_ok "Download completed"

# =========================================================
# EXTRACT KERNEL
# =========================================================

log_step "EXTRACT KERNEL"

if [ ! -d "$WORK_DIR/linux-4.1.15" ]; then
    tar xvf "$KERNEL_ARCHIVE"
else
    log_warn "Kernel source already extracted"
fi

log_ok "Kernel source ready"

# =========================================================
# INSTALL TOOLCHAIN
# =========================================================

log_step "INSTALL TOOLCHAIN"

chmod +x "$TOOLCHAIN_SH"

if [ ! -d "$TOOLCHAIN_DIR" ]; then

    sudo ./"$TOOLCHAIN_SH" \
        -d "$TOOLCHAIN_DIR" \
        -y

    log_ok "Toolchain installed"

else
    log_warn "Toolchain already installed"
fi

# =========================================================
# LOAD TOOLCHAIN
# =========================================================

log_step "LOAD TOOLCHAIN"

export CCACHE_PATH=""

source "$TOOLCHAIN_DIR/environment-setup-cortexa7hf-neon-poky-linux-gnueabi"

log_ok "Toolchain loaded"

echo
echo "CC = $CC"

# =========================================================
# BUILD SCRIPT
# =========================================================

log_step "RUN BUILD SCRIPT"

cd "$WORK_DIR"

if [ ! -f "imx6ull_build.sh" ]; then
    log_err "imx6ull_build.sh not found"
    exit 1
fi

chmod +x imx6ull_build.sh

./imx6ull_build.sh

log_ok "Build script completed"

# =========================================================
# AUTO CONFIG
# =========================================================
set +e

wget --no-check-certificate --tries=3 --timeout=15 -q -O auto_config.sh "$AUTO_CONFIG_URL"
WGET_STATUS=$?

if [ $WGET_STATUS -ne 0 ] || [ ! -s auto_config.sh ]; then
    log_warn "wget failed (code=$WGET_STATUS), trying curl..."
    curl -fsSL --retry 3 --connect-timeout 15 -o auto_config.sh "$AUTO_CONFIG_URL"
    CURL_STATUS=$?
    if [ $CURL_STATUS -ne 0 ] || [ ! -s auto_config.sh ]; then
        log_warn "Failed to download auto_config.sh -> skipped"
    else
        log_ok "Downloaded via curl"
        chmod +x auto_config.sh
        source ./auto_config.sh   # <-- dùng source
    fi
else
    log_ok "Downloaded auto_config.sh successfully"
    chmod +x auto_config.sh
    source ./auto_config.sh       # <-- dùng source
fi

set -e
# =========================================================
# DONE
# =========================================================

echo
echo -e "${GREEN}"
echo "======================================================="
echo "               BUILD ENVIRONMENT READY"
echo "======================================================="
echo -e "${NC}"

echo "Kernel source : $WORK_DIR/linux-4.1.15"
echo "Toolchain     : $TOOLCHAIN_DIR"
