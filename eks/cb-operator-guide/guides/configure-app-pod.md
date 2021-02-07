# Deploy Client Pod

You may decide to deploy client application pod in the same namespace as the Couchbase Server, which in our case is ```emart``` or you can do the separation of ownership between application tier and database tier by deploying application in a separate namespace.

## 1. Create a Namespace

We are going to deploy application client in a separate namespace. So let's create the namespace first:

```
$ kubectl create namespace apps
namespace/apps created
```

## 2. Deploy Application Pod

Create the application pod based on the manifestation file [app-centos-pod.yaml](../files/app-centos-pod.yaml)

```
$ kubectl create -f app-centos-pod.yaml --namespace apps
pod/app01 created
```

Verify state of the pod by performing:

```
$ kubectl get pods -n apps

NAME         READY     STATUS    RESTARTS   AGE
client-app   1/1       Running   0          4h10m
```

## 3. Install JRE

We are going to install Java Runtime (JRE) on the pod but first we need to install few other required libraries. So we are going to connect to ```client-app``` pod using ```exec``` command like this:

```
$ kubectl exec -it client-app -n apps -- /bin/bash

root@client-app:/#
```

And then install following list of packages in the pod:

```
yum update -y
yum install -y wget
yum install -y git
yum install -y curl

#install nslookup
yum install -y bind-utils

#Install Java
yum install -y java-11-openjdk

```

Please follow the prompts carefully and copy/paste the paths where required. Once all of the above packages are installed verify the JRE version to be 1.8 or above:

```
java -version

openjdk version "11.0.10" 2021-01-19 LTS
OpenJDK Runtime Environment 18.9 (build 11.0.10+9-LTS)
OpenJDK 64-Bit Server VM 18.9 (build 11.0.10+9-LTS, mixed mode, sharing)   
```
In actual production environment you would just be pulling your pod image where all the required libraries will be installed, including JDK/JRE.
