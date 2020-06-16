#!/bin/bash
set -e

if [[ $# -ne 1 ]]; then 
  >&2 echo './clean.sh <student_id>'
  exit 1
fi
sid=$1

DEBIAN_FRONTEND=noninteractive apt remove --purge -y ldap-utils slapd libpam-ldap libnss-ldap nslcd nscd oathtool
apt autoremove -y
rm -rf /etc/ldap /var/lib/ldap /home/totp /home/TA /home/taipeirioter /home/$sid  totppasswd.sh
