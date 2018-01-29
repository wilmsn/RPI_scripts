#!/bin/bash
#########################################################
#
# Sichert die wichtigsten Dateien auf dem Webspace von T-Online
# Startet taeglich
#
#
#########################################################
HOST=$(hostname)
PRODSERVER=rpi1
TONL_DIR=${HOST}
TONL_MNT_DIR=/t-online/pl
LOCAL_DIR=/backup/backup
WEB_DIR=./sd_p2/web
HOME_DIR=./sd_p2/home
ETC_DIR=./etc
WIKI_DAT_DIR="./sd_p2/web/wiki_images"
MEDIAWIKIDIR="./sd_p2/web/"$(ls -1 /sd_p2/web | grep mediawiki | grep "-")
#
PATH=/bin:/usr/bin:/usr/sbin
SUBDIR=$1
if [ "${SUBDIR}" = "longtime" ]; then
  DATESTR=$(date +%y%m)
else
  DATESTR=$(date +%y%m%d)
fi
DAV_USER=$(cat /etc/davfs2/secrets | grep "t-online/pl" | cut -d " " -f 2)
DAV_PASSWD=$(cat /etc/davfs2/secrets | grep "t-online/pl" | cut -d " " -f 3)
DB_DUMP=all_db_${DATESTR}.dump.xz
RPI_TGZ=${HOST}_${DATESTR}.txz
export PATH DATESTR
SUBDIR=$1
#
if ! grep -qs '/t-online/pl' /proc/mounts; then
   mount -t davfs  https://webdav.mediencenter.t-online.de/ /t-online/pl
   echo "Mount /t-online/pl"
fi

if [ ! -d ${TONL_MNT_DIR}/${TONL_DIR} ]; then
  mkdir ${TONL_MNT_DIR}/${TONL_DIR}
  chmod 777 ${TONL_MNT_DIR}/${TONL_DIR}
fi
if [ ! -d ${LOCAL_DIR} ]; then
  mkdir ${LOCAL_DIR}
fi
if [ -n "${SUBDIR}" ]; then
  TONL_DIR=${TONL_DIR}/${SUBDIR}
  LOCAL_DIR=${LOCAL_DIR}/${SUBDIR}
  if [ ! -d ${TONL_MNT_DIR}/${TONL_DIR} ]; then
    mkdir ${TONL_MNT_DIR}/${TONL_DIR}
    chmod 777 ${TONL_MNT_DIR}/${TONL_DIR}
  fi
  if [ ! -d ${LOCAL_DIR} ]; then
    mkdir ${LOCAL_DIR}
    chmod 777 ${LOCAL_DIR}
  fi
fi
#
# Backup der Backup Skripte
#
curl --upload-file /usr/bin/backup.sh --user ${DAV_USER}:${DAV_PASSWD} https://webdav.mediencenter.t-online.de/${TONL_DIR}/backup_${DATESTR}.sh
curl --upload-file /usr/bin/backup_sd.sh --user ${DAV_USER}:${DAV_PASSWD} https://webdav.mediencenter.t-online.de/${TONL_DIR}/backup_sd_${DATESTR}.sh
#
# Dump aller MariaDB Datenbanken
#
mysqldump -A -Y --add-drop-database --force --lock-all-tables | xz - > ${LOCAL_DIR}/${DB_DUMP}
curl --upload-file ${LOCAL_DIR}/${DB_DUMP} --user ${DAV_USER}:${DAV_PASSWD} https://webdav.mediencenter.t-online.de/${TONL_DIR}/${DB_DUMP}
#
# Backup via tar und xz
#
cd /
tar --exclude bilder --exclude ${MEDIAWIKIDIR} --exclude wiki-images -cJf ${LOCAL_DIR}/${RPI_TGZ} ${WEB_DIR}  ${ETC_DIR} ${HOME_DIR}
curl --upload-file ${LOCAL_DIR}/${RPI_TGZ} --user ${DAV_USER}:${DAV_PASSWD} https://webdav.mediencenter.t-online.de/${TONL_DIR}/${RPI_TGZ}
#
# Alte Dateien löschen
#
if [ "${SUBDIR}" != "longtime" ]; then
  find -P ${TONL_MNT_DIR}/${TONL_DIR}  -maxdepth 1 -type f -name '*xz' -ctime +14 -delete
  find -P ${TONL_MNT_DIR}/${TONL_DIR}  -maxdepth 1 -type f -name '*sh' -ctime +14 -delete
  find -P ${LOCAL_DIR}  -maxdepth 1 -type f -name '*dump.xz' -ctime +32 -delete
  find -P ${LOCAL_DIR}  -maxdepth 1 -type f -name '*.txz' -ctime +5 -delete
fi

