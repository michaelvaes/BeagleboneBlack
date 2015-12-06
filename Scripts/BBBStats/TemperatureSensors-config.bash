#!/bin/bash
declare -A SENSORS;

# HOST 1
if [ "$(hostname)" = "host1.example.tld" ]; then
	API_KEY="host1key";	
	SENSORS["28-0000057ee007"]="&Office&field1";

# HOST 2
elif [ "$(hostname)" = "host2.example.tld" ]; then
	API_KEY="host2key";
	SENSORS["28-0000057ee219"]="&Garden&field1"; # Sensor 1
	SENSORS["28-0014136d7bff"]="&Garden&field2"; # Sensor 2
fi