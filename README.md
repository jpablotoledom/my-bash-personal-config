# Environment User Configs

> [Versión en Español](LEAME.md)

Personal terminal environment setup: shell, editor, fonts and tools, deployable on Debian and macOS.

![alt Terminal colors](https://raw.githubusercontent.com/jpablotoledom/my-bash-personal-config/main/images/screenshot.png)

## What it installs

- **Oh My Bash** with the Powerline theme
- **Nerd Fonts** (Hack, MesloLGS, JetBrains Mono, Powerline collection)
- **Neovim** with vim-plug and a pre-configured plugin set
- **lsd** — modern `ls` replacement with icons
- **bat** — `cat` with syntax highlighting
- **tmux** — terminal multiplexer
- **Bash 5** — replaces macOS system Bash 3.2
- **ble.sh** — advanced Bash line editor with autocompletion

## Shell prompt features

The custom `.bashrc` configures the Powerline prompt with:

- OS icon (Apple, Debian, Arch, Fedora, etc.)
- Git branch and state with color coding:
  - Green — clean
  - Bright green — staged changes
  - Orange — unstaged changes
  - Yellow — untracked files
  - Red — merge/rebase conflict
- Repository icon (GitHub / Bitbucket / generic Git)
- Phosphor green color scheme

## Scripts

### `install_on_debian_13.sh`

Installs the environment on Debian 13 (also tested on Ubuntu 22).

- Installs packages via `apt`: neovim, bat, lsd, tmux, bash-completion, curl, git, etc.
- Installs ble.sh by cloning from GitHub and building
- Installs Oh My Bash from GitHub
- Copies `copy_to_user_folder/.bashrc_debian` as `~/.bashrc`
- Copies `.blerc` (ble.sh options), the Ghostty config (`~/.config/ghostty/config.ghostty`) and the WirePlumber config (50% initial volume for new analog outputs)
- Applies a fix for the `alsa-utils` 1.2.14 udev rule: hotplugging any sound card (e.g. a USB webcam behind a KVM switch) reset the speaker volume. The fixed rule is installed to `/etc/udev/rules.d/` only while the packaged rule still has the bug

- On machines with a graphical environment, shows a checklist of optional apps (already installed ones are marked). Only Debian packages, free official repositories, or builds from GitHub:
  - **Ghostty**: built at install time from the official source tarball of the latest version (per GitHub tags), with the Zig version that tag requires (from ziglang.org), installed to `/usr/local`
  - **Wayscriber**: official repository (wayscriber.com)
  - **GHex**, **Audacity**: Debian repositories
  - **Winetricks**: latest GitHub release script in `/usr/local/bin/winetricks` (the Debian package is in `contrib`, often not enabled)
  - **Ghidra**: latest GitHub release in `/opt/ghidra` (installs OpenJDK 25)
  - **86Box**: latest GitHub AppImage in `/usr/local/bin/86Box`, plus the ROM set in `~/.local/share/86Box/roms`
  - **VirtualBox**: Oracle's official repository (newest `virtualbox-X.Y`, signing key checked by fingerprint), adds the user to `vboxusers` and sets `kvm enable_virt_at_load=0` so KVM doesn't block AMD-V/VT-x on kernel 6.12+
  - **Wine**: WineHQ staging (official repository, enables i386)

**Requirements:** internet access, `sudo` privileges.

---

### `install_on_macos.sh`

Installs the environment on macOS 14+ (Apple Silicon and Intel) using Homebrew.

- Installs Homebrew if not already present
- Installs tools via `brew`: neovim, bat, lsd, bash, tmux
- Installs ble.sh by cloning from GitHub and building
- Installs Oh My Bash from GitHub
- Installs vim-plug from GitHub
- Copies `copy_to_user_folder/.bashrc_macos` as `~/.bashrc`
- Creates `~/.bash_profile` to use Bash 5 from Homebrew on login

**Requirements:** internet access.

---

### `install_on_macos_briked.sh`

Installs the environment on macOS 14+ (Apple Silicon and Intel) **without internet access**. All dependencies are bundled in `./thirdparty/macos/`.

- Installs pre-built binaries from `./thirdparty/macos/`: neovim, bat, lsd, tmux, bash 5
- Installs ble.sh from a local `.tar.xz` bundle
- Installs Oh My Bash from a local `.tar.gz` bundle
- Installs vim-plug from the local `plug.vim` file
- Installs pre-bundled Neovim plugins from `plugged.tar.gz`
- Copies `copy_to_user_folder/.bashrc_macos` as `~/.bashrc`
- Creates `~/.bash_profile` to use Bash 5 on login

**Requirements:** no internet needed. Bundled binaries support both `arm64` and `x86_64`.

---

## Project structure

```
.
├── install_on_debian_13.sh       # Debian/Ubuntu installer (online)
├── install_on_macos.sh           # macOS installer via Homebrew (online)
├── install_on_macos_briked.sh    # macOS installer offline (bundled)
├── copy_to_user_folder/
│   ├── .bashrc_debian            # Shell config for Debian/Ubuntu
│   ├── .bashrc_macos             # Shell config for macOS
│   ├── .vimrc                    # Vim config
│   ├── .blerc                    # ble.sh options
│   ├── .vim/
│   │   ├── plugins.vim           # vim-plug plugin list
│   │   └── plugged.tar.gz        # Pre-bundled plugins (offline use)
│   └── .config/
│       ├── nvim/init.vim         # Neovim init config
│       ├── ghostty/config.ghostty # Ghostty config (shell integration off)
│       └── wireplumber/wireplumber.conf.d/50-volume.conf # Initial analog output volume
├── system/debian/udev/
│   └── 90-alsa-restore.rules     # Fixed alsa-utils rule (volume reset on USB audio hotplug)
├── fonts/
│   ├── hack/                     # Hack Nerd Font
│   ├── meslolgs/                 # MesloLGS NF
│   ├── jetbrains/                # JetBrains Mono Nerd Font
│   └── powerline/                # Powerline font collection
├── thirdparty/macos/             # Offline bundles for macOS
└── show/
    ├── welcome                   # Welcome banner
    ├── divbar                    # Section divider
    └── finished                  # "All done" banner shown at the end
```

## Author

**Jonathan Pablo Toledo M.**  
[TheRetroCenter.com](https://www.theretrocenter.com)
