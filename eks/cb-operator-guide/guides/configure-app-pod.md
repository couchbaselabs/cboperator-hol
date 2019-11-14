# Deploy Client Pod

You may decide to deploy client application pod in the same namespace as the Couchbase Server, which in our case is ```emart``` or you can do the separation of ownership between application tier and database tier by deploying application in a separate namespace.

## 1. Create a Namespace

We are going to deploy application client in a separate namespace. So let's create the namespace first:

```
$ kubectl create namespace apps
namespace/apps created
```

## 2. Deploy Application Pod

Create the application pod based on the manifestation file [app_pod.yaml](../files/app-pod.yaml)

```
$ kubectl create -f app-pod.yaml --namespace apps
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
$ apt-get -y update
$ apt-get install -y wget
$ apt-get install -y git
$ apt-get -y install curl

#install nslookup
$ apt-get -y install dnsutils

#Install Java
$ apt-get install software-properties-common
$ add-apt-repository ppa:jonathonf/openjdk
$ apt-get update
$ apt-get install openjdk-8-jre

# Set Latest Java Version
$ update-java-alternatives -l
$ update-java-alternatives -s /usr/lib/jvm/java-1.8.0-openjdk-amd64

```

Please follow the prompts carefully and copy/paste the paths where required. Once all of the above packages are installed verify the JRE version to be 1.8 or above:

```
$java -version

openjdk version "1.8.0_222"
OpenJDK Runtime Environment (build 1.8.0_222-8u222-b10-1ubuntu2~14.04.york0-b10)
OpenJDK 64-Bit Server VM (build 25.222-b10, mixed mode)   
```
In actual production environment you would just be pulling your pod image where all the required libraries will be installed, including JDK/JRE.
