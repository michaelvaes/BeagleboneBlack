#!/bin/bash
sName='w1';
sInput=$sName'.dts';
sOutput=${sName:0:16}'-00A0.dtbo';

# Build
rm -fv $sOutput;
rm -fv /lib/firmware/$sOutput;
cat /sys/devices/bone_capemgr.9/slots;

echo 'echo -9999 > /sys/devices/bone_capemgr.9/slots';

