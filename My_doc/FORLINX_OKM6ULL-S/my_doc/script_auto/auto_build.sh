#!/bin/bash

echo "===== SCRIPT BUILD LINUX KERNEL FOR OKM6ULL-S ====="

USER=forlinx


cd /home/$USER/

mkdir -p work

cd /home/$USER/work

wget https://github.com/dinhquanghaICTU/IMX6ULL_doccument/releases/download/v1.0/linux-4.1.15.tar.bz2
wget https://github.com/dinhquanghaICTU/IMX6ULL_doccument/releases/download/v1.0/fsl-imx-x11-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-toolchain-4.1.15-2.0.0.sh

cd /home/$USER/work
tar xvf linux-4.1.15.tar.bz2 



chmod +x fsl-imx-x11-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-toolchain-4.1.15-2.0.0.sh

sudo ./fsl-imx-x11-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-toolchain-4.1.15-2.0.0.sh -d /opt/fsl-imx-x11/4.1.15-2.0.0 -y

source /opt/fsl-imx-x11/4.1.15-2.0.0/environment-setup-cortexa7hf-neon-poky-linux-gnueabi


cd /home/$USER/work

chmod +x imx6ull_build.sh

./imx6ull_build.sh

echo "=================OKE CAI MOI TRUONG XONG========================="
cd ..
chmod +x auto_config.sh
./auto_config.sh
echo "=================chuyen sang config va build kernel=============="
