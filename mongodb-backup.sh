#!/bin/bash
################################################################################################
#### Scripname:         mongodb-backup.sh
#### Description:       This is script is performing a mongodump and is deleting older dumps
#### Version:           1.0 | Matthias Olbrich
################################################################################################

#### Time Function for logs
_currtime() {
  echo "$(date +"%Y-%m-%dT%H:%M:%S.%3N%z")"
}

#### Declare variables from parameter file
source mongodb-backup.par

#### Constants
TIMESTAMP=`date +%F-%H%M`                                                       ## Variable with date for file names
LOGDIR=${BACKUPDIR}/log                                                         ## Location of the logs
DUMPLOG=${LOGDIR}/mongodump_${TIMESTAMP}_${REPLICASET}_${HOSTNAME}.log          ## Dump log name
CLEANLOG=${LOGDIR}/cleanup_${TIMESTAMP}_${REPLICASET}_${HOSTNAME}.log           ## Dump removal log name

echo "$(_currtime) - Script start" | tee -a ${DUMPLOG}

#### Check if log dirs exists, if not create dir
if [ ! -d "${LOGDIR}" ]; then
  mkdir -p ${LOGDIR}
fi

#### Check if mongodump-binaries exists
if [ ! -x ${MONGODUMP} ]; then
  echo "$(_currtime) - Cannot find mongodump at location ${MONGODUMP}, abort" | tee -a ${DUMPLOG}
  echo "$(_currtime) - Script ends"                                                             | tee -a ${DUMPLOG}
  mv ${DUMPLOG} ${DUMPLOG}.FAILED
  exit 1
fi

#### Check if backup dir exists
if [ ! -d "${BACKUPDIR}" ]; then
  echo "$(_currtime) - Backup dir ${BACKUPDIR} doesn't exists, abort"   | tee -a ${DUMPLOG}
  echo "$(_currtime) - Script ends"                                                             | tee -a ${DUMPLOG}
  mv ${DUMPLOG} ${DUMPLOG}.FAILED
  exit 1
fi

echo "$(_currtime) - Backup dir is $BACKUPDIR"  | tee -a ${DUMPLOG}
echo "$(_currtime) - Backup retention is $RETENTION days" | tee -a ${DUMPLOG}
echo "$(_currtime) - Log is $DUMPLOG"           | tee -a ${DUMPLOG}
echo "$(_currtime) - Cleanlog is $CLEANLOG"    | tee -a ${DUMPLOG}

#### Check FS utilisation of backup dir, if yellow >85% give warning and if red >98% script stop
df -H ${BACKUPDIR} | tail -n +2 | awk '{ print $5 " " $6 }' | while read output; do
  usep=$(echo $output | awk '{print $1}' | cut -d'%' -f1)
  partition=$(echo $output | awk '{ print $2 }' )

  if [ "${usep}" -ge 98 ]; then
    echo "$(_currtime) - Critical, FS of backup dir is running out of space \"$partition ($usep% utilisation)\"" | tee -a ${DUMPLOG}
    echo "$(_currtime) - Script ends" | tee -a ${DUMPLOG}
    mv ${DUMPLOG} ${DUMPLOG}.FAILED
    exit 1
  elif [ "${usep}" -ge 85 ]; then
    echo "$(_currtime) - Warning, FS utilisation of backup dir is high \"$partition ($usep% utilisation)\""     | tee -a ${DUMPLOG}
  else
    echo "$(_currtime) - FS utilisation of backup dir is \"$partition ($usep% utilisation)\""                                   | tee -a ${DUMPLOG}
  fi
done

#### Perform mongodump
echo "$(_currtime) - Mongodump is processing..." | tee -a ${DUMPLOG}
${MONGODUMP} --uri="${URI}" --out "${BACKUPDIR}/mongodump_${TIMESTAMP}_${REPLICASET}_${HOSTNAME}" < ${PWLOC} >> ${DUMPLOG} 2>&1
BCK_RC=${?}

#### Error handling
if [ ${BCK_RC} -ne 0 ]; then
  tail -1 ${DUMPLOG}
  echo "$(_currtime) - Dump failed, abort"      | tee -a ${DUMPLOG}
  echo "$(_currtime) - Script ends"             | tee -a ${DUMPLOG}
  mv ${DUMPLOG} ${DUMPLOG}.FAILED
  exit 1
fi

#### Cleanup of older backups and logs based on the retention
cd ${BACKUPDIR}
AMOUNTBACKUPS=$(ls -l | grep mongodump_ | wc -l)

echo "$(_currtime) - Current amount of backups ${AMOUNTBACKUPS} ."  | tee -a ${DUMPLOG}

if [ ${AMOUNTBACKUPS} -gt ${RETENTION} ]; then
   for backup in $(find . -maxdepth 1 -type d -mtime +${RETENTION} -name 'mongodump_*'); do
      rm -vrf $backup | tee -a ${CLEANLOG}
   done
else
  echo "$(_currtime) - Just ${AMOUNTBACKUPS} backups available, skip deletion." | tee -a ${DUMPLOG} ${CLEANLOG}
fi

cd ${LOGDIR}
for logfile in $(find . -maxdepth 1 -type f -mtime +90 -name '*.log' -print); do
  rm -vf $logfile | tee -a ${CLEANLOG}
done

echo "$(_currtime) - Backup completed successfully."    | tee -a ${DUMPLOG}
echo "$(_currtime) - Script ends"                       | tee -a ${DUMPLOG}
exit 0