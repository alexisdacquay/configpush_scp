#!/bin/bash
# by Alexis Dacquay, ad@arista.com
# version 1.31
#
# examples of aliases and command examples to setup this script:
# alias backup bash /mnt/flash/configpush_scp.sh 1.1.1.1
#
# automated backup on config save:
# event-handler config-push
#   trigger on-startup-config
#   action bash /mnt/flash/configpush_scp.sh 1.1.1.1

if [ ! $1 ]; then
 echo "Usage: configpush_scp.sh <DESTINATION IP>"
 exit 0
fi

echo "Informational: Automated SCP transfer requires that SSH keys are setup"
# Example, from Arista EOS kernel bash :
# sudo cat /persist/secure/ssh_host_dsa_key.pub | ssh user@server 'cat >> .ssh/authorized_keys'

IP=$1
NOW=$(date +%Y-%m-%d.%H%M%S)
USER='user'
CONFIGPATH='MyPath/configs'

# Capturing Running-config and diff
echo '-------------------- diff running-config <> startup-config ------------------------' >> /tmp/configdump_run
FastCli -p 15 -c 'show run diff >> file:/tmp/configdump_run'
sleep 1
echo '--------------------------------- sh run -----------------------------------------' >> /tmp/configdump_run
FastCli -p 15 -c 'show run >> file:/tmp/configdump_run'
sleep 1
sudo scp /tmp/configdump_run $USER@$IP:$CONFIGPATH/$HOSTNAME-run-$NOW.cfg
sudo scp /tmp/configdump_run $USER@$IP:$CONFIGPATH/$HOSTNAME-run-latest.cfg
sleep 1
rm -rf /tmp/configdump_run

# Capturing Startup-config
FastCli -p 15 -c 'show start >> file:/tmp/configdump_start'
sleep 1
sudo scp /tmp/configdump_start $USER@$IP:$CONFIGPATH/$HOSTNAME-start-$NOW.cfg
sudo scp /tmp/configdump_start $USER@$IP:$CONFIGPATH/$HOSTNAME-start-latest.cfg
sleep 1
rm -rf /tmp/configdump_start

# Backing up files on flash
tar -cf /tmp/flash_backup.tar /mnt/flash/*.* --exclude='*.swi'
sleep 1
sudo scp /tmp/flash_backup.tar $USER@$IP:$CONFIGPATH/$HOSTNAME-flash-$NOW.tar
sleep 1
rm -rf /tmp/flash_backup.tar


# Optional (not recommended) - Automatic save of the runnning-config as startup-config
# FastCli -p 15 -c 'copy run start'


