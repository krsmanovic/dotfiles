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

show_disk_wait () {
    while true; do
        date
        ps aux | awk '{if ( $8 == "D" ) print $0;}'
        echo
        sleep 1
    done
}

show_os_age () {
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
