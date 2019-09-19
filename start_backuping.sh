#!/bin/bash

sendmail=it@adler.com.ua

./backup_to_ssh.sh > backup.log

backup_log=$(cat ./backup.log)

subject="Subject: backup"

echo "$subject" "$backup_log" | /usr/sbin/ssmtp $sendmail
