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
function show_os_age () {
    birth_root=$(stat -c %W /)
    time_curent=$(date +%s)

    age_seconds=$((time_curent - birth_root))
    age_days=$((age_seconds / 86400))
    age_years=$((age_days / 365))
    age_years_weeks=$((age_days % 365 / 7))
    age_years_days=$((age_days % 365 % 7))

    # years
    if [ "$age_years" -eq "1" ]; then
        noun_age_years="year"
    else
        noun_age_years="years"
    fi
    if [ "$age_years" -eq "0" ]; then
        output_years=""
    else
        output_years="$age_years $noun_age_years,"
    fi

    # weeks
    if [ "$age_years_weeks" -eq "1" ]; then
        noun_age_weeks="week"
    else
        noun_age_weeks="weeks"
    fi
    if [ "$age_years_weeks" -eq "0" ]; then
        output_weeks=""
    else
        output_weeks="$age_years_weeks $noun_age_weeks,"
    fi

    # days
    if [ "$age_years_days" -eq "1" ]; then
        noun_age_days="day"
    else
        noun_age_days="days"
    fi
    if [ "$age_years_days" -eq "0" ]; then
        output_days=""
    else
        output_days="$age_years_days $noun_age_days"
    fi

    echo "$output_years $output_weeks $output_days ($age_days days)"
}

# decide if we want to print duration
DURATION_SECONDS=$(( SECONDS - INITIAL_SECONDS ))
if [ $DURATION_SECONDS -gt 0 ]; then
    echo ".bashrc took ${DURATION_SECONDS}s to load..."
fi
