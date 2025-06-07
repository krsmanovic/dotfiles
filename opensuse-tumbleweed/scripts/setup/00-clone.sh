#!/bin/bash

# vars
DESKTOP_USER=che
WORKDIR="$(mktemp -d)"
SUDOERS_CONFIG_DIR="/usr/etc/sudoers.d"
SUDOERS_CONFIG_CUSTOM_PATH="$SUDOERS_CONFIG_DIR/99-bootstrap-scripts"

# install essential tools
sudo zypper --non-interactive --quiet install curl jq git tig

# do the magic
cd $WORKDIR
git clone https://github.com/krsmanovic/dotfiles.git
rsync -a dotfiles/opensuse-tumbleweed/ /home/$DESKTOP_USER/
sudo chown -R $DESKTOP_USER:$DESKTOP_USER /home/$DESKTOP_USER/

# allow config scripts to mess up the system
if sudo grep "@includedir $SUDOERS_CONFIG_DIR" /usr/etc/sudoers; then
    if [ -d $SUDOERS_CONFIG_DIR ]; then
        echo
    else
        sudo mkdir -p $SUDOERS_CONFIG_DIR
    fi
    sudo tee $SUDOERS_CONFIG_CUSTOM_PATH > /dev/null << EOF
$DESKTOP_USER ALL=(ALL:ALL) NOPASSWD:/home/$DESKTOP_USER/scripts/setup/01-bootstrap.sh
EOF
fi
sudo chmod 440 /usr/etc/sudoers
sudo chmod 440 $SUDOERS_CONFIG_CUSTOM_PATH
sudo visudo --check
