#!/bin/bash
# Script to launch the custom Alpine Linux OS using QEMU

echo "Starting Alpine Linux Kiosk Edition in QEMU..."
echo "Connect via SSH using: ssh root@127.0.0.1 -p 2222"

qemu-system-x86_64 \
    -kernel out/bzImage \
    -drive file=out/alpine_rootfs.ext4,format=raw,if=ide \
    -append "root=/dev/sda console=tty1 rw" \
    -m 1024 \
    -vga virtio \
    -net nic \
    -net user,hostfwd=tcp::2222-:22
