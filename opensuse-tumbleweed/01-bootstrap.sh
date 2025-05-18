#!/bin/bash

# set host information
sudo hostnamectl set-hostname greenzard
if [ `sudo dmesg | grep -q 'Hypervisor detected'` ]; then
    CHASSIS_TYPE="desktop"
else
    CHASSIS_TYPE="vm"
fi
sudo hostnamectl set-chassis $CHASSIS_TYPE

# standardize stdout timestamp
stamp_time () {
    TZ="Europe/Belgrade" date "+%Y-%m-%d %H:%M:%S"
}

# configure logging
if logger -V &> /dev/null; then
    LOGGING_FACILITY="logger"
else
    LOGGING_FACILITY="fd"
fi

VALID_LOG_LEVEL_NAMES=(
    emerg
    alert
    crit
    err
    warning
    notice
    info
    debug
)

log_message () {
    local LOGGER_MESSAGE_LEVEL
    local LOGGER_MESSAGE
    local LOGGER_TIME

    LOGGER_TIME=$(stamp_time)
    LOGGER_MESSAGE_LEVEL=$1
    LOGGER_MESSAGE=$2

    TOLOWER_LOGGER_MESSAGE_LEVEL=$(echo $LOGGER_MESSAGE_LEVEL | awk '{print tolower($0)}')
    # validate log level
    if [ `echo "$VALID_LOG_LEVEL_NAMES" | grep -w -q "$TOLOWER_LOGGER_MESSAGE_LEVEL"` ]; then
        REAL_LOG_LEVEL="$TOLOWER_LOGGER_MESSAGE_LEVEL"
    else
        REAL_LOG_LEVEL="info"
    fi

    # print log message
    if [ $LOGGING_FACILITY == "logger" ]; then
        logger --priority "local7.$REAL_LOG_LEVEL" "$LOGGER_MESSAGE"
    else
        TOUPPER_REAL_LOG_LEVEL=$(echo $REAL_LOG_LEVEL | awk '{print toupper($0)}')
        echo "$LOGGER_TIME $TOUPPER_REAL_LOG_LEVEL $LOGGER_MESSAGE"
    fi
}

# install essential tools
log_message info "Installing essential packages..."
sudo zypper --non-interactive --quiet install curl jq git

# set up directories
DESKTOP_USER=che
STEAM_LOCAL_LIBRARY=/home/$DESKTOP_USER/steam/library
WORKDIR="$(mktemp -d)"
mkdir -p $STEAM_LOCAL_LIBRARY

# package manager variables
ANYDESK_LOCAL_REPO_PATH=/etc/zypp/repos.d/anydesk.repo
CODIUM_LOCAL_REPO_PATH=/etc/zypp/repos.d/vscodium.repo
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

# install packages
sudo zypper --non-interactive --quiet update
log_message info "Installing core list of packages..."
sudo zypper $ZYPPER_PARAMS_QUIET install \
    nmap mtr whois samba-client bind-utils wireshark wget \
    fastfetch neovim fira-code-fonts conky tmux htop btop steam-devices kitty \
    go go-doc rustup cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel libstartup-notification-1-0 \
    flatpak \
    discord telegram-desktop MozillaThunderbird \
    wine virtualbox \
    deadbeef audacity ffmpeg \
    keepassxc gimp calibre okular k3b qbittorrent nextcloud

# install rust
log_message info "Installing rust..."
rustup toolchain install stable

# install programs from external repos
log_message info "Installing packages from external repositories..."
sudo tee $ANYDESK_LOCAL_REPO_PATH > /dev/null << "EOF" 
[anydesk]
name=AnyDesk OpenSUSE - stable
baseurl=http://rpm.anydesk.com/opensuse/$basearch/
enabled=1
pkg_gpgcheck=1
repo_gpgcheck=1
gpgpautoimport=1
autorefresh=1
gpgkey=https://keys.anydesk.com/repos/RPM-GPG-KEY
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
sudo zypper $ZYPPER_PARAMS_QUIET --gpg-auto-import-keys refresh
sudo zypper $ZYPPER_PARAMS_QUIET update
sudo zypper $ZYPPER_PARAMS_QUIET install anydesk codium

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

# rpm installations
cd $WORKDIR
log_message info "Downloading latest TeamViewer version..."
wget https://download.teamviewer.com/download/linux/teamviewer-suse.x86_64.rpm
wget https://linux.teamviewer.com/pubkey/currentkey.asc -O teamviewer-public-key.asc
sudo rpm --import teamviewer-public-key.asc
sudo zypper $ZYPPER_PARAMS_QUIET install teamviewer-suse.x86_64.rpm
