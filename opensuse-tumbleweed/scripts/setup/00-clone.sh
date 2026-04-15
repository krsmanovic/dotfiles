#!/bin/bash

# vars
DESKTOP_USER=che
WORKDIR="$(mktemp -d)"
SUDOERS_FILE="/usr/etc/sudoers"
SUDOERS_CONFIG_DIR="/usr/etc/sudoers.d"
SUDOERS_CONFIG_USER_PATH="$SUDOERS_CONFIG_DIR/98-$DESKTOP_USER"
SUDOERS_CONFIG_CUSTOM_PATH="$SUDOERS_CONFIG_DIR/99-bootstrap-scripts"

# install essential tools
sudo zypper --non-interactive --quiet install curl jq git tig

# do the magic
cd $WORKDIR
git clone https://github.com/krsmanovic/dotfiles.git
cd dotfiles
while read filename; do
    unixtime=$(git log -1 --format="%at" -- "${filename}")
    touchtime=$(date -d @$unixtime +'%Y%m%d%H%M.%S')
    touch -t ${touchtime} "${filename}"
done < <(git ls-files)
rsync --recursive --update --times opensuse-tumbleweed/ /home/$DESKTOP_USER/
sudo chown -R $DESKTOP_USER:$DESKTOP_USER /home/$DESKTOP_USER/
for dir in $(ls -1 opensuse-tumbleweed/scripts/cron); do
    sudo rsync --recursive --update --times opensuse-tumbleweed/scripts/cron/$dir/ /etc/cron.$dir
done

# allow config scripts to mess up the system
if sudo grep --quiet "@includedir $SUDOERS_CONFIG_DIR" $SUDOERS_FILE; then
    if [ -d $SUDOERS_CONFIG_DIR ]; then
        echo "$SUDOERS_FILE is already up to date..."
    else
        sudo mkdir -p $SUDOERS_CONFIG_DIR
    fi
    sudo dd status=none of=$SUDOERS_CONFIG_CUSTOM_PATH << EOF
# bootstrap scripts
$DESKTOP_USER ALL=(ALL:ALL) NOPASSWD:/home/$DESKTOP_USER/scripts/setup/00-clone.sh
$DESKTOP_USER ALL=(ALL:ALL) NOPASSWD:/home/$DESKTOP_USER/scripts/setup/01-bootstrap.sh
Cmnd_Alias    DUP_CMDS = /home/$DESKTOP_USER/.local/bin/dup
$DESKTOP_USER ALL=NOPASSWD:SETENV: DUP_CMDS
EOF
    sudo dd status=none of=$SUDOERS_CONFIG_USER_PATH << EOF
# mtr
$DESKTOP_USER ALL=(root) NOPASSWD:/usr/sbin/mtr
EOF
fi
# for some reason distribution produces wrong permissions on sudoers config files
sudo chmod 440 $SUDOERS_FILE
sudo chmod --recursive 440 $SUDOERS_CONFIG_DIR
sudo visudo --check
