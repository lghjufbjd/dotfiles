#!/bin/bash

set -e 
LOG_FILE="$HOME/dotfiles-install.log"
exec &> >(tee "$LOG_FILE")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set +e
sudo dnf install -y git
set -e

if [[ ! -d "$SCRIPT_DIR/.config" ]] || [[ ! -d "$SCRIPT_DIR/.bin" ]]; then
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://github.com/lghjufbjd/dotfiles.git
    cd dotfiles
    SCRIPT_DIR="$(pwd)"
fi

PACKAGES=(
    "bemenu" "wdisplays" "zsh" "zsh-syntax-highlighting" "zsh-autosuggestions" 
    "thunar" "zathura" "zathura-pdf-mupdf" "firefox" "chromium" 
    "wl-clipboard" "fastfetch" "grim" "imv" "slurp" 
    "tesseract" "tesseract-langpack-pol" "tesseract-langpack-eng" 
    "ImageMagick" "fuse" "fuse-libs" "tmux" "jetbrains-mono-fonts" 
    "jq" "materia-gtk-theme" "adwaita-icon-theme"
    "qt5ct" "qt6ct" "kvantum" "kvantum-qt5" "qgnomeplatform-qt5" "qgnomeplatform-qt6"
    "foot" "playerctl" "brightnessctl" 
    "swaylock" "swayidle" "kanshi" "wlr-randr" 
    "ripgrep" "fzf" "firewalld" "audit" "pass"
    "nodejs" "npm" "golang" "python3-psutil" 
    "nm-connection-editor" "network-manager-applet" 
    "mako" "file-roller" "mpv"
    "java-latest-openjdk" "librewolf"
    "qemu-kvm" "libvirt" "virt-manager" "virt-install"
    "fail2ban" "dnscrypt-proxy" "snapper" "moby-engine"
)

BUILD_DEPS=(
    "meson" "ninja-build" "cmake" "gcc" "gcc-c++" 
    "pkgconf" "make" "git" "rust" "cargo" "scdoc"
    "wayland-devel" "wayland-protocols-devel" 
    "libdrm-devel" "libxkbcommon-devel" "pixman-devel" 
    "systemd-devel" "mesa-libgbm-devel" "libgbm" 
    "libdisplay-info-devel" "libliftoff-devel" 
    "mesa-libEGL-devel" "mesa-libGLES-devel" 
    "vulkan-devel" "vulkan-loader" "glslang" 
    "libinput-devel" "libinput" "libudev-devel" 
    "systemd-udev" "libseat-devel" 
    "mesa-dri-drivers" "mesa-vulkan-drivers"
    "libX11-devel" "libXrandr-devel" "libxcb-devel" 
    "xcb-util-devel" "xcb-util-wm-devel" "xcb-util-image-devel"
    "xcb-util-keysyms-devel" "xcb-util-renderutil-devel" "xcb-util-errors-devel"
    "xorg-x11-server-Xorg" "xorg-x11-xauth" "xdpyinfo" "xorg-x11-server-Xwayland-devel"
    "lcms2-devel"
)

echo "==> Updating system..."
sudo dnf update -y

echo "==> Installing RPM Fusion repositories..."
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

echo "==> Installing Development Tools group..."
sudo dnf install -y @development-tools

echo "==> Adding LibreWolf repository..."
set +e
curl -fsSL https://repo.librewolf.net/librewolf.repo | sudo tee /etc/yum.repos.d/librewolf.repo
set -e

echo "==> Installing build dependencies..."
sudo dnf install -y "${BUILD_DEPS[@]}"

echo "==> Installing packages..."
sudo dnf install -y "${PACKAGES[@]}"


echo "==> Downloading Neovim nightly..."
NVIM_URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
curl -L -o /tmp/nvim-nightly.tar.gz "$NVIM_URL"
sudo tar xzf /tmp/nvim-nightly.tar.gz -C /usr/local --strip-components=1
rm /tmp/nvim-nightly.tar.gz

echo "==> Configuring firewall..."
sudo systemctl enable --now firewalld
sudo firewall-cmd --set-default-zone=home
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload

echo "==> Enabling audit daemon..."
sudo systemctl enable --now auditd

echo "==> Installing and enabling DNF automatic updates..."
sudo dnf install -y dnf5-plugin-automatic
sudo systemctl enable dnf-automatic.timer

echo "==> Configuring security limits..."
echo "* soft core 0" | sudo tee -a /etc/security/limits.conf
echo "* hard core 0" | sudo tee -a /etc/security/limits.conf

echo "==> Configuring kernel parameters..."
echo "net.ipv4.tcp_syncookies = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "==> Setting up SSH directory..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

echo "==> Configuring sudoers..."
echo '%wheel ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/wheel

echo "==> Enabling services..."
sudo systemctl enable --now fail2ban
sudo systemctl enable --now dnscrypt-proxy
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
sudo systemctl enable --now libvirtd
sudo usermod -a -G libvirt $USER
mkdir -p "$HOME/VMs"

echo "==> Adding user to video/input/render/seat groups..."
for group in video input render seat; do
    getent group "$group" >/dev/null 2>&1 && sudo usermod -aG "$group" "$USER" || true
done

echo "==> Enabling systemd-logind..."
sudo systemctl enable --now systemd-logind

echo "==> Setting up password store and GPG..."
mkdir -p "$HOME/.password-store"
mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

echo "==> Installing NVM..."
export NVM_DIR="$HOME/.nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo "==> Building wlroots from source..."
export INSTALL=/usr/bin/install
cd "$HOME"
rm -rf wlroots dwl dwl-v0.7.tar.gz

sudo mkdir -p /usr/share/pkgconfig
sudo tee /usr/share/pkgconfig/hwdata.pc > /dev/null <<'EOF'
prefix=/usr
datadir=${prefix}/share
pkgdatadir=${datadir}/hwdata

Name: hwdata
Description: Hardware identification and configuration data
Version: 0.377
EOF

git clone https://gitlab.freedesktop.org/wlroots/wlroots.git
cd wlroots
git checkout -f 0.18.1
meson setup build 
ninja -C build
sudo ninja -C build install
echo "/usr/local/lib64" | sudo tee /etc/ld.so.conf.d/wlroots.conf >/dev/null
sudo ldconfig
cd ..

echo "==> Building DWL window manager "
curl -L -o dwl-v0.7.tar.gz https://codeberg.org/dwl/dwl/archive/v0.7.tar.gz
tar xf dwl-v0.7.tar.gz
cd dwl

curl -L -o unclutter.patch https://codeberg.org/dwl/dwl-patches/raw/commit/5453b7407535a7c7e079048c768979857b27d0ed/patches/unclutter/unclutter.patch
patch -p1 < unclutter.patch

curl -L -o swallow.patch https://codeberg.org/dwl/dwl-patches/raw/commit/5453b7407535a7c7e079048c768979857b27d0ed/patches/swallow/swallow.patch
patch -p1 < swallow.patch

curl -L -o autostart.patch https://codeberg.org/dwl/dwl-patches/raw/commit/5453b7407535a7c7e079048c768979857b27d0ed/patches/autostart/autostart.patch
patch -p1 < autostart.patch

curl -L -o alwayscenter.patch https://codeberg.org/dwl/dwl-patches/raw/commit/5453b7407535a7c7e079048c768979857b27d0ed/patches/alwayscenter/alwayscenter.patch
patch -p1 < alwayscenter.patch

cp "$SCRIPT_DIR/.config/dwl/config.h" ./config.h

make clean || true
make VERSION=0.7 dwl
sudo $INSTALL -Dm755 ./dwl /usr/local/bin/dwl

cd "$HOME"
rm -rf wlroots dwl dwl-v0.7.tar.gz

echo "==> Installing dotfiles..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config"
cp -r "$SCRIPT_DIR/.config"/* "$HOME/.config/"
cp -r "$SCRIPT_DIR/.bin"/* "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/"*
cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

echo "==> Configuring XDG default applications..."
set +e
xdg-settings set default-web-browser librewolf.desktop || xdg-settings set default-web-browser firefox.desktop
xdg-mime default librewolf.desktop x-scheme-handler/http || xdg-mime default firefox.desktop x-scheme-handler/http
xdg-mime default librewolf.desktop x-scheme-handler/https || xdg-mime default firefox.desktop x-scheme-handler/https
xdg-mime default librewolf.desktop text/html || xdg-mime default firefox.desktop text/html
set -e

xdg-mime default foot.desktop x-scheme-handler/terminal || true
xdg-mime default thunar.desktop inode/directory

mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/nvim.desktop" <<'EOF'
[Desktop Entry]
Name=Neovim
GenericName=Text Editor
Comment=Edit text files
Exec=foot -e nvim %F
Terminal=false
Type=Application
Icon=nvim
Categories=Utility;TextEditor;
MimeType=text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
EOF

xdg-mime default nvim.desktop text/plain
xdg-mime default nvim.desktop text/x-shellscript || true
xdg-mime default nvim.desktop text/x-python || true
xdg-mime default org.pwmt.zathura.desktop application/pdf || true

for type in image/jpeg image/png image/gif image/bmp image/webp image/svg+xml image/tiff; do
    xdg-mime default imv.desktop "$type" 2>/dev/null || true
done

for type in video/mp4 video/x-matroska video/webm video/mpeg video/x-msvideo video/quicktime video/x-flv; do
    xdg-mime default mpv.desktop "$type" 2>/dev/null || true
done

for type in audio/mpeg audio/ogg audio/flac audio/x-wav audio/x-m4a audio/aac; do
    xdg-mime default mpv.desktop "$type" 2>/dev/null || true
done

for type in application/zip application/x-tar application/gzip application/x-bzip application/x-7z-compressed application/x-rar application/x-xz; do
    xdg-mime default org.gnome.FileRoller.desktop "$type" 2>/dev/null || true
done

echo "==> Disabling display managers..."
set +e
sudo systemctl disable sddm 2>/dev/null || true
sudo systemctl stop sddm 2>/dev/null || true
set -e

echo "==> Setting default target to multi-user..."
sudo systemctl set-default multi-user.target

echo "==> Refreshing font cache..."
fc-cache -fv

echo "==> Creating backup directory..."
mkdir -p "$HOME/backups"

echo "==> Changing default shell to zsh..."
sudo chsh -s /usr/bin/zsh "$USER"

printf '%s\n' \
    "" \
    "============================================" \
    "Installation completed successfully!" \
    "============================================" \
    "" \
    "Log file: $LOG_FILE" \
    "" \
    "IMPORTANT: LOGOUT and LOGIN for changes to take effect!" \
    "" \
    "SETUP REQUIRED:" \
    "  1. gpg --full-generate-key" \
    "  2. pass init your-email@example.com" \
    "" \
    "To start DWL: dwl" 
