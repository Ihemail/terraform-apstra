#!/bin/ash

#ssh -NL 0.0.0.0:51840:10.207.199.110:51830 ihazra@10.32.192.47
#ssh -R 52830:0.0.0.0:52830 ihazra@10.32.192.47

# ssh -L 51840:localhost:52830 ihazra@10.32.192.47
# mkfifo /tmp/fifo
# nc -l -u -p 51830 < /tmp/fifo | nc 127.0.0.1 51840 > /tmp/fifo

## With /etc/config/sshtunnel config:## socat UDP4-LISTEN:51840,fork TCP4:localhost:52800
#ssh -NL 52800:localhost:52800 ihazra@10.32.192.47 | socat UDP4-LISTEN:51840,fork TCP4:localhost:52800

ssh -NL 53800:localhost:53800 ihazra@10.32.192.47 | socat UDP4-LISTEN:51840,fork TCP4:localhost:53800 &
echo "Hello World!!"

#server$ socat -T10 TCP4-LISTEN:52800,fork UDP4:switch:51830