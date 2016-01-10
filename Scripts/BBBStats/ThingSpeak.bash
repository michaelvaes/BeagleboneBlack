#!/bin/bash
#
# POST temperatures to ThingSpeak
#
URI="https://api.thingspeak.com/update";
DIR="/root/BeagleboneBlack/Scripts/BBBStats/";
CONFIG="${DIR}/TemperatureSensors-config.bash";
FUNC="${DIR}/TemperatureSensors.bash";

function tsPostData {
	local API_KEY="${1}"; shift;
	local PARAMS="";
	local CNT=1;

	while (( "$#" )); do
		if [ "${CNT}" -gt "8" ]; then break; fi

		PARAMS="${PARAMS}&field${CNT}=${1}";
		CNT=$((CNT-1));
		shift;
	done

	# POST the data to thingspeak
	curl -sS --data "api_key=${API_KEY}&${PARAMS}" ${URI} > /dev/null;
	echo "api_key=${API_KEY}&${PARAMS}" ${URI};
}

function tsPushTemperatures {
	local PARAMS="";
	local VALUE="";

	source "${CONFIG}";

	for i in "${!SENSORS[@]}"; do
		VALUE=$(getTemperature "${i}");
		PARAMS="${PARAMS}${SENSORS[${i}]}=${VALUE}";	
	done;

	# POST the data to thingspeak
	curl -sS --data "api_key=${API_KEY}&${PARAMS}" ${URI} > /dev/null;
	echo "api_key=${API_KEY}&${PARAMS}" ${URI};
}
