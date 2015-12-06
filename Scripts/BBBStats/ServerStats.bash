#!/bin/bash

# install necessary files:
# sudo apt-get install bc

# make this file executable:
# chmod +x ServerStats.bash

# add to crontab (command: crontab -e)
# * * * * * /path/to/ServerStats.bash
DIR="/root/BeagleboneBlack/Scripts/BBBStats/";

# thingspeak api key for channel that data will be logged to
source "${DIR}/ServerStats-config.bash";

# get cpu usage as a percent
used_cpu_percent=`top -b -n2 -p 1 | fgrep "Cpu(s)" | tail -1 | tr -s ' ' | cut -f2 -d' ' | cut -f1 -d'%'`

# get memory
used_mem=`free -m | tr -s ' ' | grep buffers/cache | cut -f3 -d' '`
total_mem=`free -m | tr -s ' ' | grep Mem | cut -f2 -d' '`
used_mem_percent=`echo "scale=2;100*$used_mem/$total_mem" | bc`

# get disk use as a percent
used_disk_percent=`df -lh | awk '{if ($6 == "/") { print $5 }}' | head -1 | cut -d'%' -f1`

# post the data to thingspeak
curl -sS --data "api_key=$api_key&field1=$used_cpu_percent&field2=$used_mem_percent&field3=$used_disk_percent" https://api.thingspeak.com/update > /dev/null
