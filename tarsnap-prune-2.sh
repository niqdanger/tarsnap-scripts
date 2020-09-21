#!/usr/bin/env bash

# Tarsnap backup script
# Written by Tim Bishop, 2009.
# Modified by Pronoiac, 2014. 
# Modified by niqdanger for hackermonkey, 2020
#     only care about daily/weeky. Dont want Hourly/monthly

# Directories to backup - set in
CONFIG=/root/etc/tarsnap-cron.conf

# note: this evals the config file, which can present a security issue
# unless it's locked with the right permissions - e.g. not world-writable
if [ ! -r "$CONFIG" ] ; then 
    echo "ERROR: Couldn't read config file $CONFIG"
    echo Exiting now!
    exit 1
fi

source $CONFIG

# end of config

FILTER=""
SAVE=""
FILESAVE=""
RED='\033[0;31m' # RED
NC='\033[0m' # NO COLOR


# Make array of dates to keep
# iterate through week
for (( DAYS=0; DAYS<=$DAILY; DAYS++ ))
do
	SAVE=$(date -d "-$DAYS days" "+%Y-%m-%d")
	FILTER="$FILTER $SAVE"
done
# Weekly ; check DAYOFWEEKLY in tarsnap.conf - if not there, it gets Mondays
if [ -z $DAYOFWEEKLY ]; then
	DAYOFWEEKLY="Mondays"
fi
for (( WEEKS=1; WEEKS<=$WEEKLY; WEEKS++ ))
do
	SAVE=$(date -d "-$WEEKS weeks $DAYOFWEEKLY" "+%Y-%m-%d")
	FILTER="$FILTER $SAVE"
done

# Get current backup list
CURBACKUPS=$(tarsnap --list-archive | sort)

# Find the backups to save
for i in ${CURBACKUPS[@]}; do
	for datef in ${FILTER[@]}; do
		FILESAVE="$FILESAVE $(echo $i | grep $datef)"
	done
done

# Show all files, highlight files to be deleted in red
if [ "$1" = "dryrun" ]; then
  echo "Files to be deleted are shown in red:"
  for i in ${CURBACKUPS[@]}; do
	if [[ ! " ${FILESAVE[@]} " =~ " $i " ]]; then
		printf "${RED}$i${NC}\n"
	else
		printf "$i\n"
	fi
  done
  exit 0
fi

# Remove backups no longer needed
for i in ${CURBACKUPS[@]}; do
      if [[ ! " ${FILESAVE[@]} " =~ " $i " ]]; then
              # tarsnap delete!
	      printf "Deleting ${RED}$i${NC}\n"
	      $TARSNAP --configfile /etc/tarsnap.conf -d -f $i
      fi
done
