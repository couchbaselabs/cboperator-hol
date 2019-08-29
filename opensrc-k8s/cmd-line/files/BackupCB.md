# Backup CB cluster via cbbackupmgr

## Create backup repo on given backup mount/volume


```
$ cbbackupmgr config --archive /tmp/data/ --repo myBackupRepo
Backup repository `myBackupRepo` created successfully in archive `/tmp/data/`
```

## Backup
```
$ cbbackupmgr backup -c couchbase://127.0.0.1 -u Administrator -p password -a /tmp/data/ -r myBackupRepo
```

## Restore
```
# use --force-updates to use all updates from backup repo rather than current state of cluster
$ cbbackupmgr restore -c couchbase://127.0.0.1 -u Administrator -p password -a /tmp/data/ -r myBackupRepo --force-updates
```


