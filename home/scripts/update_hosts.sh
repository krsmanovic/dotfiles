#!/bin/bash

echo ""
echo "Downloading the current hosts.txt file to the /tmp folder"
cd /tmp
wget -q http://winhelp2002.mvps.org/hosts.txt

echo ""
echo "Overwriting the hosts file with the hosts header"
cat /home/che/hosts.header > /etc/hosts

echo ""
echo "Appending the hosts.txt data to the hosts file"
tail -n +26 /tmp/hosts.txt >> /etc/hosts

echo ""
echo "Deleting hosts.txt and exiting the script"
rm /tmp/hosts.txt
echo ""

exit
