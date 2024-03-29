# NA HW4 Automator

Please prepare a clean Ubuntu OS 18.04.
Clone this repo to your home dir (or somewhere else, but in this tutorial we take home dir for example).

## ldap1 setup
You must have A records pointing to ldap1.0716xxx.nasa; otherwise you cannot run this script.

```
cd ~/nahw4
sudo ./ldap1.sh <student_id> <wireguard_key>
```

If you already prepare your key and certificate, put them at ~/nahw4/.ldap.key.pem and ~/nahw4/.ldap.cert.pem. 
The script will use your certificate or else it generates a new one. 

If the script generates new key and certificate, they will be at ~/nahw4/.ldap.key.pem and ~/nahw4/.ldap.cert.pem. In this case, you must deploy this cert to your nameserver.

If you are not running this script for the first time, the script uses the the cert generated at the first run.

## ws1 setup
You must have A records pointing to ldap1.0716xxx.nasa and agent.0716xxx.nasa and TXT record to cert.0716xxx.nasa; otherwise you cannot run this script.

```
cd ~/nahw4
sudo ./ws1.sh <student_id>
```

## Post-install
Before submitting, be sure you have configured the firewall properly:
- Open tcp:ldap and udp:ldap from intranet to ws1 and ldap1
- Open udp:snmp from intranet to ws1
- Open tcp:ssh from intranet to ldap and ws1

## Clean
If for some reason you fail and want to rerun the scirpt, you should clean your environment before retrying. 
```
cd ~/nahw4
sudo ./clean.sh <student_id>
```

The cleaning does not remove ~/nahw4/.ldap.key.pem and ~/nahw4/.ldap.cert.pem, so if you rerun the script the same key and cert will be used.
