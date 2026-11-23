# Environment User Configs

Configuración personal de entorno de terminal: shell, editor, fuentes y herramientas, desplegable en Debian y macOS.

![alt Terminal colors](https://raw.githubusercontent.com/jpablotoledom/my-bash-personal-config/main/images/screenshot.png)

## Qué instala

- **Oh My Bash** con el tema Powerline
- **Nerd Fonts** (Hack, MesloLGS, JetBrains Mono, colección Powerline)
- **Neovim** con vim-plug y un conjunto de plugins preconfigurado
- **lsd** — reemplazo moderno de `ls` con íconos
- **bat** — `cat` con resaltado de sintaxis
- **tmux** — multiplexor de terminal
- **Bash 5** — reemplaza el Bash 3.2 del sistema en macOS
- **ble.sh** — editor de línea de Bash avanzado con autocompletado

## Características del prompt

El `.bashrc` personalizado configura el prompt Powerline con:

- Ícono del sistema operativo (Apple, Debian, Arch, Fedora, etc.)
- Rama y estado de Git con colores:
  - Verde — repositorio limpio
  - Verde brillante — cambios en stage
  - Naranja — cambios sin stage
  - Amarillo — archivos sin seguimiento
  - Rojo — conflicto de merge/rebase
- Ícono del repositorio (GitHub / Bitbucket / Git genérico)
- Paleta de color verde fósforo

## Scripts

### `install_on_debian_13.sh`

Instala el entorno en Debian 13 (probado también en Ubuntu 22).

- Instala paquetes con `apt`: neovim, bat, lsd, tmux, bash-completion, curl, git, etc.
- Instala ble.sh clonando desde GitHub y compilando
- Instala Oh My Bash desde GitHub
- Copia `copy_to_user_folder/.bashrc_debian` como `~/.bashrc`
- Copia `.blerc` (opciones de ble.sh), la configuración de Ghostty (`~/.config/ghostty/config.ghostty`) y la de WirePlumber (volumen inicial de 50% para salidas analógicas nuevas)
- Aplica una corrección a la regla udev de `alsa-utils` 1.2.14: al conectar cualquier tarjeta de sonido (p. ej. una webcam USB detrás de un switch KVM) se reseteaba el volumen de los parlantes. La regla corregida se instala en `/etc/udev/rules.d/` solo mientras la regla del paquete siga con el bug

- En equipos con entorno gráfico, muestra una lista de aplicaciones opcionales para elegir (las ya instaladas aparecen marcadas). Solo paquetes de Debian, repositorios oficiales gratuitos o compilación desde GitHub:
  - **Ghostty**: se compila al instalar desde el tarball oficial de la última versión (según los tags de GitHub), con la versión de Zig que ese tag exige (desde ziglang.org), y se instala en `/usr/local`
  - **Wayscriber**: repositorio oficial (wayscriber.com)
  - **GHex**, **Audacity**: repositorios de Debian
  - **Winetricks**: script del último release de GitHub en `/usr/local/bin/winetricks` (el paquete de Debian está en `contrib`, que muchas veces no está activado)
  - **Ghidra**: último release de GitHub en `/opt/ghidra` (instala OpenJDK 25)
  - **86Box**: último AppImage de GitHub en `/usr/local/bin/86Box`, más el set de ROMs en `~/.local/share/86Box/roms` y los íconos oficiales del mismo release
  - **VirtualBox**: repositorio oficial de Oracle (último `virtualbox-X.Y`, clave de firma verificada por huella), agrega el usuario a `vboxusers` y configura `kvm enable_virt_at_load=0` para que KVM no bloquee AMD-V/VT-x en el kernel 6.12+
  - **Wine**: WineHQ staging (repositorio oficial, habilita i386)

**Requisitos:** acceso a internet, permisos `sudo`.

---

### `install_on_macos.sh`

Instala el entorno en macOS 14+ (Apple Silicon e Intel) usando Homebrew.

- Instala Homebrew si no está presente
- Instala herramientas con `brew`: neovim, bat, lsd, bash, tmux
- Instala ble.sh clonando desde GitHub y compilando
- Instala Oh My Bash desde GitHub
- Instala vim-plug desde GitHub
- Copia `copy_to_user_folder/.bashrc_macos` como `~/.bashrc`
- Crea `~/.bash_profile` para usar Bash 5 de Homebrew al iniciar sesión

**Requisitos:** acceso a internet.

---

### `install_on_macos_briked.sh`

Instala el entorno en macOS 14+ (Apple Silicon e Intel) **sin acceso a internet**. Todas las dependencias están empaquetadas en `./thirdparty/macos/`.

- Instala binarios precompilados desde `./thirdparty/macos/`: neovim, bat, lsd, tmux, bash 5
- Instala ble.sh desde un bundle `.tar.xz` local
- Instala Oh My Bash desde un bundle `.tar.gz` local
- Instala vim-plug desde el archivo `plug.vim` local
- Instala los plugins de Neovim preempaquetados en `plugged.tar.gz`
- Copia `copy_to_user_folder/.bashrc_macos` como `~/.bashrc`
- Crea `~/.bash_profile` para usar Bash 5 al iniciar sesión

**Requisitos:** sin internet. Los binarios bundleados soportan `arm64` y `x86_64`.

---

## Estructura del proyecto

```
.
├── install_on_debian_13.sh       # Instalador Debian/Ubuntu (online)
├── install_on_macos.sh           # Instalador macOS con Homebrew (online)
├── install_on_macos_briked.sh    # Instalador macOS sin internet (bundleado)
├── copy_to_user_folder/
│   ├── .bashrc_debian            # Configuración de shell para Debian/Ubuntu
│   ├── .bashrc_macos             # Configuración de shell para macOS
│   ├── .vimrc                    # Configuración de Vim
│   ├── .blerc                    # Opciones de ble.sh
│   ├── .vim/
│   │   ├── plugins.vim           # Lista de plugins de vim-plug
│   │   └── plugged.tar.gz        # Plugins preempaquetados (uso offline)
│   └── .config/
│       ├── nvim/init.vim         # Configuración de inicio de Neovim
│       ├── ghostty/config.ghostty # Configuración de Ghostty (shell integration desactivada)
│       └── wireplumber/wireplumber.conf.d/50-volume.conf # Volumen inicial de salidas analógicas
├── system/debian/udev/
│   └── 90-alsa-restore.rules     # Regla de alsa-utils corregida (reseteo de volumen al conectar audio USB)
├── fonts/
│   ├── hack/                     # Hack Nerd Font
│   ├── meslolgs/                 # MesloLGS NF
│   ├── jetbrains/                # JetBrains Mono Nerd Font
│   └── powerline/                # Colección de fuentes Powerline
├── thirdparty/macos/             # Bundles offline para macOS
└── show/
    ├── welcome                   # Banner de bienvenida
    ├── divbar                    # Separador de secciones
    └── finished                  # Banner "All done" que se muestra al terminar
```

## Author

**Jonathan Pablo Toledo M.**  
[TheRetroCenter.com](https://www.theretrocenter.com)
