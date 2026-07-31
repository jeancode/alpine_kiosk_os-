#!/bin/bash
set -e

NORMAL_USER=$(ls /home | head -n 1)

su - $NORMAL_USER -c '
set -e
cd ~/kiosk_build/buildroot-2024.02.1

# Enable Dropbear (Lightweight SSH Server)
echo "BR2_PACKAGE_DROPBEAR=y" >> .config
make olddefconfig

# Clean SDL2 so it recompiles WITH KMSDRM support now that Mesa3D/libgbm is installed
make sdl2-dirclean

# Recompile SDL2 and the rest of the system
make

# Recompile our app against the new SDL2 library
cd ~/kiosk_build
./buildroot-2024.02.1/output/host/bin/x86_64-buildroot-linux-gnu-g++ \
    ./kiosk.cpp -o buildroot-2024.02.1/output/target/usr/bin/kiosk_app \
    -Ibuildroot-2024.02.1/output/staging/usr/include/SDL2 \
    -Lbuildroot-2024.02.1/output/staging/usr/lib -lSDL2 -Wl,-rpath,/usr/lib

# Pack the final image again
cd buildroot-2024.02.1
make

cp output/images/bzImage /mnt/c/Users/jean/.gemini/antigravity/scratch/kiosk/out/
cp output/images/rootfs.ext4 /mnt/c/Users/jean/.gemini/antigravity/scratch/kiosk/out/
'
