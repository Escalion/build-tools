#!/bin/bash

set -x 
set -e

IMAGE_NAME="$1"
TARBALL="$2"
ROOTFS="$3"

if [ -z "$IMAGE_NAME" ] || [ -z "$TARBALL" ] || [ -z "$ROOTFS" ]; then
	echo "Usage: $0 <image name> <buildroot dir> <rootfs dir>"
	exit 1
fi

if [ "$(id -u)" -ne "0" ]; then
	echo "This script requires root."
	exit 1
fi

echo "Attaching loop device"
LOOP_DEVICE=$(losetup -f)
losetup -P $LOOP_DEVICE $IMAGE_NAME

echo "Creating filesystems"
mkfs.vfat ${LOOP_DEVICE}p1
mkswap ${LOOP_DEVICE}p2
mkfs.ext4 ${LOOP_DEVICE}p3

TEMP_ROOT=$(mktemp -d)
mkdir -p $TEMP_ROOT
echo "Mounting rootfs"
mount ${LOOP_DEVICE}p3 $TEMP_ROOT

echo "Copying rootfs"
cp -R "$ROOTFS/." "$TEMP_ROOT"
cp  "$TARBALL/output/build/linux-fa88f7f6bdb8854f887a1c942414fc4f870e5050/arch/arm64/boot/Image" "$TEMP_ROOT/boot"
cp "$TARBALL/output/build/linux-fa88f7f6bdb8854f887a1c942414fc4f870e5050/arch/arm64/boot/dts/allwinner/sun50i-a64-oceanic-5205-5inmfd.dtb" "$TEMP_ROOT/boot"
cp "$TARBALL/output/build/uboot-2019.01/u-boot-sunxi-with-spl.bin" "$TEMP_ROOT/boot"
echo "Installing bootloader"
dd if=$TEMP_ROOT/boot/u-boot-sunxi-with-spl.bin of=${LOOP_DEVICE} bs=8k seek=1

echo "Unmounting rootfs"
umount $TEMP_ROOT
rm -rf $TEMP_ROOT

# Detach loop device
losetup -d $LOOP_DEVICE
