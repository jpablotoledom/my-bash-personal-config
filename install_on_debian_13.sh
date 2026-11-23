#!/bin/bash
# *************************************************************** #
#                           WELCOME                               #
#                                                                 #
#  Tested on:                                                     #
#   - Ubuntu 22                                                   #
#                                                                 #
# *************************************************************** #
source ./show/welcome

# Get user in session and say hello
user="$(whoami)" 
echo "Hi ${user}!!"

# *************************************************************** #
#                       1- Copy fonts                             #
# *************************************************************** #
source ./show/divbar
echo '1- Copying Nerd Fonts...'
source ./show/divbar
sleep .5

# 1.1 Create fonst type directories
sudo mkdir -p /usr/share/fonts/TTF
sudo mkdir -p /usr/share/fonts/OTF

# 1.2 Copy all fonts
sudo cp -r ./fonts/hack/*.ttf /usr/share/fonts/TTF
sudo cp -r ./fonts/meslolgs/*.ttf /usr/share/fonts/TTF
sudo cp -r ./fonts/powerline/*.ttf /usr/share/fonts/TTF
sudo cp -r ./fonts/powerline/*.otf /usr/share/fonts/OTF
sudo cp -r ./fonts/jetbrains/*.ttf /usr/share/fonts/TTF

fc-cache -fv

# *************************************************************** #
#                  2- Install terminal tools                      #
# *************************************************************** #
echo '2- Installing terminal tools...'
source ./show/divbar
sleep .5

# 2.1 Install software with apt
sudo apt -y install locate
sudo apt -y install p7zip-full
sudo apt -y install zsh
sudo apt -y install tmux
sudo apt -y install neovim
sudo apt -y install curl
sudo apt -y install wget
sudo apt -y install git
sudo apt -y install bat
sudo apt -y install lsd
sudo apt -y install bash-completion
sudo apt -y install gawk

# 2.2 Install autocompletation tool
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
make -C ble.sh install PREFIX=~/.local
rm -R -f ble.sh

# *************************************************************** #
#                  3- Install OH MY BASH                          #
# *************************************************************** #
source ./show/divbar
echo '3- Installing OH MY BASH...'
sleep .5

bash -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)"

# *************************************************************** #
#                  4- Install RUNCOM files                        #
# *************************************************************** #
source ./show/divbar
echo '4- Installing RUNCOM files...'
sleep .5

# 4.1 Create backup RUNCOM files
mv -f ~/.zshrc ~/.zshrc.back
mv -f ~/.vimrc ~/.vimrc.back
mv -f ~/.bashrc ~/./.bashrc.back

# 4.2 Copy custom Bash RUNCOM to user directory
cp ./copy_to_user_folder/.bashrc_debian ~/.bashrc

# 4.3 Copy other user config files to user directory
cp -r ./copy_to_user_folder/.vimrc ~/
cp ./copy_to_user_folder/.blerc ~/.blerc

# 4.4 Ghostty terminal config (shell integration disabled: it duplicates the
#     first line of the multi-line prompt when used together with ble.sh)
mkdir -p ~/.config/ghostty
cp ./copy_to_user_folder/.config/ghostty/config.ghostty ~/.config/ghostty/config.ghostty

# 4.5 WirePlumber: initial volume (50%) for new analog outputs
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
cp ./copy_to_user_folder/.config/wireplumber/wireplumber.conf.d/50-volume.conf ~/.config/wireplumber/wireplumber.conf.d/

# *************************************************************** #
#               5- Copy neovim configuration                      #
# *************************************************************** #
source ./show/divbar
echo '5- Installing VIM plugins...'
source ./show/divbar
sleep .5

# 5.1 Create .vim directories
mkdir -p  ~/.vim/plugged

# 5.2 Copy plugins list
cp -r ./copy_to_user_folder/.vim/plugins.vim ~/.vim/plugins.vim

# 5.3 Copy configuration init file
mkdir -p ~/.config/nvim
cp -r ./copy_to_user_folder/.config/nvim/init.vim ~/.config/nvim/init.vim

# 5.4 Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# 5.5 Copy nvim plugins
cd ./copy_to_user_folder/.vim/
tar -zxvf plugged.tar.gz
cp -r plugged/* ~/.vim/plugged
rm -R -f plugged
cd ../..

# *************************************************************** #
#               6- System fixes (Debian 13)                       #
# *************************************************************** #
source ./show/divbar
echo '6- Applying system fixes...'
source ./show/divbar
sleep .5

# 6.1 alsa-utils 1.2.14 udev rule bug: hotplugging any sound card (e.g. a USB
#     webcam behind a KVM switch) restores the mixer of the HDA analog card,
#     resetting the speaker volume. Install the fixed rule only while the
#     packaged rule still has the duplicated "alsa_restore_go" label.
if [[ $(grep -c '^LABEL="alsa_restore_go"' /usr/lib/udev/rules.d/90-alsa-restore.rules 2>/dev/null) -ge 2 ]]; then
  sudo install -m644 ./system/debian/udev/90-alsa-restore.rules /etc/udev/rules.d/90-alsa-restore.rules
  sudo udevadm control --reload
fi

# *************************************************************** #
#           7- Optional GUI applications (desktop only)           #
# *************************************************************** #

# 7.0 Detect a graphical environment: an active X11/Wayland session, or a
#     system that boots into the graphical target.
has_gui() {
  [[ -n ${WAYLAND_DISPLAY-} || -n ${DISPLAY-} || -n ${XDG_CURRENT_DESKTOP-} ]] && return 0
  [[ $(systemctl get-default 2>/dev/null) == graphical.target ]]
}

is_installed() { command -v "$1" >/dev/null 2>&1; }

# Ghostty: built from source at install time, always the newest version.
# The version comes from the latest GitHub tag; the code is the official source
# tarball (release.files.ghostty.org), which ships pre-generated UI files.
# A git checkout would need blueprint-compiler >= 0.20, newer than Debian 13's.
# Zig is downloaded from ziglang.org in the exact version that release requires.
install_ghostty() {
  sudo apt -y install curl xz-utils pkg-config gettext libxml2-utils \
    libgtk-4-dev libadwaita-1-dev libgtk4-layer-shell-dev
  local tmp ver zigver jobs
  # /tmp is a RAM-backed tmpfs on Debian 13: build on disk instead, otherwise
  # Zig, the sources and the build cache fill the RAM and clang gets OOM-killed.
  tmp=$(mktemp -d -p /var/tmp ghostty-build.XXXXXX)
  # About 2 GB of RAM per parallel compile job
  jobs=$(( $(awk '/^MemAvailable/{print $2}' /proc/meminfo) / 2097152 ))
  (( jobs < 1 )) && jobs=1
  (( jobs > $(nproc) )) && jobs=$(nproc)
  ver=$(curl -fsSL "https://api.github.com/repos/ghostty-org/ghostty/tags?per_page=20" \
        | grep -o '"name": *"v[0-9]*\.[0-9]*\.[0-9]*"' | cut -d'"' -f4 | sort -V | tail -1)
  ver=${ver#v}
  [[ -n $ver ]] || { echo "Ghostty: could not find the latest version"; rm -rf "$tmp"; return 1; }
  curl -fsSL "https://release.files.ghostty.org/$ver/ghostty-$ver.tar.gz" | tar -xz -C "$tmp" \
    || { echo "Ghostty: could not download the $ver source tarball"; rm -rf "$tmp"; return 1; }
  zigver=$(grep -o 'minimum_zig_version *= *"[^"]*"' "$tmp/ghostty-$ver/build.zig.zon" | cut -d'"' -f2)
  echo "Building Ghostty $ver with Zig $zigver ($jobs parallel jobs)..."
  curl -fsSL "https://ziglang.org/download/$zigver/zig-x86_64-linux-$zigver.tar.xz" | tar -xJ -C "$tmp" \
    || { echo "Ghostty: could not download Zig $zigver"; rm -rf "$tmp"; return 1; }
  (
    cd "$tmp/ghostty-$ver" &&
    DESTDIR="$tmp/stage" "$tmp/zig-x86_64-linux-$zigver/zig" build -j"$jobs" \
      --prefix /usr/local -Doptimize=ReleaseFast -Dversion-string="$ver"
  ) || { echo "Ghostty: build failed (sources kept in $tmp)"; return 1; }
  sudo cp -a "$tmp/stage/usr/local/." /usr/local/
  rm -rf "$tmp"
}

# Wayscriber: official apt repository
install_wayscriber() {
  sudo apt -y install curl gpg
  curl -fsSL https://wayscriber.com/apt/WAYSCRIBER-GPG-KEY.asc | gpg --dearmor | sudo tee /usr/share/keyrings/wayscriber.gpg > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/wayscriber.gpg] https://wayscriber.com/apt stable main" | sudo tee /etc/apt/sources.list.d/wayscriber.list > /dev/null
  sudo apt update
  sudo apt -y install wayscriber
}

# Ghidra: latest release zip from GitHub into /opt (requires JDK 25)
install_ghidra() {
  sudo apt -y install openjdk-25-jdk unzip curl
  local url zip
  url=$(curl -fsSL https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest \
        | grep -o '"browser_download_url": *"[^"]*_PUBLIC_[^"]*\.zip"' | cut -d'"' -f4 | head -1)
  [[ -n $url ]] || { echo "Ghidra: could not find the latest release"; return 1; }
  zip=/tmp/${url##*/}
  curl -fL -o "$zip" "$url"
  sudo unzip -q -o "$zip" -d /opt
  rm -f "$zip"
  # /opt/ghidra always points to the newest extracted version
  sudo ln -sfn "$(ls -d /opt/ghidra_*_PUBLIC | sort -V | tail -1)" /opt/ghidra
  sudo ln -sf /opt/ghidra/ghidraRun /usr/local/bin/ghidra
  sudo tee /usr/share/applications/ghidra.desktop > /dev/null <<'DESKTOP'
[Desktop Entry]
Name=Ghidra
Comment=Software reverse engineering framework
Exec=/opt/ghidra/ghidraRun
Icon=/opt/ghidra/support/ghidra.ico
Type=Application
Categories=Development;
DESKTOP
}

# 86Box: latest AppImage from GitHub + ROM set
install_86box() {
  sudo apt -y install libfuse2t64 curl git
  local url
  url=$(curl -fsSL https://api.github.com/repos/86Box/86Box/releases/latest \
        | grep -o '"browser_download_url": *"[^"]*-Linux-x86_64-[^"]*\.AppImage"' | cut -d'"' -f4 | head -1)
  [[ -n $url ]] || { echo "86Box: could not find the latest release"; return 1; }
  sudo curl -fL -o /usr/local/bin/86Box "$url"
  sudo chmod +x /usr/local/bin/86Box
  # ROMs are distributed separately; 86Box looks for them in ~/.local/share/86Box/roms
  if [[ ! -d ~/.local/share/86Box/roms ]]; then
    mkdir -p ~/.local/share/86Box
    git clone --depth 1 https://github.com/86Box/roms.git ~/.local/share/86Box/roms
  fi
  mkdir -p ~/.local/share/applications
  cat > ~/.local/share/applications/86box.desktop <<'DESKTOP'
[Desktop Entry]
Name=86Box
Exec=/usr/local/bin/86Box
Type=Application
Categories=System;Emulator;
DESKTOP
}

# Wine: WineHQ staging build (32-bit support needs the i386 architecture)
install_wine() {
  sudo dpkg --add-architecture i386
  sudo mkdir -pm755 /etc/apt/keyrings
  curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/winehq-archive.key
  sudo curl -fsSL -o /etc/apt/sources.list.d/winehq-trixie.sources \
    https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources
  sudo apt update
  sudo apt -y install --install-recommends winehq-staging
}

# VirtualBox: Oracle's official apt repository, newest virtualbox-X.Y package
install_virtualbox() {
  sudo apt -y install curl gpg "linux-headers-$(uname -r)"
  local key codename fpr pkg kvm_mod
  # The signing key comes from download.virtualbox.org (www.virtualbox.org
  # sometimes answers 504) and must be Oracle's VirtualBox archive key.
  key=$(mktemp)
  curl -fsSL -o "$key" https://download.virtualbox.org/virtualbox/debian/oracle_vbox_2016.asc \
    || { echo "VirtualBox: could not download the signing key"; rm -f "$key"; return 1; }
  fpr=$(gpg --show-keys --with-colons "$key" | awk -F: '/^fpr/{print $10; exit}')
  if [[ $fpr != B9F8D658297AF3EFC18D5CDFA2F683C52980AECF ]]; then
    echo "VirtualBox: unexpected key fingerprint ($fpr)"; rm -f "$key"; return 1
  fi
  sudo gpg --dearmor --yes -o /usr/share/keyrings/oracle-virtualbox-2016.gpg < "$key"
  rm -f "$key"
  codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $codename contrib" \
    | sudo tee /etc/apt/sources.list.d/virtualbox.list > /dev/null
  sudo apt update
  pkg=$(apt-cache pkgnames virtualbox- | grep -E '^virtualbox-[0-9]+\.[0-9]+$' | sort -V | tail -1)
  [[ -n $pkg ]] || { echo "VirtualBox: no package found for $codename"; return 1; }
  sudo apt -y install "$pkg"
  # USB passthrough needs the vboxusers group (applies after logging in again)
  sudo usermod -aG vboxusers "$USER"
  # Since kernel 6.12 KVM grabs AMD-V/VT-x as soon as it loads and VirtualBox
  # fails with VERR_SVM_IN_USE / VERR_VMX_IN_USE. With enable_virt_at_load=0
  # KVM only takes it while a KVM VM (e.g. Android emulator) is running.
  echo 'options kvm enable_virt_at_load=0' | sudo tee /etc/modprobe.d/kvm-virtualbox.conf > /dev/null
  if grep -qw svm /proc/cpuinfo; then kvm_mod=kvm_amd; else kvm_mod=kvm_intel; fi
  if lsmod | grep -q '^kvm '; then
    sudo modprobe -r "$kvm_mod" kvm 2>/dev/null && sudo modprobe "$kvm_mod" \
      || echo "VirtualBox: KVM is in use, the KVM option applies after rebooting"
  fi
  echo "VirtualBox installed: log out and back in so USB devices work in VMs."
}

install_ghex()       { sudo apt -y install ghex; }
install_audacity()   { sudo apt -y install audacity; }

# Winetricks: latest release script from GitHub. The Debian package lives in
# "contrib", which many installs don't enable, and lags behind upstream.
install_winetricks() {
  sudo apt -y install curl wget binutils cabextract unzip p7zip-full xz-utils zenity
  local tag
  tag=$(curl -fsSL https://api.github.com/repos/Winetricks/winetricks/releases/latest \
        | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)
  [[ -n $tag ]] || { echo "Winetricks: could not find the latest release"; return 1; }
  sudo curl -fL -o /usr/local/bin/winetricks \
    "https://raw.githubusercontent.com/Winetricks/winetricks/$tag/src/winetricks" || return 1
  sudo chmod +x /usr/local/bin/winetricks
}

if has_gui; then
  source ./show/divbar
  echo '7- Optional GUI applications...'
  source ./show/divbar
  sleep .5

  command -v whiptail >/dev/null 2>&1 || sudo apt -y install whiptail

  # id | description | command used to detect if it is already installed
  apps=(
    "ghostty|Ghostty - GPU terminal emulator|ghostty"
    "wayscriber|Wayscriber - draw on screen (Wayland)|wayscriber"
    "ghex|GHex - hex editor|ghex"
    "ghidra|Ghidra - reverse engineering (JDK 25)|ghidra"
    "audacity|Audacity - audio editor|audacity"
    "86box|86Box - retro PC emulator (+ ROMs)|86Box"
    "virtualbox|VirtualBox - virtual machines (Oracle repo)|VirtualBox"
    "wine|Wine (WineHQ staging) - Windows apps|wine"
    "winetricks|Winetricks - Wine helper|winetricks"
  )
  options=()
  for app in "${apps[@]}"; do
    IFS='|' read -r id desc bin <<< "$app"
    if is_installed "$bin"; then
      options+=("$id" "$desc [installed]" OFF)
    else
      options+=("$id" "$desc" OFF)
    fi
  done

  selected=$(whiptail --title "Optional GUI applications" --separate-output \
    --checklist "Space to select, Enter to confirm:" 19 70 9 \
    "${options[@]}" 3>&1 1>&2 2>&3) || selected=""

  for id in $selected; do
    echo "--> Installing $id..."
    "install_$id" || echo "!! $id failed to install, continuing"
  done
else
  echo 'No graphical environment detected: skipping optional GUI applications.'
fi
