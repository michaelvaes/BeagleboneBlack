#!/bin/bash

# Ref.: https://www.raspberrypi.org/forums/viewtopic.php?f=37&t=54238&start=25
RETRIES=2;
function getTemperature {
	local SENSOR_ID="${1}";

	if [ -z "${SENSOR_ID}" ]; then
		echo 'No temperature sensor provided!';
		return;
	elif [ "${SENSOR_ID:0:3}" == "28-" ]; then
		getDigitalTemperature ${SENSOR_ID};
	elif [ "${SENSOR_ID:0:3}" == "AIN" ]; then
		getAnalogTemperature ${SENSOR_ID};
	else
		echo 'Only analog (AIN*) and digital (28*) sensors are allowed.';
		return;		
	fi
}

#
# LMT86 analog temperature sensors
#
function getAnalogTemperature {
	local SENSOR_ID="${1}";
	local VOLTAGECMD="cat /sys/devices/ocp.3/helper.13/${SENSOR_ID}";
	local VDIFFRATIO="1.494005994";   # Voltage divider ratio 47k/20k
	local TEMPMODIFIER="-1.91592543"; # Difference with Digital sensor

	# Sampling to reduce fluctuations
	local VOLTAGES=`${VOLTAGECMD}`;
	for i in `seq 1 9`; do
		sleep 0.25;
		VOLTAGES="${VOLTAGES} + `${VOLTAGECMD}`";
	done; 

	local VOLTAGE=`echo "(${VOLTAGES}) / 10" | bc`;

	# LMT86 temperature conversion formula
	# >> ending /1 is to apply scale
	local FORMULA="( ( ( ( 10.888 - sqrt( (-10.888*-10.888)+4 * 0.00347 * (1777.3-${VOLTAGE}*${VDIFFRATIO}) ) ) / (2*-0.00347)) ) + 30 + ${TEMPMODIFIER} ) / 1";

	echo $(echo "scale=10; temperature=${FORMULA}; scale=3; temperature/1;" | bc);
}

#
# DS18B20 digital temparature sensors
#
function getDigitalTemperature {
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
			getDigitalTemperature ${SENSOR_ID};
		fi
	fi
}

#
# HIH-4010 analog humidity sensor
# Inputs:
#  - Humidity Sensor ID (analog)
#  - Temperature Sensor ID (analog/digital)
# References:
#  - https://github.com/wgr69/gfb/blob/master/arduino/DS2438/DS2438.cpp
#  - http://forum.arduino.cc/index.php?topic=19961.0
#
function getHumidity {
	local HUMIDITY_SENSOR_ID="${1}";
	local TEMP_SENSOR_ID="${2}";

	if [ -z "${HUMIDITY_SENSOR_ID}" ]; then
		echo 'No humidity sensor provided!';
		return;
	elif [ "${HUMIDITY_SENSOR_ID:0:3}" != "AIN" ]; then
		echo 'Only analog (AIN*) sensors are allowed.';
		return;
	fi

	local TEMP=$(getTemperature ${TEMP_SENSOR_ID});

	local VOLTAGECMD="cat /sys/devices/ocp.3/helper.13/${HUMIDITY_SENSOR_ID}";
	local VDIFFRATIO="2.4"; # Voltage divider ratio 28k/20k

	# Sampling to reduce fluctuations
	local VOLTAGES=`${VOLTAGECMD}`;
	for i in `seq 1 9`; do
		sleep 0.25;
		VOLTAGES="${VOLTAGES} + `${VOLTAGECMD}`";
	done;
	local VOLTAGE=`echo "(${VOLTAGES}) / 10" | bc`;

	# HIH-4010 temperature conversion formula
	# >> ending /1 is to apply scale
	local FORMULA="((((${VOLTAGE}/1000*${VDIFFRATIO}) / 5) - 0.16) / 0.0062) / (1.0546 - (0.00216 * ${TEMP}))";

	echo $(echo "scale=10; humidity=${FORMULA}; scale=1; humidity/1;" | bc);
}
