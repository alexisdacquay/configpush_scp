#!/bin/bash
# by Alexis Dacquay, ad@arista.com
# version 1.4
#
# examples of aliases and command examples to setup this script:
# alias backup bash /mnt/flash/configpush_scp.sh user 1.1.1.1
#
# automated backup on config save:
# event-handler config-push
#   trigger on-startup-config
#   action bash /mnt/flash/configpush_scp.sh user 1.1.1.1

if [ ! $1 ] || [ ! $2 ]; then
 echo "Usage: configpush_scp.sh <USER> <DESTINATION IP> [<REMOTE PATH>]"
 exit 0
fi

echo "Informational: Automated SCP transfer requires that SSH keys are setup"
# The above is only a failsafe info for people unaware (during setup); 
# You may want to comment out for production.
#
# Setup example, from Arista EOS kernel bash; test afterwards with 'sudo ssh user@server':
# sudo cat /persist/secure/ssh_host_dsa_key.pub | ssh user@server 'cat >> .ssh/authorized_keys'

USER=$1
IP=$2
NOW=$(date +%Y-%m-%d.%H%M%S)
if [ $3 ]
then
  CONFIGPATH=$3
else
  CONFIGPATH='~/'
fi

echo "Informational: Timestamp is $NOW"

# Capturing Running-config and diff
echo '-------------------- diff running-config <> startup-config ------------------------' >> /tmp/configdump_run_diff
FastCli -p 15 -c 'show run diff > file:/tmp/configdump_run_diff'
sleep 1
FastCli -p 15 -c 'show run > file:/tmp/configdump_run'
sleep 1
sudo scp -o LogLevel=ERROR /tmp/configdump_run $USER@$IP:$CONFIGPATH/$HOSTNAME-run-$NOW.cfg
sudo scp -o LogLevel=ERROR /tmp/configdump_run $USER@$IP:$CONFIGPATH/$HOSTNAME-run-latest.cfg
sudo scp -o LogLevel=ERROR /tmp/configdump_run_diff $USER@$IP:$CONFIGPATH/$HOSTNAME-run-$NOW-diff.cfg
sleep 1
rm -rf /tmp/configdump_run_diff
rm -rf /tmp/configdump_run

# Capturing Startup-config
FastCli -p 15 -c 'show start >> file:/tmp/configdump_start'
sleep 1
sudo scp -o LogLevel=ERROR /tmp/configdump_start $USER@$IP:$CONFIGPATH/$HOSTNAME-start-$NOW.cfg
sudo scp -o LogLevel=ERROR /tmp/configdump_start $USER@$IP:$CONFIGPATH/$HOSTNAME-start-latest.cfg
sleep 1
rm -rf /tmp/configdump_start

# Backing up files on flash
tar -cf /tmp/flash_backup.tar /mnt/flash/*.* --exclude='*.swi'
sleep 1
sudo scp -o LogLevel=ERROR /tmp/flash_backup.tar $USER@$IP:$CONFIGPATH/$HOSTNAME-flash-$NOW.tar
sleep 1
rm -rf /tmp/flash_backup.tar


# Optional (not recommended) - Automatic save of the runnning-config as startup-config
# FastCli -p 15 -c 'copy run start'


