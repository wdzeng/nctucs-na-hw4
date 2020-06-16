#!/bin/bash

if [[ $# -ne 1 ]]; then 
  >&2 echo './clean.sh <student_id>'
  exit 1
fi
sid=$1

systemctl stop slapd nslcd nscd 
systemctl disable slapd nslcd nscd

DEBIAN_FRONTEND=noninteractive apt remove --purge -y ldap-utils slapd libpam-ldap libnss-ldap nslcd nscd oathtool
apt autoremove -y
sleep 2
rm -rf /etc/ldap /var/lib/ldap /home/totp /home/TA /home/taipeirioter /home/$sid  totppasswd.sh
