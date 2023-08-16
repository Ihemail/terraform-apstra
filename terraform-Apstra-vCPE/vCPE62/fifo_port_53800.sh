#!/bin/bash

rm -rf /tmp/fifo53800
mkfifo /tmp/fifo53800

nc -l -p 53800 < /tmp/fifo53800 | nc -u 10.220.10.202 51820 > /tmp/fifo53800 &
# socat -T10 TCP4-LISTEN:52800,fork UDP4:switch:51830

echo "Hello World!!"
echo "FIFO port tunnel Established on port 53800 @qnc-css-lnx02"

