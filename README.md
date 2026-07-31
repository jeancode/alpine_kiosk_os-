# Alpine Kiosk OS Builder

Este repositorio contiene la infraestructura como código (IaC) y los scripts necesarios para construir desde cero un sistema operativo ligero basado en Alpine Linux, diseñado para correr como un kiosco en QEMU.

## Arquitectura
El sistema se compone de dos elementos principales:
1. **El Kernel (bzImage):** Un núcleo Linux compilado a medida (aproximadamente 8MB) que debes colocar en la carpeta `out/bzImage`.
2. **El Sistema de Archivos Raíz (RootFS):** Un disco duro virtual (`.ext4`) que se construye dinámicamente utilizando el script de automatización incluido.

## Entorno y Paquetes Configurados

Durante la ejecución de los scripts de construcción, el sistema se provee con las siguientes herramientas y controladores clave (inyectados nativamente en Alpine):

* **Red y Acceso Remoto:**
  * `openssh`: Servidor SSH configurado para acceso remoto (por defecto en el puerto local 2222 vía QEMU).
  * `dhcpcd` e `iproute2`: Para gestión automática de la red de la máquina virtual.
* **Controladores Gráficos (Drivers):**
  * `mesa-dri-gallium`: Controladores de aceleración gráfica por software/hardware.
  * `mesa-gl`: Soporte para OpenGL puro.
  * *Nota: La máquina de QEMU arranca inyectando un adaptador de video `virtio` que es consumido nativamente.*
* **Entorno de Desarrollo en C++ (Kiosco):**
  * `build-base`: Metapaquete que incluye `g++`, `gcc`, `make`, y librerías estándar de C/C++.
  * `sdl2-dev` y `sdl2_ttf-dev`: Librerías de gráficos y renderizado de texto (Simple DirectMedia Layer), preparadas para compilar interfaces gráficas en crudo.
* **Gestión de Hardware y Arranque:**
  * `openrc`: Sistema de inicialización súper ligero (reemplazo purista de `systemd`).
  * `eudev`: Gestor de dispositivos (udev) para detectar hardware en tiempo real.

## Scripts Incluidos

* **`create_alpine.sh`**: El motor principal. Descarga la versión base de Alpine Linux (Mini rootfs), crea un disco virtual de 1.5GB, formatea el disco en `ext4`, monta el sistema y utiliza `chroot` para instalar los paquetes esenciales (`build-base`, `sdl2`, `openrc`, `dhcpcd`, `openssh`). Finalmente configura el sistema de arranque automático (Init).
* **`fix_inittab_correct.sh`**: Aplica un parche de seguridad al archivo de arranque (`/etc/inittab`) para asegurar que el sistema exija inicio de sesión (Login) en lugar de arrojar una terminal `root` expuesta.
* **`set_password.sh`**: Configura la contraseña del administrador y bloquea las conexiones SSH vacías editando `/etc/ssh/sshd_config`.
* **`update_banner.sh`**: Inyecta un colorido arte ASCII (Banner) en el archivo `/etc/motd` para darle una estética "Developer Edition" al momento de iniciar sesión.
* **`run_qemu.sh`**: Un script de comodidad para encender la máquina virtual mapeando el puerto SSH al puerto `2222` de la máquina anfitriona.
* **`build_bootable_image.sh`**: Transforma el entorno (que originalmente solo arranca en QEMU) en un disco crudo (`.img`) de 1.6GB con tabla de particiones MBR y gestor de arranque Syslinux, listo para VirtualBox o para flashear en un USB.

## Cómo Usarlo (Instrucciones de Construcción)

1. **Prerrequisitos:** Necesitas tener WSL (Windows Subsystem for Linux) o un entorno Linux con acceso root.
2. **Prepara el Kernel:** Coloca tu kernel compilado en `out/bzImage`.
3. **Construye el OS:**
   ```bash
   chmod +x *.sh
   sudo ./create_alpine.sh
   ```
4. **Aplica las Configuraciones (Opcional pero recomendado):**
   ```bash
   sudo ./update_banner.sh
   sudo ./fix_inittab_correct.sh
   sudo ./set_password.sh
   ```
5. **Genera la Imagen para VirtualBox o USB (Nuevo):**
   ```bash
   sudo ./build_bootable_image.sh
   ```
6. **Ejecuta la Máquina Virtual en QEMU:**
   ```bash
   ./run_qemu.sh
   ```

## Arquitectura de Diseño: ¿Por qué `.img` y no `.iso`?

Es una duda común querer empaquetar el sistema en un archivo `.iso`. Sin embargo, hemos optado por generar un Disco Duro Crudo (`.img`) por dos razones técnicas vitales:

1. **La Regla de Solo Lectura (Persistencia):** El formato `.iso` (ISO 9660) está diseñado por naturaleza para ser de **solo lectura**. Si compiláramos un `.iso`, cualquier archivo guardado, base de datos alterada o registro (log) escrito por el kiosco desaparecería al reiniciar. Un disco `.img` actúa como un pendrive real, ofreciendo **lectura y escritura permanente**.
2. **El Riesgo del Initramfs:** Para arrancar desde un CD de solo lectura y permitir una falsa escritura en RAM (Live CD), el Kernel de Linux necesita un subsistema de rescate llamado `initramfs`. Puesto que en este proyecto el Kernel (`bzImage`) es personalizado, minimalista (8MB) y de arranque directo, obligarlo a leer un sistema de archivos ISO sin los controladores (drivers) y módulos adecuados (como `isofs` o `loop`) arriesgaría un colapso de arranque catastrófico (Kernel Panic). 

El archivo `.img` provee la solución más elegante: se comporta idéntico a un Disco de Estado Sólido (SSD), retiene todos los datos tras un apagado, y cualquier PC o VirtualBox lo arranca nativamente mediante un MBR estándar.

*(Por seguridad, la contraseña de root por defecto configurada por `set_password.sh` es `admin`)*
