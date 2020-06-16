#!/bin/bash
set -e

sid=$1
wgkey=$2
pswd=$sid

if [[ ! -f /etc/ssl/certs/ldap.pem ]]; then
  cacert=$(dig TXT +short cert.$sid.nasa @ns1.$sid.nasa | sed 's/"//g' | sed 's/\s//g' | base64 -d)
  if [[ -z $cacert ]]; then
    >&2 echo 'Please publish your cert firet. Byebye.'
    exit 1;
  fi
  printf "$cacert" > /etc/ssl/certs/ldap.pem
fi


## Authentication
DEBIAN_FRONTEND=noninteractive apt install -y libpam-ldap libnss-ldap nslcd 

cat > /etc/nslcd.conf <<EOF
uid nslcd
gid nslcd
uri ldap://ldap1.$sid.nasa
base   dc=$sid,dc=nasa
base   group   ou=Groups,dc=$sid,dc=nasa
base   passwd  ou=People,dc=$sid,dc=nasa
binddn cn=$sid,ou=People,dc=$sid,dc=nasa
bindpw $sid
tls_cacertfile /etc/ssl/certs/ldap.pem
EOF

cat > /etc/nsswitch.conf <<EOF
passwd:         compat systemd ldap
group:          compat systemd ldap
shadow:         compat ldap
gshadow:        files
hosts:          files dns
networks:       files
protocols:      db files
services:       db files
ethers:         db files
rpc:            db files
netgroup:       nis
EOF

cat > /etc/ldap.conf <<EOF
base dc=$sid,dc=nasa
uri ldap://ldap1.$sid.nasa
ldap_version 3
binddn cn=$sid,ou=People,dc=$sid,dc=nasa
bindpw $sid
rootbinddn cn=admin,dc=$sid,dc=nasa
pam_password md5
tls_cacertfile /etc/ssl/certs/ldap.pem
EOF

printf $sid > /etc/ldap.secret
chmod 600 /etc/ldap.secret

cp -f nscd.conf /etc/nscd.conf

echo session required pam_mkhomedir.so skel=/etc/skel umask=077 >> /etc/pam.d/common-session

cat > /etc/pam.d/common-password <<EOF
password        [success=2 default=ignore]                      pam_unix.so obscure sha512
password        [success=1 user_unknown=ignore default=die]     pam_ldap.so try_first_pass
password        requisite                                       pam_deny.so
password        required                                        pam_permit.so
EOF

cat > /etc/ldap-key-auth.sh <<EOF
#!/bin/sh
ldapsearch -H ldap://ldap1.$sid.nasa -b dc=$sid,dc=nasa -D cn=$sid,ou=People,dc=$sid,dc=nasa -w $sid '(&(objectClass=posixAccount)(uid='"TA"')(ludoucredit>=1))' 'sshPublicKey' | awk '/^sshPublicKey/{\$1=""; p=1} /^$/{p=0} {printf p?\$0:""}' | sed 's/ //g' | base64 -d
EOF
chmod +x /etc/ldap-key-auth.sh
cp -f sshd_config /etc/ssh/sshd_config

systemctl enable nslcd nscd
systemctl restart sshd
systemctl start  nslcd nscd

