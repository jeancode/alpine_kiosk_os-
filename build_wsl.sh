#!/bin/bash
set -e

echo "Instalando dependencias de Buildroot en WSL..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential wget cpio unzip rsync bc git python3 file libncurses-dev pkg-config libelf-dev libssl-dev

# We must run buildroot as a non-root user, otherwise it complains
# "You're building as root! Do not do this!"
# So we switch to the normal user (e.g., ubuntu) for the rest of the build.
NORMAL_USER=$(ls /home | head -n 1)

su - $NORMAL_USER -c '
set -e
mkdir -p ~/kiosk_build
cd ~/kiosk_build

if [ ! -d "buildroot-2024.02.1" ]; then
    echo "Descargando Buildroot..."
    wget -q https://buildroot.org/downloads/buildroot-2024.02.1.tar.gz
    tar xzf buildroot-2024.02.1.tar.gz
    rm buildroot-2024.02.1.tar.gz
fi

cd buildroot-2024.02.1

echo "Configurando Buildroot..."
WINDOWS_DIR="/mnt/c/Users/jean/.gemini/antigravity/scratch/kiosk"

cp "$WINDOWS_DIR/kiosk.cpp" ./kiosk.cpp

cat << EOF > .config
BR2_x86_64=y
BR2_TOOLCHAIN_BUILDROOT_CXX=y
BR2_TARGET_GENERIC_HOSTNAME="kiosk"
BR2_LINUX_KERNEL=y
BR2_LINUX_KERNEL_DEFCONFIG="x86_64"
BR2_PACKAGE_SDL2=y
BR2_PACKAGE_SDL2_KMSDRM=y
BR2_TARGET_ROOTFS_EXT2=y
BR2_TARGET_ROOTFS_EXT2_4=y
EOF

make olddefconfig

echo "Iniciando compilacion del Kernel de Linux y dependencias (Toma de 30 a 60 min)..."
make

echo "Compilando aplicacion C++ (Kiosco)..."
./output/host/bin/x86_64-buildroot-linux-gnu-g++ \
    ./kiosk.cpp -o output/target/usr/bin/kiosk_app \
    -Ioutput/staging/usr/include/SDL2 -Loutput/staging/usr/lib -lSDL2 -Wl,-rpath,/usr/lib

echo "Configurando script de inicio..."
cat << EOF > output/target/etc/init.d/S99kiosk
#!/bin/sh
exec /usr/bin/kiosk_app
EOF
chmod +x output/target/etc/init.d/S99kiosk

echo "Reconstruyendo imagen del sistema con el Kiosco incluido..."
make

echo "Copiando archivos resultantes de vuelta a Windows..."
mkdir -p "$WINDOWS_DIR/out"
cp output/images/bzImage "$WINDOWS_DIR/out/"
cp output/images/rootfs.ext4 "$WINDOWS_DIR/out/"

echo "¡Construccion terminada exitosamente!"
'
