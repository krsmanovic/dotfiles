#!/bin/bash

# Created for MikroTik routers with existing firewall facility.
# Aim is to form permanent block list for scanning farms that
# have known PTR records.
#                                               Che, July 2018

# Create ssh key pair for your router and use
# those credentials for logging in
router_ip="192.168.0.1"
router_username="admin"
router_port="22"
# Stage 1 dynamic address list on the remote MikroTik
router_stage1_dynamic="vpn_stage1"
# Blacklist address list on the remote MikroTik
router_blacklist="vpn_blacklist_static"

# Temporary file we are using to store stage 1 access list
file="stage1"

> "$file"

ssh $router_username@$router_ip -p $router_port "/ip firewall address-list print where list=$router_stage1_dynamic" | awk 'NR > 2 {print $4}' >> "$file"

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
