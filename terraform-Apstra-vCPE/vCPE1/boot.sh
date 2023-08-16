#!/bin/ash
                                                                                                                                       
 sed -i "s/hostname 'LEDE_3'/hostname 'Lede_17_1_tun'/g" /etc/config/system
 chmod 700 /etc/dropbear
 chmod 600 /etc/dropbear/authorized_keys                                                                                                              
 echo 'Hello World!!!'                                                                                                  
 echo 'Hello World!!!!!!!!!!!!!!'                                                                                       
 reboot                                                                                         
