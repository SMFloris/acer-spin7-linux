#!/bin/bash

rm -rf /tmp/grub-output/EFI/BOOT
mkdir -p /tmp/grub-output/EFI/BOOT
docker buildx build --platform linux/arm64 -f Dockerfile.grub -t grub -o type=local,dest=/tmp/grub-output/EFI/BOOT .

DISK=/dev/sda

umount ${DISK}1
umount ${DISK}2

mkdir -p /boot/mine
MOUNTPATH=/boot/mine
EFIPATH=${MOUNTPATH}/efi
EXTPATH=${MOUNTPATH}/ext4

rm -rf $EFIPATH
rm -rf $EXTPATH

# Inspired by:
# http://ninux.org/Hybrid_UEFI_MBR_USB_Drive
set -e

if [[ "$1" == "--format" ]]; then
    sgdisk --zap-all $DISK
    sgdisk -n 0:0:+500MiB -t 0:0700 -c 0:EFI $DISK
    sgdisk -n 0:0:0 -t 0:8300 -c 0:DATA $DISK

    partprobe

    mkfs.fat -F32 ${DISK}1
    sudo mkfs.ext4 ${DISK}2
fi


mkdir -p $EFIPATH
mkdir -p $EXTPATH

mount ${DISK}1 $EFIPATH
mount ${DISK}2 $EXTPATH

UUID=$(blkid ${DISK}2 | grep -P ' UUID=\S+' | cut -d '"' -f 2)

mkdir -p  ${EFIPATH}/EFI/BOOT/
cp /tmp/grub-output/EFI/BOOT/bootaa64.efi  ${EFIPATH}/EFI/BOOT/BOOTAA64.efi

cp grub/grub.cfg /tmp/grub.cfg
sed -i "s/MYUUID/${UUID}/" /tmp/grub.cfg

mkdir -p ${EFIPATH}/kernel
cp grub/rootfs.cpio.gz ${EFIPATH}/kernel/rootfs.cpio.gz

mkdir -p /tmp/kernel
cp kernelImage.tar /tmp/kernel

pushd /tmp/kernel

tar -xf kernelImage.tar
cp Image ${EFIPATH}/kernel/Image

mkdir -p ${EFIPATH}/kernel/dtbs
cp dts/qcom/sc8180x-lenovo-flex-5g* ${EFIPATH}/kernel/dtbs/

popd

SHELLFILE=./debian-cdimage/simple-cdd/misc/Shell.efi
if test -f "$SHELLFILE"; then
    cp ${SHELLFILE} ${EFIPATH}/kernel/Shell.efi
fi

cp /tmp/grub.cfg ${EFIPATH}/EFI/BOOT/grub.cfg

umount ${DISK}1
umount ${DISK}2
