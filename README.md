# acer-spin7-linux
The purpose of this repo is to have a reproducible linux build that can boot Linux on the Acer Spin 7.

# Observations

- booting into the kernel works and we get to a login
- own keyboard does not work (plugging an external keyboard works)
- WIFI ??
- Modem ??
- Touchpad ??

# Getting aarch64-laptops kernel branch

Clone the kernel into the `aarch64-linux` folder.

```
git clone https://github.com/aarch64-laptops/linux.git aarch64-linux
cd aarch64-linux
git checkout laptops-5.15
```

# Building the kernel

Enable buildkit for better caching if you want or use the `DOCKER_BUILDKIT` env variable.

Build the kernel and tar the Image, it will be used later:

```
docker build -f Dockerfile.kernel . -o - > kernelImage.tar
```

# Booting the kernel

First make sure that your device is up-to-date in Windows. Then go into firmware settings (bios) and disable secure boot. In order to disable secure boot, you will have to create a password first, then it will allow you to disable secure boot.
Also make sure you disable the fn keys, it will help you to select the bootloader later by pressing F12 when the laptop starts.

## Working Grub

Build a working aarch64 efi file first:

```
docker buildx build --platform linux/arm64 -f Dockerfile.grub -t grub -o type=local,dest=/tmp/grub-output/EFI/BOOT .
```

This is a multiarch build, so refer to the Docker documentation regarding it in case of problems.

## Working EFI Shell (Optional)

If you want to be able to drop to an EFI shell, grab the `debian-cdimage` repo and the scripts will take it from there:

```
git clone https://github.com/aarch64-laptops/debian-cdimage.git
```

## Making an external disk bootable with the custom grub and kernel

The script `grubInstall.sh` assumes the external disk is located at /dev/sda.
Modify the `DISK` variable inside to point it somewhere else.
It needs to be run by root since it takes care of mounting and formatting the external device.

After modifying the `DISK` variable to point to the right device:

```
# only required for an unformatted disk (first-time)
./grubInstall.sh --format

# afterwards, no need for formatting simply copying will suffice
./grubInstall.sh
```

This will format and structure the external disk into one ESP partition and one Linux partition.
It will then copy the grub and custom kernel files.

You can now connect the external disk to the laptop and boot from it.
Selecting the `Kernel Boot with DTB` option will get you furthest.


# Build debian image

docker buildx build --platform linux/arm64 -f Dockerfile.arm -t debianarm -o type=local,dest=images .
