# Couchbase Operator deployment for Open Source Kubernetes with minikube

## Scope
	Setup couchbase operator 1.2 on open source kubernetes using minikube
	The deployment would be using command line tools to deploy 
	
## Overview of the hand on labs
	Pre-requisities
	Env details
	Deploy adminission controller
	Deploy Couchbase Autonomous Operator
	Deploymnent Couchbase Cluster with following details
		* PV 
		* TLS certificates
	

## Pre-requisites
* CLI / UI

	`$ brew update`
	 
* Install hypervisor from link below

	<https://download.virtualbox.org/virtualbox/6.0.10/VirtualBox-6.0.10-132072-OSX.dmg>

* Install minikube

	`$ brew cask install minikube`

* Install kubectl

	<https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-macos>

* Kubernetes cluster with supported version

* Start minikube

	`$ sudo minikube start`

	`$ sudo kubectl cluster-info`

	
## Environment details
* minikue on macos : v1.2.0

`$ sudo minikube config view`
	
	- cpus: 4
	- memory: 4096
	
## minikube cluster details

	$ sudo kubectl get nodes
	
	NAME       STATUS   ROLES    AGE     VERSION
	minikube   Ready    master   3d11h   v1.15.0
	

### Deploy adminission controller
*	cd into the files dir to access the required yaml files
First we will create a namespace to localize our deployment
	
`$ sudo kubectl create namespace cbdb`

*	Deployment adminission controller

`	$ sudo kubectl create -f admission.yaml --namespace cbdb`	

*	Query the deployment

	```
	$ sudo kubectl get deployments --namespace cbdb
	NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
	couchbase-operator-admission   1/1     1            1           11m
	```
		
## Deploy Couchbase Autonomous Operator
*	Deploy Operator Role

	`sudo kubectl create -f operator-role.yaml --namespace cbdb`
	
*	Create service account

	`sudo kubectl create serviceaccount couchbase-operator --namespace cbdb`
	
*	Bind the service account 'couchbase-operator' with operator-role

	`sudo kubectl create rolebinding couchbase-operator --role couchbase-operator --serviceaccount cbdb:couchbase-operator --namespace cbdb`
	
*	Deploy Custom Resource Definition

	`sudo kubectl create -f operator-deployment.yaml --namespace cbdb`
	
* Query deployment

	```
	
	$ sudo kubectl get deployment --namespace cbdb
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
couchbase-operator             1/1     1            1           20m
couchbase-operator-admission   1/1     1            1           20m
	
	```	

## Deploymnent Couchbase Cluster

### Deploy TLS certs

Link is [here] (https://raw.githubusercontent.com/ramdhakne/blogs/master/external-connectivity/x509-help.txt)

### Query the TLS secrets
	
```
$ sudo kubectl get secrets --namespace cbdb
NAME                                       TYPE                                  DATA   AGE
couchbase-operator-tls                     Opaque                                1      14h
couchbase-server-tls                       Opaque                                2      14h
```

### Deploy secret to access Couchbase UI


`sudo kubectl create -f secret.yaml --namespace cbdb`

### Get storageClass details for minikube k8s cluster

```
$ sudo kubectl get storageclass
NAME                 PROVISIONER                AGE
standard (default)   k8s.io/minikube-hostpath   3d14h
```

### Deploy the Couchbase cluster

`sudo kubectl create -f couchbase-persistent-cluster-tls-k8s-minikube.yaml --namespace cbdb`
	
### If everything goes well then we should see the Couchbase cluster deployed with PVs, TLS certs

```
$ sudo kubectl get pods --namespace cbdb
NAME                                            READY   STATUS    RESTARTS   AGE
cb-opensource-k8s-0000                          1/1     Running   0          5h58m
cb-opensource-k8s-0001                          1/1     Running   0          5h58m
cb-opensource-k8s-0002                          1/1     Running   0          5h57m
couchbase-operator-864685d8b9-j72jd             1/1     Running   0          20h
couchbase-operator-admission-7d7d594748-btnm9   1/1     Running   0          20h
```

### Access the Couchbase UI

*	Get the service details for Couchbase cluster

```
$ sudo kubectl get svc --namespace cbdb
NAME              		TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                 AGE                                             6h11m
cb-opensource-k8s-ui   NodePort    10.100.90.161    <none>        8091:30477/TCP,18091:30184/TCP
```

```
$ sudo kubectl port-forward service/cb-opensource-k8s-ui 8091:8091 --namespace cbdb
Forwarding from 127.0.0.1:8091 -> 8091
Forwarding from [::1]:8091 -> 8091
```

#### Couchbase UI

1-cluster-home-page


Verify the root ca to check custom x509 cert is being used

Click Security->Root Certificate

2-root-ca-page


Delete a pod at random, lets delete pod 001

```
$ sudo kubectl delete pod cb-opensource-k8s-0001 --namespace cbdb
pod "cb-opensource-k8s-0001" deleted
```

Server would automatically failover, depending on the autoFailovertimeout

3-svr-autofailover

A lost couchbase is auto-recovered by Couchbase Operator as its contantly watching cluster definition

4-auto-rebalance

	
## Cleanup

```
sudo kubectl delete -f secret.yaml --namespace cbdb
sudo kubectl delete -f couchbase-persistent-cluster-tls-k8s-minikube.yaml --namespace cbdb
sudo kubectl delete rolebinding couchbase-operator --namespace cbdb
sudo kubectl delete serviceaccount couchbase-operator --namespace cbdb
sudo kubectl delete -f operator-deployment.yaml --namespace cbdb
sudo kubectl get deployments --namespace cbdb
sudo kubectl delete -f admission.yaml --namespace cbdb
```