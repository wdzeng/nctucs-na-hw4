#!/bin/bash
set -e

DEBIAN_FRONTEND=noninteractive apt remove --purge -y ldap-utils slapd libpam-ldap libnss-ldap nslcd nscd oathtool
apt autoremove -y
sleep 2
rm -rf /etc/ldap
rm -rf /var/lib/ldap
rm -f totppasswd.sh
