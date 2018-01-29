#!/bin/bash
#########################################################
#
# Sichert die SD Karte mittels dd (nur die ersten 3GB)
# Die zweite Partition (gemounted unter /sd_p2) wird als tar gesichert
# Zusaetzlich werden alle Maria/Mysql Datenbanken gesichert
#
# Startet monatlich am 1.
#
#########################################################
PATH=/bin:/usr/bin:/usr/sbin
export PATH
DATESTR=$(date +%y%m)
HOSTNAME=$(hostname)
BACKUPDIR=/backup/backup_sd
DAV_USER=$(cat /etc/davfs2/secrets | grep "/t-online/pl" | cut -d " " -f 2)
DAV_PASSWD=$(cat /etc/davfs2/secrets | grep "t-online/pl" | cut -d " " -f 3)
DB_USER=$(cat /etc/backup_user.txt | grep "dbuser" | cut -d "=" -f 2)
DB_PASSWD=$(cat /etc/backup_user.txt | grep "dbpasswd" | cut -d "=" -f 2)

if [ ! -d ${BACKUPDIR} ]; then
  mkdir -p ${BACKUPDIR}
fi
dd if=/dev/mmcblk0 bs=1M count=3000 | xz > ${BACKUPDIR}/${HOSTNAME}_sd_${DATESTR}.dd.img.xz
curl --upload-file ${BACKUPDIR}/${HOSTNAME}_sd_${DATESTR}.dd.img.xz --user ${DAV_USER}:${DAV_PASSWD} https://webdav.mediencenter.t-online.de/${HOSTNAME}/backup_sd/${HOSTNAME}_sd_${DATESTR}.dd.img.xz
cd /sd_p2
tar cJf  ${BACKUPDIR}/${HOSTNAME}_sd_p3_${DATESTR}.txz * --exclude ./database --exclude ./cache
curl --upload-file ${BACKUPDIR}/${HOSTNAME}_sd_p3_${DATESTR}.txz --user ${DAV_USER}:${DAV_PASSWD} https://webdav.mediencenter.t-online.de/${HOSTNAME}/backup_sd/${HOSTNAME}_sd_p3_${DATESTR}.txz
mysqldump -u ${DB_USER} -p${DB_PASSWD} --all-databases | xz >  ${BACKUPDIR}/${HOSTNAME}_db_${DATESTR}.sql.xz
curl --upload-file ${BACKUPDIR}/${HOSTNAME}_db_${DATESTR}.sql.xz --user ${DAV_USER}:${DAV_PASSWD} https://webdav.mediencenter.t-online.de/${HOSTNAME}/backup_sd/${HOSTNAME}_db_${DATESTR}.sql.xz

