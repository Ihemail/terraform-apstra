#!/bin/ash

ip link add tunnel0 type gretap remote 10.100.100.1 local 10.100.100.2 ttl 64
ip link set dev tunnel0 up
ip link set dev tunnel0 master br-grelan