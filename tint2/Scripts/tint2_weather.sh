#!/bin/bash

# Taken from
# https://petermolnar.net/hacking-tint2-panel-weather-cpu-temperature-and-volume-executors/
# and edited for convinence

geo="$(wget -O- -q http://geoip.ubuntu.com/lookup)"
if grep -qi '91.148.109.98' <<< $geo; then
    lat="44.8186"
    lon="20.4681"
else
    lat="$(sed -r 's/.*<Latitude>(.*?)<\/Latitude>.*/\1/g' <<< $geo)"
    lon="$(sed -r 's/.*<Longitude>(.*?)<\/Longitude>.*/\1/g' <<< $geo)"
fi

weather="$(wget -q -O- http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=$lat,$lon)"

kw="temp_c"
temperature="$(sed -r "s/.*<$kw>(.*?)<\/$kw>.*/\1/g" <<< $weather)"

display_output="${temperature}°C"

echo "${display_output:0:12}"
