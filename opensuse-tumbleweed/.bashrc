# start measuring script duration
INITIAL_SECONDS=$SECONDS

# common shell functions
if [ -f ~/lib/sh/common.sh ]; then
    source ~/lib/sh/common.sh
else
    echo "Failed to load common shell library."
fi

# ops shell functions
if [ -f ~/lib/sh/ops.sh ]; then
    source ~/lib/sh/ops.sh
else
    echo "Failed to load ops shell library."
fi

# starship
if [ -f ~/.config/starship/starship.toml ] && which starship &> /dev/null; then
    export STARSHIP_CONFIG=~/.config/starship/starship.toml
    eval -- "$(/usr/bin/starship init bash --print-full-init)"
else
    echo "Failed to load starship configuration."
fi

# kubectl
if which kubectl &> /dev/null; then
    source <(kubectl completion bash)
    alias k=kubectl
    complete -o default -F __start_kubectl k
else
    echo "Failed to load kubectl completions."
fi

# opentofu
if which tofu &> /dev/null; then
    complete -C /usr/bin/tofu tofu
else
    echo "Failed to load tofu completions."
fi

# generic aliases
alias ff="fastfetch"
alias ll="ls -lah"
alias dev="cd ~/code/krsmanovic"
alias mtr="sudo mtr"
if which rdap &> /dev/null; then
    alias whois="echo Using rdap -w instead...;echo;rdap --whois --type=domain"
fi
alias code="codium"
alias kamera="ffplay -f video4linux2 -input_format mjpeg -video_size 1920x1080 -fs /dev/video0"
alias clonedot="sudo /home/che/scripts/setup/00-clone.sh"
alias osu="sudo /home/che/.local/bin/dup"
alias python="python3"

# functions
function show_disk_wait () {
    while true; do
        date
        ps aux | awk '{if ( $8 == "D" ) print $0;}'
        echo
        sleep 1
    done
}

# decide if we want to print duration
DURATION_SECONDS=$(( SECONDS - INITIAL_SECONDS ))
if [ $DURATION_SECONDS -gt 0 ]; then
    echo ".bashrc took ${DURATION_SECONDS}s to load..."
fi
