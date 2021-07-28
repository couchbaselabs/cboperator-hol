## Couchbase restore step


1. Create a pod definition file called restore-cb-pod.yaml and paste the below yaml changing the volumes, volumeMounts and namespace if they are different.

```YAML
apiVersion: v1
kind: Pod
metadata:
  name: restore-node
  namespace: cbns
spec:  # specification of the pod's contents
  containers:
    - name: restore-pod
      image: couchbase/server:enterprise-6.5.0
      # Just spin & wait forever
      command: [ "/bin/bash", "-c", "--" ]
      args: [ "while true; do sleep 30; done;" ]
      volumeMounts:
        - name: "couchbase-cluster-backup-volume"
          mountPath: "/backups"
  volumes:
    - name: couchbase-cluster-backup-volume
      persistentVolumeClaim:
        claimName: backup-pvc
  restartPolicy: Never
```

2. Apply restore-cb-pod.yaml.

```
kubectl apply -f  restore-cb-pod.yaml
```

3. Access the `restore-node` pod.

```
kubectl exec -it restore-node -n cbns -- /bin/bash
```

4. Choose the backup of choice

```
cbbackupmgr list --archive /backups --repo couchbase
```

We will choose the oldest we received from the command above 2021-02-20T11_06_13.123456Z

5. Preform the restore using the cbbackupmgr command.

```
cbbackupmgr restore --archive /backups --repo couchbase --cluster cbgluu.cbns.svc.cluster.local --username admin --password passsword --start 2021-02-20T11_06_13.123456Z --end 2021-02-20T12_05_13.781131773Z
```

Learn more about [cbbackupmgr](https://docs.couchbase.com/server/current/backup-restore/cbbackupmgr-restore.html) command and its options.

6. Once done delete the restore-node pod.

```
kubectl delete -f restore-cb-pod.yaml -n cbns
```
