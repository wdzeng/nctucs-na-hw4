#!/bin/bash
set -e

if [[ $(whoami) != 'root' ]]; then
  >&2 echo Must be root.
  exit 1
fi

if [[ $# -ne 1 ]]; then
  >&2 echo 'script.sh <student_id>'
  exit 1
fi

sid=$1
#wgkey=$2
ldap1ip=$(dig +short ldap1.${sid}.nasa)
ws1ip=$(dig +short ws1.${sid}.nasa)
agentip=$(dig +short agent.${sid}.nasa)
if [[ -z $ldap1ip ]]; then
  >&2 echo ldap1.$sid.nasa IP not found.
  exit 1
fi
if [[ -z $ws1ip ]]; then
  >&2 echo ws1.$sid.nasa IP not found.
  exit 1
fi
if [[ -z $agentip ]]; then
  >&2 echo agent.$sid.nasa IP not found.
  exit 1
fi

./ldap-client-setup.sh $@
./snmp-setup.sh $@

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

cat <<EOF
SUCCESS! You can submit!
EOF

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

