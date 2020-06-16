# NA HW4 Automator

Please prepare a clean Ubuntu OS 18.04.
Clone this repo to your home dir (or somewhere else, but in this tutorial we take home dir for example).

## ldap1 setup
You must have A records pointting to ldap1.0716xxx.nasa and ws1.0716xxx.nasa; otherwise you cannot run this script.

```
cd ~/nahw4
sudo ./ldap1.sh <student_id> <wireguard_key>
```

If you already prepare your key and certificate, put them at /nahw4/.ldap.key.pem and /nahw4/.ldap.cert.pem. 
The script will use your certificate or else it generates a new one. If the script generates new certificates, you must deploy this cert to your nameserver.

If you are not running this script for the first time, the script uses the script generated when the first run.

## ws1 setup
You must have A records pointting to ldap1.0716xxx.nasa, ws1.0716xxx.nasa and cert.0716023.nasa; otherwise you cannot run this script.

```
cd ~/nahw4
sudo ./ws1.sh <student_id> <wireguard_key>
```

## Clean
If for some reason you fail and you want to rerun the scirpt, you should clean your environment.
```
cd ~/nahw4
sudo ./clean.sh <student_id>
```
