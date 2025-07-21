# start measuring script duration
INITIAL_SECONDS=$SECONDS

# common shell functions
if [ -f ~/lib/sh/common.sh ]; then
    source ~/lib/sh/common.sh
else
    echo "Failed to load common shell library."
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

# decide if we want to print duration
DURATION_SECONDS=$(( SECONDS - INITIAL_SECONDS ))
if [ $DURATION_SECONDS -gt 0 ]; then
    echo ".bashrc took ${DURATION_SECONDS}s to load..."
fi
