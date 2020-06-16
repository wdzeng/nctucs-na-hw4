#!/bin/bash
set -e

if [[ $# -ne 1 ]]; then
  >&2 echo './snmp-setup.sh <student_id>'
  exit 1
fi

sid=$1
wid=$(dig agent.$sid.nasa +short | awk '-F.' '{print $3}')
if [[ -z $wid ]]; then
  >&2 echo 'Cannot find your agent IP.'
  exit 1
fi


apt update -y
apt install -y snmpd wget
#apt install -y snmp libsnmp-dev

cp -f snmpd.conf /etc/snmp/snmpd.conf
sed -i s/@ID@/$wid/ /etc/snmp/snmpd.conf

cat > /usr/local/bin/i_love_yca.sh <<EOF
#!/bin/bash
wget -q --spider agent.$sid.nasa
EOF
chmod +x /usr/local/bin/i_love_yca.sh

systemctl restart snmpd
