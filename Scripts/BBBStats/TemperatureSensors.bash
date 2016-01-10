#!/bin/bash

# Ref.: https://www.raspberrypi.org/forums/viewtopic.php?f=37&t=54238&start=25
RETRIES=2;
function getTemperature {
	local SENSOR_ID="${1}";
	local DATA=`cat /sys/devices/w1_bus_master1/${SENSOR_ID}/w1_slave`;
	local DATA_CRC=`echo "${DATA}" | grep crc`;
	local DATA_TEMP=`echo "${DATA}" | grep t=`;
	local TEMP=`echo ${DATA_TEMP} | sed -n 's/.*t=//;p'`;

	# Test if crc is 'YES' and temperature is not -62 or +85
	if [ `echo ${DATA_CRC} | sed 's/^.*\(...\)$/\1/'` == "YES" -a $TEMP != "-62" -a $TEMP != "85000"  ]; then
		echo $(echo "scale=3; ${TEMP} / 1000" | bc);
	else
		# There was an error (crc not 'YES' or invalid temperature)
		# Let's try again after waiting 1 second
		if [ "${RETRIES}" -gt "0" ]; then
			sleep 1;
			RETRIES=$((RETRIES-1));
			getTemperature ${SENSOR_ID};
		fi
	fi
}