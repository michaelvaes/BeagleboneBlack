#!/bin/bash
#
# BBB One Wire Temperature sensor (DS18B20)
# August 21th, 2014: initial creation
#
sName='w1';
sInput=$sName'.dts';
sOutput=${sName:0:16}'-00A0.dtbo';

# Build
/usr/local/bin/dtc -O dtb -o "$sOutput" -b 0 -@ "$sInput";
cp $sOutput /lib/firmware/;
echo "$sName" > /sys/devices/bone_capemgr.9/slots;

