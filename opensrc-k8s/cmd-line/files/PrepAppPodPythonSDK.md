# Pre-requisites for prepping POD for Python SDK

## Create app pod and prep it

App pod yaml !file[https://raw.githubusercontent.com/ramdhakne/blogs/master/external-connectivity/assets/app_pod.yaml] is here

Create app pod 

```
$ kubectl create -f app_pod.yaml

```

Exec into the pod via command line

```
$ kubectl exec -ti app01 bash
	root@app01:/#
```

Prepping the pod (ubuntu OS):
 
```
apt-get -y update
apt-get install -y wget
apt-get install -y git
apt-get -y install dnsutils
apt-get -y install curl
apt install -y python-pip
wget http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-4-amd64.deb
dpkg -i couchbase-release-1.0-4-amd64.deb
apt-get -y update
apt-get -y install libcouchbase-dev build-essential python-dev python-pip
pip install git+http://github.com/couchbase/couchbase-python-client@2.5.4
wget !file[https://raw.githubusercontent.com/ramdhakne/blogs/master/external-connectivity/assets/app_pod.yaml]
```

### 1. App pod in same namespace

This is a very typical and straightforward scenario, where CB cluster and Application(App) pods are in the same

Within the same namespace, any pod can resolve other pod via kube-dns, like below

```
	root@app01:/# nslookup cb-gke-demo-0000.cb-gke-demo.default.svc
Server:         10.55.240.10
Address:        10.55.240.10#53

Non-authoritative answer:
Name:   cb-gke-demo-0000.cb-gke-demo.default.svc.cluster.local
Address: 10.52.1.12
```


Python SDK file is !here[https://raw.githubusercontent.com/ramdhakne/blogs/master/external-connectivity/python/python_sdk_example.py].

Edit the connection string in the program above for line #18. Client will bootstrap with the cluster, find the # of nodes in the cluster, fetch the cluster map, open the connection with the bucket, and perform bucket operations 

Connection string for my program

```
cluster =  Cluster(‘couchbase://10.52.2.11,10.52.1.8,10.52.5.6 ’)
```

Note: Python SDK is installed at this point.

#### Executing the program.

```
root@app01:/# python python_sdk_example.py
```

## 2. App pod in the different namespace
	
Create pod in the different namespace, first create namespace

```
$ kubectl create namespace apps
``` 

Create pod

```
$ kubectl create -f app_pod.yaml -n apps
```

The app pod is in the different namespace. When FQDN is used, kube-dns helps with resolving the hostname with IP addresses and app pods can talk to CB cluster running in different namespace.

```
root@app01:/# nslookup cb-gke-demo-0000.cb-gke-demo.default.svc
Server:         10.55.240.10
Address:        10.55.240.10#53

Non-authoritative answer:
Name:   cb-gke-demo-0000.cb-gke-demo.default.svc.cluster.local
Address: 10.52.1.12
```

Python SDK file is !here[https://raw.githubusercontent.com/ramdhakne/blogs/master/external-connectivity/python/python_sdk_example.py].

Edit the connection string in the program above for line #18. Client will bootstrap with the cluster, find the # of nodes in the cluster, fetch the cluster map, open the connection with the bucket, and perform bucket operations 

Note: Python SDK is installed at this point.

Executing the program.

```
root@app01:/# python python_sdk_example.py
```





