#!/bin/ash
                                                                                                                                       
 sed -i "s/hostname 'LEDE_3'/hostname 'LEDE_sshtun'/g" /etc/config/system
 chmod 700 /etc/dropbear
 chmod 600 /etc/dropbear/authorized_keys                                                                                                              
 echo 'Hello World!!!'                                                                                                  
 echo 'Hello World!!!!!!!!!!!!!!'                                                                                       
 reboot                                                                                         
