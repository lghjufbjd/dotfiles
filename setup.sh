#!/bin/bash

LOG_FILE="$HOME/dotfiles-install.log"
exec &> >(tee "$LOG_FILE")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEDORA_ISO_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/39/Spins/x86_64/iso/Fedora-Sway-Live-x86_64-39-1.5.iso"
WINDOWS_ISO_URL=""
FEDORA_ISO="$HOME/VMs/Fedora-Sway-Live-x86_64.iso"
WINDOWS_ISO="$HOME/VMs/Win11.iso"
sudo dnf install -y git || echo "[ERROR] Git installation failed"

if [[ ! -d "$SCRIPT_DIR/.config" ]] || [[ ! -d "$SCRIPT_DIR/.bin" ]]; then
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://github.com/lghjufbjd/dotfiles.git
    cd dotfiles
    SCRIPT_DIR="$(pwd)"
fi

PACKAGES=("bemenu" "wdisplays" "zsh" "librewolf" "zsh-syntax-highlighting" "zsh-autosuggestions" "thunar" "zathura" "zathura-pdf-mupdf" "firefox" "chromium" "wl-clipboard" "fastfetch" "grim" "imv" "slurp" "tesseract" "tesseract-langpack-pol" "tesseract-langpack-eng" "ImageMagick" "fuse" "fuse-libs" "tmux" "jetbrains-mono-fonts" "jq" "materia-gtk-theme" "adwaita-icon-theme" "meson" "ninja-build" "gcc" "gcc-c++" "pkgconf" "make" "wayland-devel" "wayland-protocols-devel" "libdrm-devel" "libinput-devel" "libxkbcommon-devel" "systemd-devel" "pixman-devel" "libX11-devel" "libXrandr-devel" "libxcb-devel" "xcb-util-devel" "xcb-util-wm-devel" "xcb-util-image-devel" "xcb-util-keysyms-devel" "xcb-util-renderutil-devel" "git" "xorg-x11-server-Xorg" "xorg-x11-xauth" "xdpyinfo" "foot" "wmenu" "playerctl" "brightnessctl" "swaylock" "swayidle" "kanshi" "wlr-randr" "ripgrep" "fzf" "firewalld" "fail2ban" "audit" "dnscrypt-proxy" "qemu-kvm" "libvirt" "virt-manager" "virt-install" "snapper" "pass" "docker" "nodejs" "npm" "java-11-openjdk" "golang" "python3-psutil" "nm-connection-editor" "network-manager-applet" "mako" "file-roller" "mpv")
DEPS=("meson" "ninja-build" "cmake" "gcc" "gcc-c++" "pkgconf" "make" "git" "rust" "cargo" "scdoc" "wayland-devel" "wayland-protocols-devel" "libdrm-devel" "libxkbcommon-devel" "pixman-devel" "systemd-devel" "mesa-libgbm-devel" "libgbm" "libdisplay-info-devel" "libliftoff-devel" "mesa-libEGL-devel" "mesa-libGLES-devel" "vulkan-devel" "vulkan-loader" "glslang" "libinput-devel" "libinput" "libudev-devel" "systemd-udev" "libseat-devel" "mesa-dri-drivers" "mesa-vulkan-drivers")

sudo dnf update -y || echo "[ERROR] DNF update failed"
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || echo "[ERROR] RPM Fusion installation failed"
sudo dnf install -y @development-tools || echo "[ERROR] Development tools installation failed"
curl -fsSL https://repo.librewolf.net/librewolf.repo | sudo tee /etc/yum.repos.d/librewolf.repo || echo "[ERROR] LibreWolf repo setup failed"
sudo dnf install -y "${DEPS[@]}" "${PACKAGES[@]}" || echo "[ERROR] Package installation failed"

NVIM_URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
curl -L -o /tmp/nvim-nightly.tar.gz "$NVIM_URL" || echo "[ERROR] Neovim download failed"
sudo tar xzf /tmp/nvim-nightly.tar.gz -C /usr/local --strip-components=1 || echo "[ERROR] Neovim extraction failed"
rm /tmp/nvim-nightly.tar.gz || echo "[ERROR] Neovim cleanup failed"

sudo systemctl enable --now firewalld || echo "[ERROR] Firewalld enable failed"
sudo firewall-cmd --set-default-zone=home || echo "[ERROR] Firewall zone setup failed"
sudo firewall-cmd --add-service=ssh --permanent || echo "[ERROR] Firewall SSH service addition failed"
sudo firewall-cmd --reload || echo "[ERROR] Firewall reload failed"
sudo systemctl enable --now fail2ban || echo "[ERROR] Fail2ban enable failed"
sudo systemctl enable --now auditd || echo "[ERROR] Auditd enable failed"
sudo systemctl enable --now dnscrypt-proxy || echo "[ERROR] Dnscrypt-proxy enable failed"
sudo dnf install -y dnf-automatic || echo "[ERROR] DNF automatic installation failed"
sudo systemctl enable dnf-automatic.timer || echo "[ERROR] DNF automatic timer enable failed"
echo "* soft core 0" | sudo tee -a /etc/security/limits.conf
echo "* hard core 0" | sudo tee -a /etc/security/limits.conf
echo "net.ipv4.tcp_syncookies = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p || echo "[ERROR] Sysctl reload failed"
mkdir -p "$HOME/.ssh" || echo "[ERROR] SSH directory creation failed"
chmod 700 "$HOME/.ssh" || echo "[ERROR] SSH directory permissions setup failed"
echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/wheel || echo "[ERROR] Sudoers configuration failed"

sudo systemctl enable --now libvirtd || echo "[ERROR] Libvirtd enable failed"
sudo usermod -a -G libvirt $USER || echo "[ERROR] Libvirt group addition failed"
mkdir -p "$HOME/VMs" || echo "[ERROR] VMs directory creation failed"


curl -L -o "$FEDORA_ISO" "$FEDORA_ISO_URL" || echo "[ERROR] Failed to download Fedora ISO"

virt-install \
    --name "fedora-sway" \
    --ram 2048 \
    --vcpus 2 \
    --disk path="$HOME/VMs/fedora-sway.qcow2",size=20 \
    --cdrom "$FEDORA_ISO" \
    --os-variant fedora39 \
    --network default \
    --graphics spice,listen=127.0.0.1 \
    --noautoconsole \
    --boot cdrom,hd || echo "[ERROR] Failed to create Fedora VM"


if [ "$WINDOWS_ISO_URL" != "" ]; then
  curl -L -o "$WINDOWS_ISO" "$WINDOWS_ISO_URL" || echo "[ERROR] Failed to download Windows ISO"
  virt-install \
      --name "windows-11" \
      --ram 4096 \
      --vcpus 4 \
      --disk path="$HOME/VMs/windows-11.qcow2",size=50 \
      --cdrom "$WINDOWS_ISO" \
      --os-variant win11 \
      --network default \
      --features hyperv=on \
      --graphics spice,listen=127.0.0.1 \
      --noautoconsole \
      --boot cdrom,hd || echo "[ERROR] Failed to create Windows VM"
fi

mkdir -p "$HOME/backups" || echo "[ERROR] Backups directory creation failed"

sudo systemctl enable --now snapper-timeline.timer || echo "[ERROR] Snapper timeline enable failed"
sudo systemctl enable --now snapper-cleanup.timer || echo "[ERROR] Snapper cleanup enable failed"

sudo systemctl enable --now docker || echo "[ERROR] Docker enable failed"
sudo usermod -aG docker $USER || echo "[ERROR] Docker group addition failed"

for group in video input render seat; do
    getent group "$group" >/dev/null 2>&1 && sudo usermod -aG "$group" "$USER" || true
done
sudo systemctl enable --now systemd-logind || echo "[ERROR] Systemd-logind enable failed"

mkdir -p "$HOME/.password-store" || echo "[ERROR] Password-store directory creation failed"
mkdir -p "$HOME/.gnupg" || echo "[ERROR] GnuPG directory creation failed"
chmod 700 "$HOME/.gnupg" || echo "[ERROR] GnuPG directory permissions setup failed"

export NVM_DIR="$HOME/.nvm"

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash || echo "[ERROR] nvm installation failed"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export INSTALL=/usr/bin/install
rm -rf wlroots dwl dwl-v0.7.tar.gz

sudo mkdir -p /usr/share/pkgconfig || echo "[ERROR] Pkgconfig directory creation failed"
sudo tee /usr/share/pkgconfig/hwdata.pc > /dev/null <<EOF || echo "[ERROR] Hwdata pkgconfig creation failed"
prefix=/usr
datadir=\${prefix}/share
pkgdatadir=\${datadir}/hwdata

Name: hwdata
Description: Hardware identification and configuration data
Version: 0.377
EOF

git clone https://gitlab.freedesktop.org/wlroots/wlroots.git || echo "[ERROR] Wlroots clone failed"
cd wlroots || echo "[ERROR] Failed to enter wlroots directory"
git checkout -f 0.18.1 || echo "[ERROR] Wlroots checkout failed"
meson setup build || echo "[ERROR] Wlroots meson setup failed"
ninja -C build || echo "[ERROR] Wlroots build failed"
sudo ninja -C build install || echo "[ERROR] Wlroots install failed"
echo "/usr/local/lib64" | sudo tee /etc/ld.so.conf.d/wlroots.conf >/dev/null || echo "[ERROR] Wlroots ld.so.conf setup failed"
sudo ldconfig || echo "[ERROR] Ldconfig failed"
cd .. || echo "[ERROR] Failed to return to parent directory"

curl -L -o dwl-v0.7.tar.gz https://codeberg.org/dwl/dwl/archive/v0.7.tar.gz || echo "[ERROR] DWL download failed"
tar xf dwl-v0.7.tar.gz || echo "[ERROR] DWL extraction failed"
cd dwl || echo "[ERROR] Failed to enter dwl directory"

curl -L -o unclutter.patch https://codeberg.org/dwl/dwl-patches/raw/commit/5453b7407535a7c7e079048c768979857b27d0ed/patches/unclutter/unclutter.patch && patch -p1 < unclutter.patch || { echo "[ERROR] Unclutter patch failed"; git reset --hard HEAD; }

curl -L -o swallow.patch https://codeberg.org/dwl/dwl-patches/raw/commit/5453b7407535a7c7e079048c768979857b27d0ed/patches/swallow/swallow.patch && patch -p1 < swallow.patch || { echo "[ERROR] Swallow patch failed"; git reset --hard HEAD; }

curl -L -o autostart.patch https://codeberg.org/dwl/dwl-patches/raw/commit/5453b7407535a7c7e079048c768979857b27d0ed/patches/autostart/autostart.patch && patch -p1 < autostart.patch || { echo "[ERROR] Autostart patch failed"; git reset --hard HEAD; }

curl -L -o alwayscenter.patch https://codeberg.org/dwl/dwl-patches/raw/commit/5453b7407535a7c7e079048c768979857b27d0ed/patches/alwayscenter/alwayscenter.patch && patch -p1 < alwayscenter.patch || { echo "[ERROR] Alwayscenter patch failed"; git reset --hard HEAD; }

cp "$SCRIPT_DIR/.config/dwl/config.h" ./config.h || echo "[ERROR] DWL config copy failed"

make clean || echo "[ERROR] Make clean skipped (nothing to clean)"
make VERSION=0.7 dwl || echo "[ERROR] DWL build failed"
test -f ./dwl || echo "[ERROR] DWL binary not found"
sudo $INSTALL -Dm755 ./dwl /usr/local/bin/dwl || echo "[ERROR] DWL installation failed"
cd || echo "[ERROR] Failed to change to home directory"
rm -rf wlroots dwl dwl-v0.7.tar.gz || echo "[ERROR] DWL cleanup failed"

mkdir -p "$HOME/.local/bin" || echo "[ERROR] Local bin directory creation failed"
cp -r "$SCRIPT_DIR/.config"/* "$HOME/.config/" || echo "[ERROR] Config files copy failed"
cp -r "$SCRIPT_DIR/.bin"/* "$HOME/.local/bin/" || echo "[ERROR] Bin files copy failed"
chmod +x "$HOME/.local/bin/"* || echo "[ERROR] Bin files chmod failed"
cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc" || echo "[ERROR] Zshrc copy failed"

mkdir -p "$HOME/.config/gtk-3.0" || echo "[ERROR] GTK-3.0 config directory creation failed"
cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF || echo "[ERROR] GTK-3.0 settings write failed"
[Settings]
gtk-theme-name=Materia-dark
gtk-icon-theme-name=Adwaita
gtk-application-prefer-dark-theme=true
EOF

mkdir -p "$HOME/.config/gtk-4.0" || echo "[ERROR] GTK-4.0 config directory creation failed"
cat > "$HOME/.config/gtk-4.0/settings.ini" <<EOF || echo "[ERROR] GTK-4.0 settings write failed"
[Settings]
gtk-theme-name=Materia-dark
gtk-icon-theme-name=Adwaita
gtk-application-prefer-dark-theme=true
EOF

echo "Configuring XDG default applications..."

xdg-settings set default-web-browser librewolf.desktop || echo "[ERROR] XDG set default browser failed"
xdg-mime default librewolf.desktop x-scheme-handler/http || echo "[ERROR] XDG mime http handler failed"
xdg-mime default librewolf.desktop x-scheme-handler/https || echo "[ERROR] XDG mime https handler failed"
xdg-mime default librewolf.desktop text/html || echo "[ERROR] XDG mime text/html handler failed"

xdg-mime default foot.desktop x-scheme-handler/terminal || echo "[ERROR] XDG mime terminal handler failed"

xdg-mime default thunar.desktop inode/directory || echo "[ERROR] XDG mime directory handler failed"

mkdir -p "$HOME/.local/share/applications" || echo "[ERROR] Applications directory creation failed"
cat > "$HOME/.local/share/applications/nvim.desktop" <<EOF || echo "[ERROR] Neovim desktop file creation failed"
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
xdg-mime default nvim.desktop text/plain || echo "[ERROR] XDG mime text editor failed"
xdg-mime default nvim.desktop text/x-shellscript || echo "[ERROR] XDG mime shellscript handler failed"
xdg-mime default nvim.desktop text/x-python || echo "[ERROR] XDG mime python handler failed"

xdg-mime default org.pwmt.zathura.desktop application/pdf || echo "[ERROR] XDG mime PDF handler failed"

for type in image/jpeg image/png image/gif image/bmp image/webp image/svg+xml image/tiff; do
    xdg-mime default imv.desktop "$type" 2>/dev/null || echo "[ERROR] XDG mime $type handler failed"
done

for type in video/mp4 video/x-matroska video/webm video/mpeg video/x-msvideo video/quicktime video/x-flv; do
    xdg-mime default mpv.desktop "$type" 2>/dev/null || echo "[ERROR] XDG mime $type handler failed"
done

for type in audio/mpeg audio/ogg audio/flac audio/x-wav audio/x-m4a audio/aac; do
    xdg-mime default mpv.desktop "$type" 2>/dev/null || echo "[ERROR] XDG mime $type handler failed"
done

for type in application/zip application/x-tar application/gzip application/x-bzip application/x-7z-compressed application/x-rar application/x-xz; do
    xdg-mime default org.gnome.FileRoller.desktop "$type" 2>/dev/null || echo "[ERROR] XDG mime $type handler failed"
done

echo "XDG defaults configured successfully"

sudo systemctl disable "sddm" 2>/dev/null || echo "[ERROR] SDDM disable skipped (not installed)"
sudo systemctl stop "sddm" 2>/dev/null || echo "[ERROR] SDDM stop skipped (not running)" 

sudo systemctl set-default multi-user.target || echo "[ERROR] Set default target failed"

fc-cache -fv || echo "[ERROR] Font cache refresh failed"

printf '%s\n' "" "Installation completed! Log: $LOG_FILE" "Inspect errors: grep '^\[ERROR\]' $LOG_FILE" "" "IMPORTANT: LOGOUT and LOGIN for group changes to take effect!" "" "SETUP REQUIRED:" "  1. gpg --full-generate-key" "  2. pass init your-email@example.com" "" "Start DWL: start-dwl" ""

sudo chsh -s /bin/zsh "$USER" || echo "[ERROR] Shell change to zsh failed"