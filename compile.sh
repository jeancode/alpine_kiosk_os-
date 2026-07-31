#!/bin/bash
set -e
NORMAL_USER=$(ls /home | head -n 1)

su - $NORMAL_USER -c '
set -e
cd ~/kiosk_build
cat << '\''EOF'\'' > buildroot-2024.02.1/output/target/etc/init.d/S99kiosk
#!/bin/sh
export SDL_VIDEODRIVER=KMSDRM

# Intentar levantar la red en background
ip link set lo up
for iface in $(ls /sys/class/net | grep -v lo); do
    ip link set $iface up
    udhcpc -i $iface &
done

# Ejecutar el kiosko
/usr/bin/kiosk_app &
EOF
chmod +x buildroot-2024.02.1/output/target/etc/init.d/S99kiosk

cd buildroot-2024.02.1
./output/host/bin/x86_64-buildroot-linux-gnu-g++ \
    ./kiosk.cpp -o output/target/usr/bin/kiosk_app \
    -Ioutput/staging/usr/include/SDL2 \
    -Loutput/staging/usr/lib -lSDL2 -Wl,-rpath,/usr/lib

make

cp output/images/bzImage /mnt/c/Users/jean/.gemini/antigravity/scratch/kiosk/out/
cp output/images/rootfs.ext4 /mnt/c/Users/jean/.gemini/antigravity/scratch/kiosk/out/
'
