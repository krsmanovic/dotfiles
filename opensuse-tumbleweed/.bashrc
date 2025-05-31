# common shell functions
if [ -f ~/lib/sh/common.sh ]; then
    source ~/lib/sh/common.sh
    echo "Loaded common shell library."
fi

# starship
if [ -f ~/.config/starship/starship.toml ] && which starship &> /dev/null; then
    export STARSHIP_CONFIG=~/.config/starship/starship.toml
    eval -- "$(/usr/bin/starship init bash --print-full-init)"
    echo "Loaded starship configuration."
fi

# kubectl
if which kubectl &> /dev/null; then
    alias k=kubectl
    complete -o default -F __start_kubectl k
    echo "Loaded kubectl completions."
fi

# opentofu
if which tofu &> /dev/null; then
    complete -C /usr/bin/tofu tofu
    echo "Loaded tofu completions."
fi
