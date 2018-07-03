#!/bin/bash

# Created for MikroTik routers with existing firewall facility.
# Aim is to form permanent block list for scanning farms that
# have known PTR entries.
# 						Che, July 2018

# Create ssh key pair for your router and use
# those credentials for logging in
router_ip="192.168.0.1"
router_username="admin"
router_port="22"

# Name of the script that extracts stage 1 dynamic access list
# that executes locally on remote MikroTik
router_script="ssh-export-stage1"
# This is the example of the script:
# :local ip;
# :foreach i in=[/ip firewall address-list find list=vpn_stage1] do={
#       :set ip [/ip firewall address-list get $i address];
#       :put $ip
# }

# Blacklist name on the remote router
router_blacklist="vpn_blacklist_static"

# Temporary file we are using to store stage 1 access list
file="stage1"

> "$file"

ssh $router_username@$router_ip -p $router_port "/system script run $router_script" >> "$file"

while IFS='' read -r ip || [[ -n "$ip" ]]
do 

	ip=$(echo $ip | tr -d '\r')
	domain=$(dig -x "$ip" +short | sed 's/.$//')

	if [ ! -z "$domain" ]
	then
		if echo $domain | egrep -i "(^|[^a-zA-Z])(stretchoid|shodan)($|[^a-zA-Z])" > /dev/null
			then
		        ssh $router_username@$router_ip -p $router_port "do { /ip firewall address-list add list=$router_blacklist comment=$domain address=$ip } on-error={}"
		        echo "Host $ip with PTR $domain was added to the blacklist on the remote device."
		fi
	fi

done < "$file"
