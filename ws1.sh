#!/bin/bash
set -e

if [[ $(whoami) != 'root' ]]; then
  echo Must be root.
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo 'script.sh <student_id>'
  exit 1
fi

sid=$1
#wgkey=$2
ldap1ip=$(dig +short ldap1.${sid}.nasa)
ws1ip=$(dig +short ws1.${sid}.nasa)
if [[ -z $ldap1ip ]]; then
  echo ldap1.$sid.nasa IP not found.
  exit 1
fi
if [[ -z $ws1ip ]]; then
  echo ws1.$sid.nasa IP not found.
  exit 1
fi

./ldap-client-setup.sh $@
./snmp-setup.sh $@

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

cat <<EOF
SUCCESS! You can submit!
EOF

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

