#!/bin/bash
set -e

NORMAL_USER=$(ls /home | head -n 1)

su - $NORMAL_USER -c '
set -e
cd ~/kiosk_build

# 1. Configuración del Kernel (Agregando AMD e Intel)
cat << EOF > kernel.cfg
CONFIG_DRM=y
CONFIG_DRM_BOCHS=y
CONFIG_DRM_VIRTIO_GPU=y
CONFIG_DRM_SIMPLEDRM=y
CONFIG_DRM_FBDEV_EMULATION=y
CONFIG_DRM_AMDGPU=y
CONFIG_DRM_RADEON=y
CONFIG_DRM_I915=y
EOF

cd buildroot-2024.02.1
echo "BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=\"/home/'$NORMAL_USER'/kiosk_build/kernel.cfg\"" >> .config

# 2. Configuración de Buildroot (Agregando Mesa3D y Udev necesarios para SDL2)
cat << EOF >> .config
BR2_ROOTFS_DEVICE_CREATION_DYNAMIC_EUDEV=y
BR2_PACKAGE_EUDEV=y
BR2_PACKAGE_MESA3D=y
BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_SWRAST=y
BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_VIRGL=y
BR2_PACKAGE_MESA3D_OPENGL_EGL=y
BR2_PACKAGE_MESA3D_OPENGL_ES=y
EOF

# Aplicar los cambios
make olddefconfig
make linux-rebuild
make

# Copiar resultados
cp output/images/bzImage /mnt/c/Users/jean/.gemini/antigravity/scratch/kiosk/out/
cp output/images/rootfs.ext4 /mnt/c/Users/jean/.gemini/antigravity/scratch/kiosk/out/
'
