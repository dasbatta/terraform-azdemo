#!/bin/bash
mongodump --username backupuser --password ${mongo_password} --archive=mongo-backups/mongodb_backup_$(date +%F_%T).gz --gzip
az storage blob upload --account-name ${storage_account_name} --container-name ${container_name} --file mongo-backups/* --output none
rm mongo-backups/*
