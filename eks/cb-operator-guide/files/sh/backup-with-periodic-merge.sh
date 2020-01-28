#!/bin/bash


#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#  Function _usage
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function _usage
{
   echo "Usage: ./backup-with-periodic-merge.sh [options]"
   echo "This script will take a cluster wide backup first and will keep specified number of restorepoints by merging backups older than restorepoints."
   echo "    Options:"
   echo "	--archive=<s>           Directory where backups would be archived (default: /backups)"
   echo "	--repo=<s>              Repository name used for the backup (default: couchbase)"
   echo "	--cluster=<s>           The cluster address (default: localhost)"
   echo " --username=<s>          Cluster Admin or RBAC username (default: Administrator)"
   echo "	--password=<s>          Cluster Admin or RBAC password (default: password)"
   echo "	--threads=<n>           Number of threads used for backup process (default: 2)"
   echo "	--restorepoints=<n>     Number of backups at any given time for restore during outage (default: 3)"
   exit 5
}

# set the defaults, these can all be overriden as environment variables or passed via the cli
CB_USERNAME=${CB_USERNAME:='Administrator'}
CB_PASSWORD=${CB_PASSWORD:='password'}
CLUSTER=${CLUSTER:='localhost'}
ARCHIVE=${ARCHIVE:='/backups'}
REPO=${REPO:='couchbase'}
THREADS=${THREADS:=2}
RESTOREPOINTS=${RESTOREPOINTS=3}

#***************************************************************************#
BACKUPREGEX="[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}_[0-9]{2}_[0-9]{2}.[0-9]{6}"
CBBACKUPMGR=cbbackupmgr

# parse any cli arguments
while [ $# -gt 1 ]
do
  case $1 in
    --username ) CB_USERNAME=$2
      shift 1
      ;;
    --password ) CB_PASSWORD=$2
      shift 1
      ;;
    --cluster ) CLUSTER=$2
      shift 1
      ;;
    --archive ) ARCHIVE=$2
      shift 1
      ;;
    --threads ) THREADS=$2
      shift 1
      ;;
    --restorepoints ) RESTOREPOINTS=$2
      shift 1
      ;;
    --repo ) REPO=$2
      shift 1
      ;;
    *)
      echo ERROR : Invalid command line option :  "$1"
      _usage
     ;;
  esac
  shift
done

# make sure cbbackupmgr is in the PATH
type $CBBACKUPMGR >/dev/null 2>&1 || {
  echo >&2 "Please make sure COUCHBASE_HOME/bin directory is set to the PATH variable";
  exit 1;
}


#########################################################################################
### Couchbase Backup run in 4 steps:
###    1) Full/delta backup
###    2) Compact last backup
###    3) Merge
#########################################################################################
############## STEP 1 : BACKUP
echo "---------------------------------------------------------"
echo  BEGIN STEP 1: BACKUP : "$(date)"
CMD="${CBBACKUPMGR} backup  --archive $ARCHIVE --repo $REPO --cluster couchbase://${CLUSTER} --username $CB_USERNAME --password $CB_PASSWORD --threads ${THREADS}"
echo -e "Running backup... \n Command:  $CMD"
eval "$CMD"

############## STEP 2 : COMPACT BACKUP
echo "---------------------------------------------------------"
echo  BEGIN STEP 2: COMPACTION : "$(date)"
BACKUPLIST=$("${CBBACKUPMGR}" list --archive "${ARCHIVE}" --repo "${REPO}" | awk '{print $NF}' | grep -E "${BACKUPREGEX}")
echo -e "List of backup snapshots ... \n\n$BACKUPLIST"
LASTBACKUP=$(echo "${BACKUPLIST}" | sed '$!d')
echo Last backup name is: "${LASTBACKUP}"
CMD="${CBBACKUPMGR} compact --archive ${ARCHIVE} --repo ${REPO} --backup ${LASTBACKUP}"
echo -e "Compacting the backup...\n Command: ${CMD}"
eval "$CMD"

############## STEP 3 : MERGING OLD BACKUPS
echo "---------------------------------------------------------"
echo  BEGIN STEP 3: Merging old backup : "$(date)"
COUNT=$(echo "${BACKUPLIST}" | wc -l)
eval "${CBBACKUPMGR}" list --archive "${ARCHIVE}" --repo "${REPO}"

if [ "$COUNT" -gt "$RESTOREPOINTS" ]; then
  START=$(echo "${BACKUPLIST}" | sed -n 1p)
  END=$(echo "${BACKUPLIST}" | sed -n $((1+COUNT-RESTOREPOINTS))p)
  echo -e "Start $START, END $END"
  CMD="${CBBACKUPMGR} merge --archive ${ARCHIVE} --repo ${REPO} --start ${START} --end ${END}"
  echo -e "Merging old backups...\n Command: ${CMD}"
  eval "$CMD"
fi

eval "${CBBACKUPMGR}" list --archive "${ARCHIVE}" --repo "${REPO}"
