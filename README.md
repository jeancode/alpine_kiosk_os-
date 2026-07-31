# Alpine Kiosk OS Builder

Este repositorio contiene la infraestructura como código (IaC) y los scripts necesarios para construir desde cero un sistema operativo ligero basado en Alpine Linux, diseñado para correr como un kiosco en QEMU.

## Arquitectura
El sistema se compone de dos elementos principales:
1. **El Kernel (bzImage):** Un núcleo Linux compilado a medida (aproximadamente 8MB) que debes colocar en la carpeta `out/bzImage`.
2. **El Sistema de Archivos Raíz (RootFS):** Un disco duro virtual (`.ext4`) que se construye dinámicamente utilizando el script de automatización incluido.

## Scripts Incluidos

* **`create_alpine.sh`**: El motor principal. Descarga la versión base de Alpine Linux (Mini rootfs), crea un disco virtual de 1.5GB, formatea el disco en `ext4`, monta el sistema y utiliza `chroot` para instalar los paquetes esenciales (`build-base`, `sdl2`, `openrc`, `dhcpcd`, `openssh`). Finalmente configura el sistema de arranque automático (Init).
* **`fix_inittab_correct.sh`**: Aplica un parche de seguridad al archivo de arranque (`/etc/inittab`) para asegurar que el sistema exija inicio de sesión (Login) en lugar de arrojar una terminal `root` expuesta.
* **`set_password.sh`**: Configura la contraseña del administrador y bloquea las conexiones SSH vacías editando `/etc/ssh/sshd_config`.
* **`update_banner.sh`**: Inyecta un colorido arte ASCII (Banner) en el archivo `/etc/motd` para darle una estética "Developer Edition" al momento de iniciar sesión.
* **`run_qemu.sh`**: Un script de comodidad para encender la máquina virtual mapeando el puerto SSH al puerto `2222` de la máquina anfitriona.

## Cómo Usarlo (Instrucciones de Construcción)

1. **Prerrequisitos:** Necesitas tener WSL (Windows Subsystem for Linux) o un entorno Linux con acceso root.
2. **Prepara el Kernel:** Coloca tu kernel compilado en `out/bzImage`.
3. **Construye el OS:**
   ```bash
   chmod +x *.sh
   sudo ./create_alpine.sh
   ```
4. **Aplica las Configuraciones:**
   ```bash
   sudo ./update_banner.sh
   sudo ./fix_inittab_correct.sh
   sudo ./set_password.sh
   ```
5. **Ejecuta la Máquina Virtual:**
   ```bash
   ./run_qemu.sh
   ```

*(Por seguridad, la contraseña de root por defecto configurada por `set_password.sh` es `admin`)*
