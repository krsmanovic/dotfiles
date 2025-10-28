#!/bin/bash

# vars
DESKTOP_USER=che
WORKDIR="$(mktemp -d)"
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
sudo rsync --recursive --update --times opensuse-tumbleweed/scripts/cron/weekly/ /etc/cron.weekly
sudo rsync --recursive --update --times opensuse-tumbleweed/scripts/cron/monthly/ /etc/cron.monthly

# allow config scripts to mess up the system
if sudo grep --quiet "@includedir $SUDOERS_CONFIG_DIR" /usr/etc/sudoers; then
    if [ -d $SUDOERS_CONFIG_DIR ]; then
        echo
    else
        sudo mkdir -p $SUDOERS_CONFIG_DIR
    fi
    sudo tee $SUDOERS_CONFIG_CUSTOM_PATH > /dev/null << EOF
# bootstrap scripts
$DESKTOP_USER ALL=(ALL:ALL) NOPASSWD:/home/$DESKTOP_USER/scripts/setup/00-clone.sh
$DESKTOP_USER ALL=(ALL:ALL) NOPASSWD:/home/$DESKTOP_USER/scripts/setup/01-bootstrap.sh
EOF
    sudo tee $SUDOERS_CONFIG_USER_PATH > /dev/null << EOF
# mtr
$DESKTOP_USER ALL=(root) NOPASSWD:/usr/sbin/mtr
EOF
fi
sudo chmod --recursive 440 $SUDOERS_CONFIG_DIR
sudo visudo --check
