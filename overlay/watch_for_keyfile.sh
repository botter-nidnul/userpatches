#!/bin/bash

counter=0
while [ $counter -le 100 ]
do
        if [ `ls /media/usb/*.key` ];
                then
                        echo "urbit keyfile detected"
                        /usr/bin/boot_urbit_with_keyfile.sh
                else
                        sleep 3
                        ((counter++))
                        echo $counter
        fi
done
echo "urbit keyfile watch timed out"
