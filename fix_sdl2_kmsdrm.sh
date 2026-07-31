#!/bin/bash
set -e
NORMAL_USER=$(ls /home | head -n 1)

su - $NORMAL_USER -c '
set -e
cd ~/kiosk_build/buildroot-2024.02.1

# Enable OpenGLES which is REQUIRED for KMSDRM
echo "BR2_PACKAGE_SDL2_OPENGLES=y" >> .config
echo "BR2_PACKAGE_SDL2_KMSDRM=y" >> .config
make olddefconfig

# Verify it got enabled
grep KMSDRM .config

# Recompile SDL2
make sdl2-dirclean
make

# Recompile app
cd ~/kiosk_build
./buildroot-2024.02.1/output/host/bin/x86_64-buildroot-linux-gnu-g++ \
    ./kiosk.cpp -o buildroot-2024.02.1/output/target/usr/bin/kiosk_app \
    -Ibuildroot-2024.02.1/output/staging/usr/include/SDL2 \
    -Lbuildroot-2024.02.1/output/staging/usr/lib -lSDL2 -Wl,-rpath,/usr/lib

# Pack
cd buildroot-2024.02.1
make

cp output/images/bzImage /mnt/c/Users/jean/.gemini/antigravity/scratch/kiosk/out/
cp output/images/rootfs.ext4 /mnt/c/Users/jean/.gemini/antigravity/scratch/kiosk/out/
'
