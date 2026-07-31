#!/bin/bash
set -e

# ==============================================================================
# Script para convertir el Kiosco (Direct Kernel Boot) en un Disco Raw Booteable
# Este script genera un archivo .img que puede ser convertido a VDI para VirtualBox
# o flasheado directamente a un USB.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Por favor ejecuta este script como root (sudo)."
  exit 1
fi

# Verificar dependencias
if ! command -v extlinux &> /dev/null; then
    echo "Falta el paquete 'syslinux-extlinux'. Instalándolo automáticamente..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y syslinux extlinux kpartx
    elif command -v apk &> /dev/null; then
        apk add syslinux
    else
        echo "Por favor instala 'syslinux' (extlinux) manualmente."
        exit 1
    fi
fi

IMG_FILE="out/alpine_kiosk.img"
ROOTFS_SOURCE="out/alpine_rootfs.ext4"
KERNEL_SOURCE="out/bzImage"

if [ ! -f "$ROOTFS_SOURCE" ] || [ ! -f "$KERNEL_SOURCE" ]; then
    echo "Error: Asegúrate de haber ejecutado ./create_alpine.sh y tener bzImage en out/"
    exit 1
fi

echo "1. Creando archivo de disco de 1.6 GB..."
rm -f "$IMG_FILE"
dd if=/dev/zero of="$IMG_FILE" bs=1M count=1600 status=progress

echo "2. Creando tabla de particiones (MBR) y partición booteable..."
fdisk "$IMG_FILE" <<EOF
o
n
p
1


a
w
EOF

echo "3. Mapeando el disco a un dispositivo loop..."
LOOP_DEV=$(losetup -P -f --show "$IMG_FILE")
PART_DEV="${LOOP_DEV}p1"
# A veces kpartx o udev es lento en WSL, si no existe p1 intentamos con part1
if [ ! -e "$PART_DEV" ]; then
    PART_DEV="${LOOP_DEV}part1"
fi
sleep 1

echo "4. Formateando partición como ext4..."
mkfs.ext4 "$PART_DEV"

echo "5. Montando partición destino..."
mkdir -p /mnt/new_disk
mount "$PART_DEV" /mnt/new_disk

echo "6. Montando el sistema de archivos raíz original..."
mkdir -p /mnt/old_root
mount -o loop "$ROOTFS_SOURCE" /mnt/old_root

echo "7. Migrando datos (esto puede tardar unos segundos)..."
cp -a /mnt/old_root/* /mnt/new_disk/

echo "8. Copiando Kernel (bzImage)..."
mkdir -p /mnt/new_disk/boot
cp "$KERNEL_SOURCE" /mnt/new_disk/boot/

echo "9. Instalando y configurando el Gestor de Arranque (Syslinux)..."
extlinux --install /mnt/new_disk/boot

cat <<EOF > /mnt/new_disk/boot/extlinux.conf
DEFAULT alpine
LABEL alpine
  SAY Arrancando SysMon 2026 Kiosk OS...
  LINUX /boot/bzImage
  APPEND root=/dev/sda1 console=tty1 rw quiet
EOF

echo "10. Desmontando particiones..."
umount /mnt/old_root
umount /mnt/new_disk
rmdir /mnt/old_root /mnt/new_disk

echo "11. Escribiendo el MBR en el disco..."
# Buscar mbr.bin dependiendo de la distro (Debian vs Alpine)
MBR_BIN=""
if [ -f "/usr/lib/syslinux/mbr/mbr.bin" ]; then MBR_BIN="/usr/lib/syslinux/mbr/mbr.bin"; fi
if [ -f "/usr/share/syslinux/mbr.bin" ]; then MBR_BIN="/usr/share/syslinux/mbr.bin"; fi
if [ -f "/usr/lib/EXTLINUX/mbr.bin" ]; then MBR_BIN="/usr/lib/EXTLINUX/mbr.bin"; fi

if [ -n "$MBR_BIN" ]; then
    dd if="$MBR_BIN" of="$IMG_FILE" bs=440 count=1 conv=notrunc
else
    echo "ADVERTENCIA: No se encontró mbr.bin. El disco podría no ser booteable en BIOS antiguas."
fi

losetup -d "$LOOP_DEV"

echo "==================================================================="
echo "¡Imagen lista! Archivo generado: $IMG_FILE"
echo ""
echo "Para VirtualBox, conviértela usando tu terminal de Windows:"
echo 'VBoxManage createmedium disk --filename alpine_kiosk.vmdk --format VMDK --variant RawDisk --image out/alpine_kiosk.img'
echo ""
echo "O grábala a un USB físico usando Rufus."
echo "==================================================================="
