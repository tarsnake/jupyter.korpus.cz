#!/bin/sh

systemctl stop nginx
letsencrypt renew -nvv --standalone > /var/log/letsencrypt/renew.log 2>&1
LE_STATUS=$?
systemctl start nginx
if [ "$LE_STATUS" != 0 ]; then
    echo Automated letsencrypt renewal failed:
    cat /var/log//letsencrypt/renew.log
    exit 1
else
    echo "$0: No errors."
fi
