FROM docker.io/library/fedora:rawhide

RUN dnf -y --refresh update && \
    dnf -y install \
        mkosi \
        systemd-udev \
        systemd-boot-unsigned \
        systemd-ukify \
        dosfstools \
        mtools \
        e2fsprogs \
        btrfs-progs \
        xz \
        zstd \
        squashfs-tools \
        erofs-utils \
        qemu-img \
    && dnf clean all