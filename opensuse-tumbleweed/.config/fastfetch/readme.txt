I have converted OpenSUSE logo from svg to raw image format.

I have changed green tone, and originals was fetched from:
    1) https://en.opensuse.org/images/6/6c/OpenSUSE-hellcp.svg
    2) https://github.com/openSUSE/artwork/blob/master/logos/distros/tumbleweed.svg

Commands to convert the files:

DESKTOP_USER=che
kitten icat -n --align=left --transfer-mode=stream /home/$DESKTOP_USER/.config/fastfetch/images/chameleon-kitty.svg > /home/$DESKTOP_USER/.config/fastfetch/images/chameleon-kitty.bin
kitten icat -n --align=left --transfer-mode=stream /home/$DESKTOP_USER/.config/fastfetch/images/tumbleweed.svg > /home/$DESKTOP_USER/.config/fastfetch/images/tumbleweed.bin
