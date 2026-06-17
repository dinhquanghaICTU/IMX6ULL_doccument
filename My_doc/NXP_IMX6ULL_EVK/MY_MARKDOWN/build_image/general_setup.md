
                CÁCH ĐỂ BUILD IMAGE CHO IMX6UL

---

I. CÁC KIỂU BUILD IMAGE CHO IMX6UL

    - Có hai kiểu build:

        + Build trên sources của openembedded (https://github.com/openembedded/)
        + Build trên sources sẵn của NXP  (em chọn cách này theo tài liệu của NXP sửa dụng src https://github.com/nxp-imx/imx-manifest)

    1. Lý do chọn src của NXP:

        - Lý do em chọn đi theo cách này là vì:

        * Ưu điểm:
            + Vì chip của NXP họ đã test và validate có ngay môi trường hoạt động được
            + Đỡ tốn time build lại từ đầu
            + Ổn định vì hàng ngày hãng đều test trên src này
            + Được hỗ trợ

        * Nhược điểm:
            + Bị giới hạn phụ thuộc vào version của hãng, nếu muốn dùng kernel mới hơn phải chờ hãng xây.

    2. Các bước build:
        - Phần này em xem tài liệu của hãng chapter 4 (/i.MX_Yocto_Project_User's_Guide/i.MX_6UL_Yocto_Project_Setup)

---

B1: CÀI REPO TOOL (CHỈ CẦN LÀM 1 LẦN)

    - Lý do khi cần cài tool này: nếu làm thủ công git clone phải gõ từng lệnh:

        git clone meta-imx
        git clone meta-freescale
        git clone poky
        git clone meta-openembedded

    - Tool repo sẽ hỗ trợ clone nhanh, nó đọc xml:

        repo init ...   # đọc file manifest XML
        repo sync       # tự clone tất cả 20+ repo về đúng version

    


    mkdir ~/bin
    curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
    chmod a+x ~/bin/repo
    PATH=${PATH}:~/bin

---

B2: TẠO THƯ MỤC LÀM VIỆC VÀ DOWNLOAD SRC

    mkdir imx-yocto-bsp
    cd imx-yocto-bsp
    repo init -u https://github.com/nxp-imx/imx-manifest \
        -b imx-linux-whinlatter \
        -m imx-6.18.2-1.0.0.xml
    repo sync

    (-b imx-linux-whinlatter \  : là nhánh chứa yocto 5.3
    -m imx-6.18.2-1.0.0.xml : là phiên bản linux kernel)

---

B3: CÀI CÁC GÓI PHỤ THUỘC

    - Phần này em xem tài liệu của hãng chapter 3 (/i.MX_Yocto_Project_User's_Guide/i.MX_6UL_Host_Setup.md)

    sudo apt-get install \
        build-essential chrpath cpio debianutils diffstat file gawk gcc git \
        iputils-ping libacl1 liblz4-tool locales python3 python3-git \
        python3-jinja2 python3-pexpect python3-pip python3-subunit socat \
        texinfo unzip wget xz-utils zstd efitools

---

B4: SETUP BACKEND CHO i.MX 6UL

    - Chính là config cho thư mục cần build những gì và chip mình dùng
    - Ở đây em chọn config như này, nó sẽ ghi vào local.conf:

        MACHINE = "imx6ull14x14evk "
        DISTRO = "fsl-imx-fb"   -> Ưu điểm: thích hợp với IMX6UL vì dùng Frame Buffer, giúp hiệu năng tốt, đơn giản, RAM ít, build image nhỏ, không dùng display server
        ACCEPT_FSL_EULA = "1"

    Lệnh setup:

        DISTRO=fsl-imx-fb MACHINE=imx6ull14x14evk source imx-setup-release.sh -b build-fb



-> Tại vì mình sử dụng dual boot 
    - nó chỉ khác nhau mỗi uboot thôi nên em phải chỉnh lại ở đây để nó build ra uboot cho qspi1

    + nên ta phải config build Uboot cho Nor flash 
        echo "UBOOT_CONFIG = \"qspi1\"" >> conf/local.conf
        bitbake core-image-base

    Khi build song ta sẽ có các:
    file -> nor
        u-boot-imx6ull14x14evk_qspi1.imx
        zImage-imx6ul7d.bin
        imx6ull-14x14-evk.dtb

    file -> sdcard
        imx-image-base-imx6ul7d.wic


=>> ta sẽ tiến hành quá trình partion sdcard và flash nor
(xem tiếp ở uuu_flash/uuu_flash.md)



   
       



    