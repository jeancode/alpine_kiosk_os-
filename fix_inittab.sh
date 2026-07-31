#!/bin/bash
set -e
mount -o loop out/alpine_rootfs.ext4 /mnt/alpine_root
sed -i 's|tty1::respawn:/bin/sh|tty1::respawn:/sbin/getty 38400 tty1|' /mnt/alpine_root/etc/inittab
umount -l /mnt/alpine_root
