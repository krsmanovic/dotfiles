#!/bin/bash

# operational functions that save me more than 5s of typing or reading man pages :)

reinstall_flatpaks () {
    for pak in $(flatpak list --columns=application --user | grep -v "Application ID"); do
        flatpak install --reinstall --assumeyes --noninteractive flathub $pak
    done
}

show_init () {
    ps -p 1 -o comm=
}
