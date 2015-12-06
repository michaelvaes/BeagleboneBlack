#!/bin/bash
declare -A SENSORS;

# BBBOFFICE
if [ "$(hostname)" -eq "bbboffice.michaelvaes.be" ]; then
	API_KEY="8DLTGR4JMAZ7SGO1";	
	SENSORS["28-0000057ee007"]="&Office&field1";

# BBBGARDEN
elif [ "$(hostname)" -eq "bbbgarden.michaelvaes.be" ]; then
	API_KEY="7ZC64ODGH4PHM7MW";
	SENSORS["28-0000057ee219"]="&Garden&field1"; # Inside
	SENSORS["28-0014136d7bff"]="&Garden&field2"; # Outside
fi