#!/bin/bash

# operational functions that save me more than 5s of typing, thinking or reading man pages :)

reinstall_flatpaks () {
    for pak in $(flatpak list --columns=application --user | grep -v "Application ID"); do
        flatpak install --reinstall --assumeyes --noninteractive flathub $pak
    done
}

show_init () {
    ps -p 1 -o comm=
}

rename_mp3_1 () {
    IFS=$'\n'
    artist=""
    if [ "$#" -gt 0 ]; then
        artist="${@} - "
    fi
    for i in $(ls -1 *.mp3); do
        new_name=$(echo -n "$i" | sed -r "s/([0-9]{2})[^a-zA-Z0-9]+(.*\.mp3)/$artist\1 - \2/")
        mv $i $new_name
        echo "$i > $new_name"
    done
    unset IFS
}
