#!/bin/ash

ip link add tunnel0 type gretap remote 10.100.100.2 local 10.100.100.1 ttl 64
ip link set dev tunnel0 up
ip link set dev tunnel0 master br-grelan

----------------------------------------
config interface 'grelan'
        option type 'bridge'
        option auto 'eth2'
        option ifname 'eth2'
        option proto 'static'
        #option ipaddr '10.1.1.10'
        option ipaddr '192.168.98.100'
        option netmask '255.255.255.0'

-----------------xxxx-------------------
config interface 'tunnel'
    option proto 'gretap'
    option ipaddr '10.100.100.2'
    option peeraddr '10.100.100.1'
    option network  'lan2'
----------------------------------------
config interface 'tunnel0'
    option proto 'gre'
    option ipaddr '10.49.100.67'
    option peeraddr '10.49.0.155'
    option mtu 1500
    
config interface 'grelan_static'
    option proto 'static'
    option ifname '@tunnel0'
    option ipaddr '10.1.1.2'
    option netmask '255.255.255.0'
---------------------------------------
Working:>
boot script:>  vi /etc/rc.local
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

sleep 60 && sh /root/gre.sh &

exit 0
