#!/bin/bash
set -e

WINDOWS_DIR="/mnt/c/Users/jean/.gemini/antigravity/scratch/kiosk"
cd $WINDOWS_DIR

# Limpiar montajes previos si quedaron atascados
umount -l /mnt/alpine_root/dev 2>/dev/null || true
umount -l /mnt/alpine_root/sys 2>/dev/null || true
umount -l /mnt/alpine_root/proc 2>/dev/null || true
umount -l /mnt/alpine_root 2>/dev/null || true

echo "2. Creando disco Alpine de 1500MB (1.5GB)..."
rm -f out/alpine_rootfs.ext4
dd if=/dev/zero of=out/alpine_rootfs.ext4 bs=1M count=1500
mkfs.ext4 out/alpine_rootfs.ext4

echo "3. Montando disco..."
mkdir -p /mnt/alpine_root
mount -o loop out/alpine_rootfs.ext4 /mnt/alpine_root

echo "4. Descargando Alpine Linux..."
wget -q -O alpine.tar.gz https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-minirootfs-3.19.1-x86_64.tar.gz
tar xzf alpine.tar.gz -C /mnt/alpine_root
rm alpine.tar.gz

echo "5. Configurando DNS para chroot..."
cp /etc/resolv.conf /mnt/alpine_root/etc/resolv.conf

echo "6. Instalando compilador y librerias (g++, sdl2) desde chroot..."
mount -t proc none /mnt/alpine_root/proc
mount -t sysfs none /mnt/alpine_root/sys
mount -o bind /dev /mnt/alpine_root/dev

chroot /mnt/alpine_root /bin/sh -c "
apk update
apk add build-base sdl2-dev sdl2_ttf-dev eudev iproute2 openrc dhcpcd
"

echo "7. Configurando autologin y red..."
chroot /mnt/alpine_root /bin/sh -c "
rc-update add devfs sysinit
rc-update add dmesg sysinit
rc-update add mdev sysinit
rc-update add hwdrivers sysinit
rc-update add modules boot
rc-update add sysctl boot
rc-update add hostname boot
rc-update add bootmisc boot
rc-update add syslog boot
rc-update add dhcpcd boot
"

chroot /mnt/alpine_root /bin/sh -c "passwd -d root"
sed -i 's/tty1::respawn:\/sbin\/getty 38400 tty1/tty1::respawn:\/bin\/login -f root/' /mnt/alpine_root/etc/inittab

rm -f /mnt/alpine_root/etc/resolv.conf
echo "nameserver 8.8.8.8" > /mnt/alpine_root/etc/resolv.conf

# Mover el archivo fuente del kiosko al root del nuevo sistema para que el usuario pueda compilarlo
cp kiosk.cpp /mnt/alpine_root/root/

echo "8. Desmontando el sistema de archivos..."
umount /mnt/alpine_root/dev
umount /mnt/alpine_root/sys
umount /mnt/alpine_root/proc
umount /mnt/alpine_root

echo "¡Disco Alpine terminado!"
