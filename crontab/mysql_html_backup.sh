#!/bin/bash

# Bash script to backup MySQL database and /var/www/html/*
# TODO: Remove sudo -u <user>, to make script running under root user

DATE=`date +"%Y%m%d_%H%M"`
BK_DEST="/onedrive/"
NUMBER_OF_BACKUPS=30

DATABASES=$(mysql -sN -e 'show databases' | grep db_)

cd /tmp

for DB in $DATABASES
do
    echo "$(date): backup $DB"
    mysqldump --single-transaction ${DB} | gzip -c  > ./${DB}_${DATE}.sql.gz

    # copy to onedrive and remove from /tmp
    sudo -u nghia.le -- bash -c "[ ! -d /onedrive/databases/${DB}/ ] && mkdir /onedrive/databases/${DB}/ "
    sudo -u nghia.le -- bash -c "cp ./${DB}_${DATE}.sql.gz /onedrive/databases/${DB}/ "
    rm ./${DB}_${DATE}.sql.gz

    # remove older backup
    CURRENT_NUMBER_OF_BACKUPS=$(sudo -u nghia.le -- bash -c "ls /onedrive/databases/${DB}/ | wc -l ")
    if [ $CURRENT_NUMBER_OF_BACKUPS -ge $NUMBER_OF_BACKUPS ]; then
        while [ $CURRENT_NUMBER_OF_BACKUPS -gt $NUMBER_OF_BACKUPS ]
        do
            BK_TO_BE_REMOVED=$(sudo -u nghia.le -- bash -c "ls -tr /onedrive/databases/${DB}/ | head -n1 ")
            echo "$(date): remove older backup $BK_TO_BE_REMOVED"
            sudo -u nghia.le -- bash -c "rm /onedrive/databases/${DB}/$BK_TO_BE_REMOVED"
            ((CURRENT_NUMBER_OF_BACKUPS--))
        done
    fi
    echo "$(date): remaining backup: $CURRENT_NUMBER_OF_BACKUPS"
done


# backup /var/www/html/*
cd /var/www/html

HTML_DIRS=$(ls /var/www/html/)
for DIR in $HTML_DIRS
do
    if [ -d /var/www/html/$DIR ] ; then
        echo "$(date): backup $DIR directory"
        tar czf /tmp/${DIR}_${DATE}.tar.gz $DIR

        # copy to onedrive and remove from /tmp
        sudo -u nghia.le -- bash -c "[ ! -d /onedrive/web/${DIR}/ ] && mkdir /onedrive/web/${DIR}/ "
        sudo -u nghia.le -- bash -c "cp /tmp/${DIR}_${DATE}.tar.gz /onedrive/web/${DIR}/ "
        rm /tmp/${DIR}_${DATE}.tar.gz

        # remove older backup
        CURRENT_NUMBER_OF_BACKUPS=$(sudo -u nghia.le -- bash -c "ls /onedrive/web/${DIR}/ | wc -l ")
        if [ $CURRENT_NUMBER_OF_BACKUPS -ge $NUMBER_OF_BACKUPS ]; then
            while [ $CURRENT_NUMBER_OF_BACKUPS -gt $NUMBER_OF_BACKUPS ]
            do
                BK_TO_BE_REMOVED=$(sudo -u nghia.le -- bash -c "ls -tr /onedrive/web/${DIR}/ | head -n1 ")
                echo "$(date): remove older backup $BK_TO_BE_REMOVED"
                sudo -u nghia.le -- bash -c "rm /onedrive/web/${DIR}/$BK_TO_BE_REMOVED"
                ((CURRENT_NUMBER_OF_BACKUPS--))
            done
        fi
        echo "$(date): remaining backup: $CURRENT_NUMBER_OF_BACKUPS"
    fi
done
