#!/bin/bash

KEYFILE= `echo ls /media/usb/*.key`

fping urbit.org 2>/dev/null | grep -q alive || \
				(echo "Unable to boot Urbit successfully, cannot contact urbit.org" >&2 ; exit 1)

runuser -u urbit -- urbit -xt -F zod -c /home/urbit/urbit_pier | tee /dev/tty1

