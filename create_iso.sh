#!/bin/sh

. ./env.sh

set -ex

cd busybox-$BUSYBOX_VERSION
make distclean defconfig
sed -i "s/.*CONFIG_STATIC.*/CONFIG_STATIC=y/" .config
make busybox install
cd _install
rm -f linuxrc
mkdir dev proc sys
echo '#!/bin/sh' > init
echo 'dmesg -n 1' >> init
echo 'mount -t devtmpfs none /dev' >> init
echo 'mount -t proc none /proc' >> init
echo 'mount -t sysfs none /sys' >> init
echo 'setsid cttyhack /bin/sh' >> init
chmod +x init
find . | cpio -R root:root -H newc -o | gzip > ../../isoimage/rootfs.gz

cd ../../linux-$KERNEL_VERSION
make mrproper defconfig bzImage
cp arch/x86/boot/bzImage ../isoimage/kernel.gz
cd ../isoimage
cp ../syslinux-$SYSLINUX_VERSION/bios/core/isolinux.bin .
cp ../syslinux-$SYSLINUX_VERSION/bios/com32/elflink/ldlinux/ldlinux.c32 .
echo 'default kernel.gz initrd=rootfs.gz' > ./isolinux.cfg

xorriso \
  -as mkisofs \
  -o ../linux.iso \
  -b isolinux.bin \
  -c boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  ./
cd ..
set +ex

echo "created iso image"
