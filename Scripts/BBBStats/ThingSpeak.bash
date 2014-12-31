#!/bin/bash

#DEFAULT VALUE EXAMPLE {2:-production}
URI="https://api.thingspeak.com/update";
DIR="/root/BeagleboneBlack/Scripts/BBBStats/";

function tsPostData {
  local API_KEY="${1}"; shift;
	local PARAMS="";
	local CNT=1;

	while (( "$#" )); do
		if [ "$CNT" -gt "8" ]; then break; fi

		PARAMS="$PARAMS&field$CNT=$1";
		CNT++
		shift
	done

	# POST the data to thingspeak
	curl -sS --data "api_key=$API_KEY&$PARAMS" ${URI} > /dev/null
	echo "api_key=$API_KEY&$PARAMS" ${URI}
}

function tsPushTemperatures {
	local PARAMS="";
	local VALUE="";

	source "${DIR}/TemperatureSensors.bash";

	for i in "${!SENSORS[@]}"; do
		VALUE=$(getTemperature "$i");
		PARAMS="$PARAMS${SENSORS[$i]}=${VALUE}";	
	done;

	# POST the data to thingspeak
	curl -sS --data "api_key=$API_KEY&$PARAMS" ${URI} > /dev/null
	echo "api_key=$API_KEY&$PARAMS" ${URI}
}

function getTemperature {
	local SENSOR_ID="${1}";
	local TEMP=`grep -oE "t=(\-*[0-9]+)$" "/sys/devices/w1_bus_master1/${SENSOR_ID}/w1_slave" || echo x`;
	if [ "${TEMP}" != "x" ]; then
		TEMP=$(echo "scale=3; ${TEMP:2} / 1000" | bc);
		echo ${TEMP};
	else
		echo "Invalid temperature reading: ${TEMP}";
		exit;
	fi
}
