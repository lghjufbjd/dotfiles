#!/bin/bash
set -e

PACKAGES=( "neovim" "bemenu" "wdisplays" "zsh" "zsh-syntax-highlighting" "zsh-autosuggestions" "thunar" "zathura" "zathura-pdf-mupdf" "chromium" "firefox" "wl-clipboard" "fastfetch" "grim" "imv" "slurp" "tesseract" "tesseract-langpack-pol" "tesseract-langpack-eng" "ImageMagick" "fuse" "fuse-libs" "tmux" "jetbrains-mono-fonts" "jq" "materia-gtk-theme" "adwaita-icon-theme" "meson" "ninja-build" "gcc" "gcc-c++" "pkg-config" "make" "wayland-devel" "wayland-protocols-devel" "libdrm-devel" "libinput-devel" "libxkbcommon-devel" "systemd-devel" "pixman-devel" "libX11-devel" "libXrandr-devel" "libxcb-devel" "xcb-util-devel" "xcb-util-wm-devel" "xcb-util-image-devel" "xcb-util-keysyms-devel" "xcb-util-renderutil-devel" "git" "xorg-x11-server-Xorg" "xorg-x11-xauth" "xdpyinfo" "foot" "wmenu" "playerctl" "brightnessctl" "swaylock" "swayidle" "kanshi" "wlr-randr" "ripgrep" "fzf" "firewalld" "fail2ban" "audit" "dnscrypt-proxy" "qemu-kvm" "libvirt" "virt-manager" "snapper" "pass" "docker" "nodejs" "npm" "java-11-openjdk" "golang" "python3-psutil" "nm-connection-editor" "network-manager-applet")

sudo dnf update -y || { echo "Failed to update system packages"; exit 1; }
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || echo "RPM Fusion may already be installed"
sudo dnf install -y @development-tools || sudo dnf group install -y "C Development Tools and Libraries" || { echo "Failed to install development tools"; exit 1; }
sudo dnf install -y git rust cargo systemd-devel libudev-devel pkg-config make scdoc || { echo "Failed to install development packages"; exit 1; }
sudo dnf install -y "${PACKAGES[@]}" || { echo "Failed to install main packages"; exit 1; }

sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --set-default-zone=home
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo systemctl enable auditd
sudo systemctl start auditd
sudo systemctl enable dnscrypt-proxy
sudo systemctl start dnscrypt-proxy
sudo systemctl disable abrt-journal-core
sudo systemctl disable abrt-oops
sudo systemctl disable abrt-xorg
sudo systemctl disable abrtd
sudo dnf install -y dnf-automatic
sudo systemctl enable dnf-automatic.timer
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
echo "* soft core 0" | sudo tee -a /etc/security/limits.conf
echo "* hard core 0" | sudo tee -a /etc/security/limits.conf
echo "net.ipv4.tcp_syncookies = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/wheel

sudo systemctl enable libvirtd
sudo systemctl start libvirtd
sudo usermod -a -G libvirt $USER
mkdir -p "$HOME/VMs"

mkdir -p "$HOME/backups"

sudo snapper create-config /
sudo snapper create-config /home
sudo systemctl enable snapper-timeline.timer
sudo systemctl enable snapper-cleanup.timer
sudo systemctl start snapper-timeline.timer
sudo systemctl start snapper-cleanup.timer

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -a -G docker $USER

mkdir -p "$HOME/.password-store"
mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

export INSTALL=/usr/bin/install
rm -rf wlroots dwl-0.7
git clone https://gitlab.freedesktop.org/wlroots/wlroots.git
cd wlroots
git checkout -f 0.18.1
meson setup build
ninja -C build
sudo ninja -C build install
echo "/usr/local/lib64" | sudo tee /etc/ld.so.conf.d/wlroots.conf >/dev/null
sudo ldconfig
cd ..

curl -L -o dwl-v0.7.tar.gz https://codeberg.org/dwl/dwl/archive/v0.7.tar.gz
tar xf dwl-v0.7.tar.gz
cd dwl

curl -L -o swallow.patch https://codeberg.org/dwl/dwl-patches/raw/branch/main/patches/swallow/swallow.patch
if patch -p1 < swallow.patch; then
    echo "Swallow patch applied"
else
    echo "Swallow patch failed to apply, continuing without it"
fi

curl -L -o unclutter.patch https://codeberg.org/dwl/dwl-patches/raw/branch/main/patches/unclutter/unclutter.patch
if patch -p1 < unclutter.patch; then
    echo "Unclutter patch applied"
else
    echo "Unclutter patch failed to apply, continuing without it"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.config/dwl/config.h" ]]; then
    cp "$SCRIPT_DIR/.config/dwl/config.h" ./config.h
    echo "Using custom dwl configuration"
else
    echo "Using default dwl configuration"
fi

make clean || true
make VERSION=0.7 dwl
test -f ./dwl
sudo $INSTALL -Dm755 ./dwl /usr/local/bin/dwl
cd ..
rm -rf wlroots dwl dwl-v0.7.tar.gz

mkdir -p "$HOME/.local/bin"
if [[ -d "$SCRIPT_DIR/.config" ]]; then
    cp -r "$SCRIPT_DIR/.config"/* "$HOME/.config/" 2>/dev/null || { echo "Failed to copy configuration files"; exit 1; }
else
    echo "Failed: .config directory not found at $SCRIPT_DIR/.config"
    exit 1
fi

if [[ -d "$SCRIPT_DIR" ]]; then
    cp -r "$SCRIPT_DIR"/* "$HOME/" 2>/dev/null || { echo "Failed to copy home directory files"; exit 1; }
fi

if [[ -d "$SCRIPT_DIR/.bin" ]]; then
    cp -r "$SCRIPT_DIR/.bin"/* "$HOME/.local/bin/" 2>/dev/null || { echo "Failed to copy binary files"; exit 1; }
    chmod +x "$HOME/.local/bin/"* 2>/dev/null || echo "Could not set executable permissions"
else
    echo "Failed: .bin directory not found at $SCRIPT_DIR/.bin"
    exit 1
fi

gsettings set org.gnome.desktop.interface gtk-theme 'Materia-dark' 2>/dev/null || echo "Could not set GTK theme"
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || echo "Could not set icon theme"

LOGIN_MANAGERS=("gdm" "sddm" "lightdm" "lxdm" "slim" "xdm" "nodm")
for dm in "${LOGIN_MANAGERS[@]}"; do
    if systemctl is-enabled "$dm" &>/dev/null; then
        echo "Disabling $dm..."
        sudo systemctl disable "$dm" || echo "Could not disable $dm"
        sudo systemctl stop "$dm" 2>/dev/null || echo "Could not stop $dm"
    fi
done

sudo systemctl set-default multi-user.target || { echo "Failed to set default target"; exit 1; }
sudo chsh -s /bin/zsh "$USER" || echo "Could not set zsh as default shell"

if command -v fc-cache &> /dev/null; then
    fc-cache -fv || echo "Could not refresh font cache"
else
    echo "fc-cache not available"
fi

echo "Installation completed!"
start-dwl