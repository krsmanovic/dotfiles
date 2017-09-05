# Make mtr default output to terminal
alias mtr="mtr -t"

# My common mtr typo
alias mrt="mtr -t"

# RIPE route query
function ripe() {
	if [ -z "$1" ]
	then
 		echo ""
		echo "    Parameter missing."
		echo ""
 	else
		whois_data="$(whois -h whois.ripe.net -T route "$1")"
		echo ""
		echo "$whois_data" | sed '/^%/ d' | sed '/^$/ d'
		echo ""
 	fi
	return 0
}

# Color picker by damo
# https://forums.bunsenlabs.org/viewtopic.php?id=3957
alias color='yad --color --button=OK --undecorated  --center'

# kernel.org parser by 2ion
# https://forums.bunsenlabs.org/viewtopic.php?id=1317
alias lskernels="python3 ~/Scripts/lskernels.py"

# srednji kurs evra
alias kurs="~/Scripts/kurs-evra.sh"

# color panes
alias panes="~/Scripts/toy-panes.sh"

# List startup services
alias showstartup="ls -1 /etc/rc\$(runlevel| cut -d\" \" -f2).d/S* | awk -F'[0-9][0-9]' '{print \"Startup :-> \" \$2}'"

# Fix weird Sublime Text 3 behavior with 'subl'
alias subl='subl -w'

# Clear screen quickly
alias c='clear'

# Go back from current directory
alias ..='cd ..'
alias ...='cd ../../../'
alias ....='cd ../../../../'
alias .....='cd ../../../../../'
alias ......='cd ../../../../../../'

# Go back to previous directory
alias b='cd - '

# Go to downloads directory
alias dl='cd ~/Downloads'
