#!/bin/bash
set -e
mount -o loop out/alpine_rootfs.ext4 /mnt/alpine_root
sed -i 's/^PermitEmptyPasswords yes/PermitEmptyPasswords no/' /mnt/alpine_root/etc/ssh/sshd_config
chroot /mnt/alpine_root /bin/sh -c 'echo "root:admin" | chpasswd'
umount -l /mnt/alpine_root
