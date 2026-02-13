#!/bin/bash

# base vars
DESKTOP_USER=che
HOST_NAME=greenzard
BASH_LIBRARY_COMMON=/home/$DESKTOP_USER/lib/sh/common.sh
STEAM_LOCAL_LIBRARY=/home/$DESKTOP_USER/lib/steam/
WORKDIR="$(mktemp -d)"
GO_DIR_CACHE=$WORKDIR/cache
GO_DIR_BIN=$WORKDIR/bin
PAPIRUS_THEME_DIR=/usr/share/icons/Papirus
CURL_PARAMS="--silent --show-error --location"

# load common functions
if [ -f $BASH_LIBRARY_COMMON ]; then
    source $BASH_LIBRARY_COMMON
else
    echo "Failed to load common shell library."
    exit 1
fi

mkdir -p $STEAM_LOCAL_LIBRARY $GO_DIR_CACHE $GO_DIR_BIN || true

# package manager variables
CODIUM_LOCAL_REPO_PATH=/etc/zypp/repos.d/vscodium.repo
KUBERNETES_LOCAL_REPO_PATH=/etc/zypp/repos.d/kubernetes.repo
OPENTOFU_LOCAL_REPO_PATH=/etc/zypp/repos.d/opentofu.repo
NVIDIA_LOCAL_REPO_PATH=/etc/zypp/repos.d/nvidia.repo
PACKMAN_LOCAL_REPO_PATH=/etc/zypp/repos.d/packman.repo
MS_EDGE_LOCAL_REPO_PATH=/etc/zypp/repos.d/microsoft-edge.repo
KUBERNETES_STABLE_VERSION_MINOR=$(curl $CURL_PARAMS https://dl.k8s.io/release/stable.txt | awk -F '.' '{print $1"."$2}')
ZYPPER_PARAMS_QUIET="--non-interactive --quiet"
ZYPPER_INSTALL_PARAMS_BASE="--no-recommends"
ZYPPER_INSTALL_PARAMS_CLOSED_SOURCE="$ZYPPER_INSTALL_PARAMS_BASE --auto-agree-with-licenses"
FLATPAK_PARAMS_QUIET="--assumeyes --noninteractive flathub"
FLATPAK_PACKAGES=(
    com.valvesoftware.Steam
    io.dbeaver.DBeaverCommunity
    tv.kodi.Kodi
    com.slack.Slack
    com.jgraph.drawio.desktop
    us.zoom.Zoom
    org.videolan.VLC
    com.mikrotik.WinBox
    com.discordapp.Discord
    org.onlyoffice.desktopeditors
    org.telegram.desktop
    com.github.tchx84.Flatseal
    org.qbittorrent.qBittorrent
)
# other vars
NVIDIA_DRIVER_DRACUT_CONFIG_PATH=/etc/dracut.conf.d/99-nvidia.conf
OGG_CODEC_NAME="libogg"
OGG_CODEC_VERSION="1.3.6"
OGG_CODEC_ARCHIVE_NAME="$OGG_CODEC_NAME-$OGG_CODEC_VERSION.tar.xz"
OGG_CODEC_DOWNLOAD_URL="https://ftp.osuosl.org/pub/xiph/releases/ogg/$OGG_CODEC_ARCHIVE_NAME"
VORBIS_CODEC_NAME="libvorbis"
VORBIS_CODEC_VERSION="1.3.7"
VORBIS_CODEC_ARCHIVE_NAME="$VORBIS_CODEC_NAME-$VORBIS_CODEC_VERSION.tar.xz"
VORBIS_CODEC_DOWNLOAD_URL="https://ftp.osuosl.org/pub/xiph/releases/vorbis/$VORBIS_CODEC_ARCHIVE_NAME"
THEORA_CODEC_NAME="libtheora"
THEORA_CODEC_VERSION="1.2.0"
THEORA_CODEC_ARCHIVE_NAME="$THEORA_CODEC_NAME-$THEORA_CODEC_VERSION.tar.gz"
THEORA_CODEC_DOWNLOAD_URL="https://ftp.osuosl.org/pub/xiph/releases/theora/$THEORA_CODEC_ARCHIVE_NAME"

# set host information
log_message info "Setting host information..."
sudo hostnamectl set-hostname $HOST_NAME
if sudo dmesg | grep --quiet 'Hypervisor detected'; then
    CHASSIS_TYPE="vm"
else
    CHASSIS_TYPE="desktop"
fi
sudo hostnamectl set-chassis $CHASSIS_TYPE

# remove garbage packages
if systemctl list-unit-files packagekit.service &>/dev/null; then
    echo "Cleaning up PackageKit garbage..."
    sudo zypper $ZYPPER_PARAMS_QUIET remove PackageKit
fi

# install packages
sudo zypper $ZYPPER_PARAMS_QUIET update
log_message info "Installing core list of packages..."
sudo zypper $ZYPPER_PARAMS_QUIET install $ZYPPER_INSTALL_PARAMS_BASE \
    nmap mtr whois samba-client bind-utils wireshark wget \
    fastfetch neovim fira-code-fonts conky tmux htop btop steam-devices kitty starship timeshift dysk \
    k9s azure-cli \
    go go-doc rustup cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel libstartup-notification-1-0 fakeroot rpmbuild meson \
    Mesa-libEGL-devel gstreamer-devel gstreamer-plugins-bad gstreamer-plugins-bad-devel edid-decode opi libva-utils \
    docker docker-compose docker-compose-switch \
    flatpak npm \
    pcsc-ccid \
    MozillaThunderbird \
    wine libvirt virt-manager \
    strawberry audacity \
    keepassxc gimp calibre okular k3b nextcloud xorriso qimgv ImageMagick zbar

# install programs from external repos
log_message info "Installing packages from external repositories..."
sudo dd status=none of=$PACKMAN_LOCAL_REPO_PATH << EOF
[packman]
enabled=1
autorefresh=1
baseurl=https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/
priority=90
EOF
sudo dd status=none of=$CODIUM_LOCAL_REPO_PATH << EOF
[vscodium]
name=VSCodium RPM
baseurl=https://download.vscodium.com/rpms/
enabled=1
pkg_gpgcheck=1
repo_gpgcheck=1
gpgpautoimport=1
autorefresh=1
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
metadata_expire=1h
EOF
sudo dd status=none of=$KUBERNETES_LOCAL_REPO_PATH << EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_STABLE_VERSION_MINOR/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_STABLE_VERSION_MINOR/rpm/repodata/repomd.xml.key
EOF
sudo dd status=none of=$OPENTOFU_LOCAL_REPO_PATH << EOF
[opentofu]
name=opentofu
baseurl=https://packages.opentofu.org/opentofu/tofu/rpm_any/rpm_any/\$basearch
repo_gpgcheck=1
gpgcheck=1
enabled=1
gpgkey=https://get.opentofu.org/opentofu.gpg
       https://packages.opentofu.org/opentofu/tofu/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[opentofu-source]
name=opentofu-source
baseurl=https://packages.opentofu.org/opentofu/tofu/rpm_any/rpm_any/SRPMS
repo_gpgcheck=1
gpgcheck=1
enabled=1
gpgkey=https://get.opentofu.org/opentofu.gpg
       https://packages.opentofu.org/opentofu/tofu/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOF
sudo dd status=none of=$NVIDIA_LOCAL_REPO_PATH << EOF
[nvidia]
name=nvidia-opensource
baseurl=https://download.nvidia.com/opensuse/tumbleweed
enabled=1
autorefresh=1
EOF
sudo dd status=none of=$MS_EDGE_LOCAL_REPO_PATH << EOF
[microsoft-edge-stable]
name=microsoft-edge-stable
enabled=1
autorefresh=1
baseurl=https://packages.microsoft.com/yumrepos/edge
EOF
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo zypper $ZYPPER_PARAMS_QUIET --gpg-auto-import-keys refresh
sudo zypper $ZYPPER_PARAMS_QUIET update
sudo zypper $ZYPPER_PARAMS_QUIET install $ZYPPER_INSTALL_PARAMS_BASE --allow-vendor-change --from packman \
    ffmpeg \
    gstreamer-plugins-{good,bad,ugly,libav} \
    libavcodec \
    libav-tools \
    vlc-codecs
sudo zypper $ZYPPER_PARAMS_QUIET install $ZYPPER_INSTALL_PARAMS_BASE codium kubectl tofu microsoft-edge-stable
# nvidia
sudo dd status=none of=$NVIDIA_DRIVER_DRACUT_CONFIG_PATH << EOF
# early load nvidia driver
# source: https://wiki.archlinux.org/title/Dracut
force_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
EOF
sudo zypper $ZYPPER_PARAMS_QUIET install $ZYPPER_INSTALL_PARAMS_CLOSED_SOURCE nvidia-video-G06
sudo zypper $ZYPPER_PARAMS_QUIET install $ZYPPER_INSTALL_PARAMS_CLOSED_SOURCE nvidia-gl-G06 nvidia-gl-G06-32bit
sudo zypper $ZYPPER_PARAMS_QUIET install $ZYPPER_INSTALL_PARAMS_CLOSED_SOURCE nvidia-compute-G06 nvidia-compute-utils-G06
cd $WORKDIR
git clone --depth 1 https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
make
sudo make install
export PKG_CONFIG_PATH="/usr/lib/pkgconfig:$PKG_CONFIG_PATH"
cd $WORKDIR
git clone --depth 1 https://github.com/elFarto/nvidia-vaapi-driver.git
cd nvidia-vaapi-driver
meson build
ninja -C build
sudo ninja -C build install

# install programs from flathub
log_message info "Installing flatpack packages..."
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
for pak in "${FLATPAK_PACKAGES[@]}"; do
    log_message info "Installing $pak flatpak..."
    flatpak install $FLATPAK_PARAMS_QUIET $pak
done
flatpak override --user --filesystem=$STEAM_LOCAL_LIBRARY com.valvesoftware.Steam

# install rust
if which cargo &> /dev/null; then
    log_message info "Rust is already installed."
else
    log_message info "Installing rust..."
    rustup toolchain install stable
fi

# install npm packages
sudo npm install --global vscode-json-languageserver

# scripted installations
if aws --version &> /dev/null; then
    log_message info "AWS cli is already installed."
else
    cd $WORKDIR
    log_message info "Downloading latest AWS cli version..."
    curl $CURL_PARAMS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" --output "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
fi
if stat /usr/lib64/libogg.so &> /dev/null; then
    log_message info "$OGG_CODEC_NAME is already installed."
else
    cd $WORKDIR
    curl $CURL_PARAMS $OGG_CODEC_DOWNLOAD_URL --output $OGG_CODEC_ARCHIVE_NAME
    tar -xvJf "$OGG_CODEC_ARCHIVE_NAME"
    cd "$OGG_CODEC_NAME-$OGG_CODEC_VERSION"
    ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/$OGG_CODEC_NAME-$OGG_CODEC_VERSION
    make
    sudo make install
fi
if stat /usr/lib64/libvorbis.so.0 &> /dev/null; then
    log_message info "$VORBIS_CODEC_NAME is already installed."
else
    cd $WORKDIR
    curl $CURL_PARAMS $VORBIS_CODEC_DOWNLOAD_URL --output $VORBIS_CODEC_ARCHIVE_NAME
    tar -xvJf "$VORBIS_CODEC_ARCHIVE_NAME"
    cd "$VORBIS_CODEC_NAME-$VORBIS_CODEC_VERSION"
    ./configure --prefix=/usr --disable-static
    make
    sudo make install
    sudo install -v -m644 doc/Vorbis* /usr/share/doc/$VORBIS_CODEC_NAME-$VORBIS_CODEC_VERSION
fi
if stat /usr/lib64/libtheora.so &> /dev/null; then
    log_message info "$THEORA_CODEC_NAME is already installed."
else
    cd $WORKDIR
    curl $CURL_PARAMS $THEORA_CODEC_DOWNLOAD_URL --output $THEORA_CODEC_ARCHIVE_NAME
    tar -xvzf "$THEORA_CODEC_ARCHIVE_NAME"
    cd "$THEORA_CODEC_NAME-$THEORA_CODEC_VERSION"
    ./configure --prefix=/usr --disable-static
    make
    sudo make install
fi

# docker setup
sudo systemctl enable docker
sudo usermod -G docker -a $DESKTOP_USER

# golang program installations
if which rdap &> /dev/null; then
    log_message info "RDAP is already installed."
else
    log_message info "Building and installing RDAP..."
    cd $WORKDIR
    GOMODCACHE=$GO_DIR_CACHE GOBIN=$GO_DIR_BIN go install github.com/openrdap/rdap/cmd/rdap@master
    sudo cp $GO_DIR_BIN/rdap /usr/local/bin/rdap
fi

# argocd cli tool
cd $WORKDIR
curl $CURL_PARAMS https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 --output argocd
sudo install -m 555 argocd /usr/local/bin/argocd

# setup plasmoids
# BW_MONITOR_PLASMOID_NAME="NetworkBandwidthMonitorQt6.plasmoid"
# wget -O $BW_MONITOR_PLASMOID_NAME "https://ocs-dl.fra1.cdn.digitaloceanspaces.com/data/files/1744930465/NetworkBandwidthMonitorQt6-6.2025.4.20.plasmoid
# kpackagetool6 -i $BW_MONITOR_PLASMOID_NAME

if zypper search --installed-only dark-icon-theme &> /dev/null; then
    log_message info "Dark icon theme is already installed."
else
    log_message info "Building and installing dark icon theme..."
    cd $WORKDIR
    git clone --depth 1 https://gitlab.com/sixsixfive/DarK-icons.git
    cd DarK-icons
    sh build_svg.sh
    cd packaging
    sh build_rpm.sh
    sudo zypper $ZYPPER_PARAMS_QUIET install $ZYPPER_INSTALL_PARAMS_BASE --allow-unsigned-rpm dark-icon-theme*.rpm
fi

if [ -d $PAPIRUS_THEME_DIR ]; then
    log_message info "Papirus icon theme is already intalled."
else
    cd $WORKDIR
    wget -qO papirus-install https://git.io/papirus-icon-theme-install
    chmod +x papirus-install
    ./papirus-install
fi

# fonts
if ls -lah ~/.fonts/ | grep --quiet "Segoe.*ttf"; then
    log_message info "Segoe UI font is already installed."
else
    cd $WORKDIR
    curl $CURL_PARAMS https://aka.ms/SegoeUIVariable --output SegoeUI-VF.zip
    curl $CURL_PARAMS https://aka.ms/SegoeFluentIcons --output Segoe-Fluent-Icons.zip
    unzip -o SegoeUI-VF.zip
    unzip -o Segoe-Fluent-Icons.zip
    mv Segoe*ttf ~/.fonts/
    fc-cache -f -v
fi

log_message info "Please run command 'opi codecs' to install all relevant media libraries!"
echo "Please run command 'opi codecs' to install all relevant media libraries!"

# once i get gfx card with cuda
# git clone https://github.com/ggml-org/llama.cpp
# cmake llama.cpp -B llama.cpp/build -DBUILD_SHARED_LIBS=OFF -DGGML_CUDA=ON -DLLAMA_CURL=ON
# cmake --build llama.cpp/build --config Release -j --clean-first --target llama-cli llama-gguf-split
# cp llama.cpp/build/bin/llama-* llama.cpp
