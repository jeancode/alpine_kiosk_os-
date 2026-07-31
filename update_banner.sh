#!/bin/bash
set -e

WINDOWS_DIR="/mnt/c/Users/jean/.gemini/antigravity/scratch/kiosk"
cd $WINDOWS_DIR

mount -o loop out/alpine_rootfs.ext4 /mnt/alpine_root

cat << 'EOF' > /mnt/alpine_root/etc/motd.raw
\e[36m
   ██╗  ██╗██╗ ██████╗ ███████╗██╗  ██╗ ██████╗ 
   ██║ ██╔╝██║██╔═══██╗██╔════╝██║ ██╔╝██╔═══██╗
   █████╔╝ ██║██║   ██║███████╗█████╔╝ ██║   ██║
   ██╔═██╗ ██║██║   ██║╚════██║██╔═██╗ ██║   ██║
   ██║  ██╗██║╚██████╔╝███████║██║  ██╗╚██████╔╝
   ╚═╝  ╚═╝╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝ 
\e[0m
   \e[1;32m[ KIOSK CORE // \e[1;33mDEVELOPER EDITION \e[1;32m]\e[0m
   \e[90m============================================\e[0m
   \e[37mKernel:    \e[32mCustom bzImage (KMSDRM / Virtio)\e[0m
   \e[37mCompiler:  \e[32mg++ (Native)\e[0m
   \e[37mStatus:    \e[32mRoot Access Granted\e[0m
   \e[90m============================================\e[0m

EOF

# Usar echo -e para interpretar los \e como el caracter ESC(27)
echo -e "$(cat /mnt/alpine_root/etc/motd.raw)" > /mnt/alpine_root/etc/motd
rm /mnt/alpine_root/etc/motd.raw

umount -l /mnt/alpine_root
