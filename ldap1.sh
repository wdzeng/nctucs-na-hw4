#!/bin/bash
set -e

if [[ $(whoami) != 'root' ]]; then
  echo Must be root.
  exit 1
fi

if [[ $# -ne 2 ]]; then
  >&2 echo 'script.sh <student_id> <wg_key>'
  exit 1
fi

sid=$1
wgkey=$2
ldap1ip=$(dig +short ldap1.${sid}.nasa)
if [[ -z $ldap1ip ]]; then
  echo ldap1.$sid.nasa IP not found.
  exit 1
fi

./ldap-server-setup.sh $@
./ldap-client-setup.sh $@

## Done
certdns=$(cat /etc/ldap/certs/cert.pem | base64 | awk '{print "    \""$0"\""}')

apt install oathtool -y
totpcode=$(printf $wgkey | base32)
cat > totppasswd.sh <<EOF
#!/bin/bash
while true; do oathtool --totp -b $totpcode; sleep 1; done
EOF
chmod +x totppasswd.sh

## Print success message

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
cat <<EOF
SUCCESS! 

You can see totp's password via \`./totppasswd\`.

You need to publish this record (only if you ran this script for the first time). 
\`\`\`
cert.$sid.nasa.    IN    TXT  ( 
$certdns )
\`\`\`
EOF
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

