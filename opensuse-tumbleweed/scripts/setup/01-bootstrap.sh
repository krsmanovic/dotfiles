#!/bin/bash

# stop packagekit while we are running cli ops
if systemctl list-unit-files packagekit.service &>/dev/null; then
    sudo systemctl stop --now packagekit
fi

# set up directories
DESKTOP_USER=che
HOST_NAME=greenzard
BASH_LIBRARY_COMMON=/home/$DESKTOP_USER/lib/sh/common.sh
STEAM_LOCAL_LIBRARY=/home/$DESKTOP_USER/lib/steam/
WORKDIR="$(mktemp -d)"
GO_DIR_CACHE=$WORKDIR/cache
GO_DIR_BIN=$WORKDIR/bin
mkdir -p $STEAM_LOCAL_LIBRARY $GO_DIR_CACHE $GO_DIR_BIN || true

# load common functions
if [ -f $BASH_LIBRARY_COMMON ]; then
    source $BASH_LIBRARY_COMMON
else
    echo "Failed to load common shell library."
    exit 1
fi

# package manager variables
CODIUM_LOCAL_REPO_PATH=/etc/zypp/repos.d/vscodium.repo
KUBERNETES_LOCAL_REPO_PATH=/etc/zypp/repos.d/kubernetes.repo
OPENTOFU_LOCAL_REPO_PATH=/etc/zypp/repos.d/opentofu.repo
NVIDIA_LOCAL_REPO_PATH=/etc/zypp/repos.d/nvidia.repo
PACKMAN_LOCAL_REPO_PATH=/etc/zypp/repos.d/packman.repo
KUBERNETES_STABLE_VERSION_MINOR=$(curl -L -s https://dl.k8s.io/release/stable.txt | awk -F '.' '{print $1"."$2}')
ZYPPER_PARAMS_QUIET="--non-interactive --quiet"
FLATPAK_PARAMS_QUIET="--assumeyes --noninteractive flathub"
FLATPAK_PACKAGES=(
    com.valvesoftware.Steam
    io.dbeaver.DBeaverCommunity
    tv.kodi.Kodi
    com.slack.Slack
    com.jgraph.drawio.desktop
    us.zoom.Zoom
    com.getpostman.Postman
    com.microsoft.Edge
    org.videolan.VLC
)

# set host information
log_message info "Setting host information..."
sudo hostnamectl set-hostname $HOST_NAME
if sudo dmesg | grep --quiet 'Hypervisor detected'; then
    CHASSIS_TYPE="vm"
else
    CHASSIS_TYPE="desktop"
fi
sudo hostnamectl set-chassis $CHASSIS_TYPE

# install packages
sudo zypper --non-interactive --quiet update
log_message info "Installing core list of packages..."
sudo zypper $ZYPPER_PARAMS_QUIET install \
    nmap mtr whois samba-client bind-utils wireshark wget \
    fastfetch neovim fira-code-fonts conky tmux htop btop steam-devices kitty starship timeshift \
    k9s aws-cli azure-cli \
    go go-doc rustup cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel libstartup-notification-1-0 fakeroot rpmbuild \
    flatpak \
    discord telegram-desktop MozillaThunderbird \
    wine virtualbox \
    deadbeef audacity \
    keepassxc gimp calibre okular k3b qbittorrent nextcloud xorriso

# install programs from external repos
log_message info "Installing packages from external repositories..."
sudo tee $PACKMAN_LOCAL_REPO_PATH > /dev/null << "EOF"
[packman]
enabled=1
autorefresh=1
baseurl=https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/
priority=90
EOF
sudo tee $CODIUM_LOCAL_REPO_PATH > /dev/null << "EOF" 
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
sudo tee $KUBERNETES_LOCAL_REPO_PATH > /dev/null << EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_STABLE_VERSION_MINOR/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_STABLE_VERSION_MINOR/rpm/repodata/repomd.xml.key
EOF
sudo tee $OPENTOFU_LOCAL_REPO_PATH > /dev/null << EOF
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
sudo tee $NVIDIA_LOCAL_REPO_PATH > /dev/null << EOF
[nvidia]
name=nvidia-opensource
baseurl=https://download.nvidia.com/opensuse/tumbleweed
enabled=1
autorefresh=1
EOF
sudo zypper $ZYPPER_PARAMS_QUIET --gpg-auto-import-keys refresh
sudo zypper $ZYPPER_PARAMS_QUIET update
sudo zypper $ZYPPER_PARAMS_QUIET install --allow-vendor-change --from packman ffmpeg gstreamer-plugins-{good,bad,ugly,libav} libavcodec vlc-codecs
sudo zypper $ZYPPER_PARAMS_QUIET install codium kubectl tofu
sudo zypper $ZYPPER_PARAMS_QUIET install --auto-agree-with-licenses nvidia-open-driver-G06-signed-kmp-default
NVIDIA_DRIVER_VERSION=$(rpm -qa --queryformat '%{VERSION}\n' nvidia-open-driver-G06-signed-kmp-default | cut -d "_" -f1 | sort -u | tail -n 1)
sudo zypper $ZYPPER_PARAMS_QUIET install nvidia-video-G06=${NVIDIA_DRIVER_VERSION} nvidia-compute-utils-G06=${NVIDIA_DRIVER_VERSION}

# install programs from flathub
log_message info "Installing flatpack packages..."
sudo tee /etc/profile.local > /dev/null << "EOF"
XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$XDG_DATA_DIRS"
XDG_DATA_HOME="/var/lib/flatpak/exports/share:$XDG_DATA_HOME"
EOF
source /etc/profile.local
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
for pak in "${FLATPAK_PACKAGES[@]}"; do
    log_message info "Installing $pak flatpak..."
    sudo -E XDG_DATA_DIRS="/root/.local/share/flatpak/exports/share:$XDG_DATA_DIRS" flatpak install $FLATPAK_PARAMS_QUIET $pak
done
flatpak override --user --filesystem=$STEAM_LOCAL_LIBRARY com.valvesoftware.Steam

# install rust
if which cargo &> /dev/null; then
    log_message info "Rust is already installed."
else
    log_message info "Installing rust..."
    rustup toolchain install stable
fi

# scripted installations
if aws --version &> /dev/null; then
    log_message info "AWS cli is already installed."
else
    cd $WORKDIR
    log_message info "Downloading latest AWS cli version..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
fi

# golang program installations
if which rdap &> /dev/null; then
    log_message info "RDAP is already installed."
else
    log_message info "Building and installing RDAP..."
    GOMODCACHE=$GO_DIR_CACHE GOBIN=$GO_DIR_BIN go install github.com/openrdap/rdap/cmd/rdap@master
    sudo cp $GO_DIR_BIN/rdap /usr/local/bin/rdap
fi

# setup plasmoids
# BW_MONITOR_PLASMOID_NAME="NetworkBandwidthMonitorQt6.plasmoid"
# wget -O $BW_MONITOR_PLASMOID_NAME "https://ocs-dl.fra1.cdn.digitaloceanspaces.com/data/files/1744930465/NetworkBandwidthMonitorQt6-6.2025.4.20.plasmoid
# kpackagetool6 -i $BW_MONITOR_PLASMOID_NAME

if zypper search --installed-only dark-icon-theme &> /dev/null; then
    log_message info "Dark icon theme is already installed."
else
    log_message info "Building and isntalling dark icon theme..."
    cd $WORKDIR
    git clone --depth 1 https://gitlab.com/sixsixfive/DarK-icons.git
    cd DarK-icons
    sh build_svg.sh
    cd packaging
    sh build_rpm.sh
    sudo zypper $ZYPPER_PARAMS_QUIET install --allow-unsigned-rpm --no-recommends dark-icon-theme*.rpm
fi

# start packagekit
if systemctl list-unit-files packagekit.service &>/dev/null; then
    sudo systemctl start --now packagekit
fi
