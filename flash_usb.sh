#!/bin/bash
set -e

# ==============================================================================
# Script para Flashear el Kiosco OS (.img) a una Memoria USB
# ADVERTENCIA: Este script sobrescribirá todos los datos del disco seleccionado.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Por favor ejecuta este script como root (sudo)."
  exit 1
fi

IMG_FILE="out/alpine_kiosk.img"

if [ ! -f "$IMG_FILE" ]; then
    echo "Error: No se encontró la imagen $IMG_FILE."
    echo "Asegúrate de haber ejecutado ./build_bootable_image.sh primero."
    exit 1
fi

echo "Dispositivos de almacenamiento disponibles (Ignora tu disco duro principal, busca tu USB):"
echo "----------------------------------------------------------------"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -i "disk"
echo "----------------------------------------------------------------"
echo ""

read -p "Ingresa el nombre del dispositivo USB (ejemplo: sdb, sdc): /dev/" target_dev

if [ -z "$target_dev" ]; then
    echo "Operación cancelada."
    exit 1
fi

TARGET="/dev/$target_dev"

if [ ! -b "$TARGET" ]; then
    echo "Error: El dispositivo $TARGET no existe."
    exit 1
fi

# Advertencia de seguridad extrema
echo ""
echo "============================================================================="
echo "¡ALERTA DE DESTRUCCIÓN DE DATOS!"
echo "Vas a borrar COMPLETAMENTE el disco: $TARGET"
echo "============================================================================="
read -p "¿Estás ABSOLUTAMENTE seguro? Escribe 'SI' en mayúsculas para continuar: " confirm

if [ "$confirm" != "SI" ]; then
    echo "Operación cancelada por seguridad."
    exit 0
fi

echo ""
echo "Flasheando la imagen al dispositivo $TARGET..."
echo "Esto puede tardar unos minutos dependiendo de la velocidad de tu USB."

# Asegurarse de que el disco no esté montado
umount "${TARGET}"* 2>/dev/null || true

# Flashear usando dd
dd if="$IMG_FILE" of="$TARGET" bs=4M status=progress oflag=sync

echo ""
echo "¡Éxito! El sistema operativo Kiosco ha sido grabado en el USB."
echo "Ya puedes extraer el USB, conectarlo a otra PC y arrancar desde él."
