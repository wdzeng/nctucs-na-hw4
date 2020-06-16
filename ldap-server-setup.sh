#!/bin/bash
set -e

sid=$1
wgkey=$2

#Installations
apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y ldap-utils slapd

cat > /etc/ldap/ldap.conf <<EOF
BASE           dc=$sid,dc=nasa
URI            ldap://ldap1.$sid.nasa
TLS_CACERT     /etc/ssl/certs/ldap.pem
EOF

mkdir -p /etc/ldap/certs
if [[ (! -f .ldap.cert.pem) || (! -f .ldap.key.pem) ]]; then
  openssl rand -out ~/.rnd -hex 256
  openssl req -nodes -x509 -newkey rsa:2048 -keyout .ldap.key.pem -out .ldap.cert.pem -days 365 -subj "/CN=ldap1.$sid.nasa/"
fi
cp .ldap.key.pem  /etc/ldap/certs/key.pem
cp .ldap.cert.pem /etc/ldap/certs/cert.pem
chown openldap /etc/ldap/certs/{key,cert}.pem
ln -sf /etc/ldap/certs/cert.pem /etc/ssl/ldap.pem

cp pw-totp/* /usr/lib/ldap/

systemctl start slapd

# LDAP
pswd=$sid
slappswd=$(slappasswd -s "$pswd")
slapwgkey=$(slappasswd -s "$wgkey")
takey='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwy0qhML4kj4mWeqi671+2yvhlh13kZ/MoUzmkyt5KjXHro5KzH5MGeDp6aKuPu2M1B9GCn3logTfRJtK/CvIZ/F1UdkI97Cb1wyyMCUHfXh0910nOPOLvlYiQNIs8SgA9p7dMOSI83svqzh9hbgOE1Ie5SsHEze3XhsE/8oAYNdtFSMrRdGYtFRabplXmXnCHI1iVWoAZ/l4LRYihFEebWuSmNSgSCilr9cc4OgIZbDrWOxS9frXWTcWZand881/5K6VKitXh8NS4alxgXNdeRU1Zmp89hkdT/s0khp3DKVt5V7lC2RO8V8hJ/kBMJJESdmxfbfZf/QOGiMaDOq9/wBLHCMGHaF0lKH8wPJclWFgGXOTLeQRzTcdOc4o67k57jBxsgEpb0ZA7k9yYni7MCqbLeMaqGMsfJAF9+NzrR8nA4DcW2xusMJr7uXkVvHNofBTHVusN3JTpvZOw2P3+a7BGhE/eHc8Bzhs5CYnckXVejz5vSzYyXpzja6mjrYihv+U1BzvKMqW1FneiW/h7AYVQOY5FYrYgUOp6sVxwe3EuFdumCpHSbAqL1/eoAwoWA/xBMvX/HuVT6AzHkmPdbjjnWBuxMk4pg0Te9EuGUwc8sfq16dPe7DuxOA7bWUT+73O5YrJbs4Dhxr7WtPFJJXCkB4VTsNxNnfu/3f9yIQ== ta@nasa.cs.nctu.edu.tw'

cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi:///
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=${sid},dc=nasa
-
replace: olcRootDN
olcRootDN: cn=admin,dc=${sid},dc=nasa
-
replace: olcRootPW
olcRootPW: $slappswd
EOF

cat <<EOF | ldapadd -D cn=admin,dc=${sid},dc=nasa -w ${pswd}
dn: ou=People,dc=${sid},dc=nasa
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=${sid},dc=nasa
objectClass: organizationalUnit
ou: Groups
EOF

cat <<EOF | ldapadd -Y EXTERNAL -H ldapi:///
dn: cn=ludou,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: ludou
olcAttributeTypes: ( 1.3.6.1.4.1.9487.1.1
  NAME 'ludoucredit'
  ORDERING integerOrderingMatch
  EQUALITY integerMatch
  SINGLE-VALUE
  SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 )
olcObjectClasses: ( 1.3.6.1.4.1.9487.2.1 
  NAME 'ludouCredit'
  SUP top AUXILIARY MUST ludoucredit )

dn: cn=publickeylogin,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: publickeylogin
olcAttributeTypes: ( 1.3.6.1.4.1.9487.1.2  
  NAME 'sshPublicKey'
  EQUALITY caseExactMatch
  SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
olcObjectClasses: ( 1.3.6.1.4.1.9487.2.2
  NAME 'publicKeyLogin'
  SUP top AUXILIARY MUST sshPublicKey )
EOF

## Create group and users

cat <<EOF | ldapadd -D cn=admin,dc=${sid},dc=nasa -w ${pswd}
dn: cn=ldapusers,ou=Groups,dc=${sid},dc=nasa
objectClass: posixGroup
cn: ldapusers
gidNumber: 3000

dn: cn=taipeirioter,ou=People,dc=${sid},dc=nasa
objectClass: posixAccount
objectClass: publicKeyLogin
objectClass: ludouCredit
objectClass: inetOrgPerson
cn: taipeirioter
sn: Song
uid: taipeirioter
uidNumber: 4000
gidNumber: 3000
ludouCredit: 100
userPassword: $wgkey
sshPublicKey: $takey
loginShell: /bin/bash
homeDirectory: /home/taipeirioter

dn: cn=${sid},ou=People,dc=${sid},dc=nasa
objectClass: posixAccount
objectClass: ludouCredit
objectClass: publicKeyLogin
objectClass: inetOrgPerson
cn: ${sid}
sn: Song
uid: ${sid}
uidNumber: 3001
gidNumber: 3000
ludouCredit: 100
userPassword: $slappswd
loginShell: /bin/bash
sshPublicKey: none
homeDirectory: /home/$sid

dn: cn=TA,ou=People,dc=${sid},dc=nasa
objectClass: posixAccount
objectClass: publicKeyLogin
objectClass: ludouCredit
objectClass: InetOrgPerson
cn: TA
sn: Song
uid: TA
uidNumber: 3000
gidNumber: 3000
ludouCredit: 100
userPassword: $wgkey
sshPublicKey: $takey
loginShell: /bin/bash
homeDirectory: /home/TA

EOF

## Enable STARTTLS and permission control

cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi:///
dn: cn=config
changetype: modify
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/certs/key.pem
-
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/certs/cert.pem

dn: olcDatabase={1}mdb,cn=config
changetype: modify
delete: olcAccess
-
add: olcAccess
olcAccess: to dn.one="ou=People,dc=${sid},dc=nasa" filter=(ludoucredit<=-1) attrs=uid
  by * none
-
add: olcAccess
olcAccess: to dn.one="ou=People,dc=${sid},dc=nasa" attrs=userPassword
  by self write
  by anonymous auth
  by dn.base="cn=admin,dc=${sid},dc=nasa" write
  by * none
-
add: olcAccess
olcAccess: to dn.one="ou=People,dc=${sid},dc=nasa" attrs=ludoucredit
  by dn.base="cn=admin,dc=${sid},dc=nasa" write
  by dn.base="cn=TA,ou=People,dc=${sid},dc=nasa" write
  by * read
-
add: olcAccess
olcAccess: to * 
  by self write
  by dn.base="cn=admin,dc=${sid},dc=nasa" write
  by * read
EOF


## Setup TOTP
cat <<EOF | ldapmodify -H ldapi:/// -Y EXTERNAL
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: pw-totp
EOF

cat <<EOF | ldapadd -H ldapi:/// -Y EXTERNAL
dn: olcOverlay={0}totp,olcDatabase={1}mdb,cn=config
objectClass: olcOverlayConfig
olcOverlay: {0}totp
EOF

cat <<EOF | ldapadd -D cn=admin,dc=$sid,dc=nasa -w $pswd
dn: cn=totp,ou=People,dc=$sid,dc=nasa
cn: totp
sn: Song
objectClass: posixAccount
objectClass: ludouCredit
objectClass: inetOrgPerson
uid: totp
uidNumber: 9453
gidNumber: 3000
loginShell: /bin/bash
homeDirectory: /home/totp
ludoucredit: 100
userPassword: {TOTP1}`printf $wgkey | base32`
EOF

