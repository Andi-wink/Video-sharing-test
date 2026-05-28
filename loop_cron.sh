#!/bin/bash
LOGFILE="/home/user/Video-sharing-test/loop.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if service cron status > /dev/null 2>&1; then
  CRON_STATUS="running"
else
  apt-get install -y cron > /dev/null 2>&1
  service cron start > /dev/null 2>&1
  CRON_STATUS="started"
fi

echo "[$TIMESTAMP] cron=$CRON_STATUS" >> "$LOGFILE"
