# Content

1. **Prerequisites**
2. **Deploy Couchbase Autonomous Operator** 

	2.1. **Download Operator package**
	
	2.2. **Create a namespace**
	
	2.3. **Install CRD**
	
	2.4. **Create a Operator Role**
	
	2.5. **Create a Service Account**
	
	2.6. **Deploy Couchbase Operator**

	2.7. **Deploy Couchbase cluster using persistent volumes**

	2.8. **X509 Certificates**

	2.9. **Availability Zones**

	2.10. **Create user namespace for Couchbase Client - SDK**
	
3. **Operations**

	3.1. **Scaling - On demand scaling - up & down**

	3.2. **Self-recovery**

	3.3. **Couchbase automated upgrade**

	3.4. **Create backup**
	
4. **Running sample application using SDK** 
	
	
# Scope

![cluster image](assets/cluster-gke.png)

# Prerequisites

There are three important prerequisites before we begin the deployment of Couchbase Autonomous Operator on GKS:
 
1. You have installed Kubernetes and [Google Cloud SDK](https://cloud.google.com/sdk/) on your local machine as described in the [guide](./guides/prerequisite-tools.md).
2. Create Google Account and Setup Google Cloud GKS cluster as per the [GKS Instruction Guide](./guides/gks-setup.md).

In the labs below we will be using europe-west-3 as the region and europe-west-3a/3b/3c as three availability-zones but you can deploy to any region/zones by making minor changes to YAML files in the examples below.


# Deploy Couchbase Autonomous Operator

Before we begin with the setup of Couchbase Operator, run ‘kubectl get nodes’ command from the local machine to confirm GKS cluster is up and running.

![europe-west3 GKE cluster](./assets/step00-gke-cluster-europe-west1.png)

```
$ kubectl get nodes
NAME                                                  STATUS   ROLES    AGE    VERSION
gke-my-cluster-europe-we-default-pool-84400c30-69hb   Ready    <none>   16m    v1.13.7-gke.8
gke-my-cluster-europe-we-default-pool-84400c30-m0bg   Ready    <none>   101s   v1.13.7-gke.8
gke-my-cluster-europe-we-default-pool-a17b09e8-99kt   Ready    <none>   16m    v1.13.7-gke.8
gke-my-cluster-europe-we-default-pool-a17b09e8-x6zr   Ready    <none>   100s   v1.13.7-gke.8
gke-my-cluster-europe-we-default-pool-b1d1dea7-6shq   Ready    <none>   16m    v1.13.7-gke.8
gke-my-cluster-europe-we-default-pool-b1d1dea7-t53z   Ready    <none>   100s   v1.13.7-gke.8
```

After we have tested that we can connect to Kubernetes control plane running on Google Cloud GKS cluster from our local machine, we can now begin with the steps required to deploy Couchbase Autonomous Operator, which is the glue technology enabling Couchbase Server cluster to be managed by Kubernetes.

### 1. Download Operator package

Let’s first begin by downloading the latest [Couchbase Autonomous Operator](https://www.couchbase.com/downloads?family=kubernetes) and unzip onto the local machine. Change directory to the operator folder so we can find YAML files we need to deploy Couchbase operator:


```
$ cd couchbase-autonomous-operator-kubernetes_1.2.0-981_linux-x86_64

$ ls

License.txt			couchbase-cli-create-user.yaml	operator-role-binding.yaml	secret.yaml
README.txt			couchbase-cluster.yaml		operator-role.yaml
admission.yaml			crd.yaml			operator-service-account.yaml
bin				operator-deployment.yaml	pillowfight-data-loader.yaml
```

### 2) Create a namespace

Create a namespace that will allow cluster resources to be nicely separated between multiple users. To do that we will use a unique namespace called **emart** for our deployment and later will use this namespace to deploy Couchbase Cluster.

In your working directory create a [namespace.yaml](files/namespace.yaml) file with this content and save it in the Couchbase operator directory itself:

```
apiVersion: v1
kind: Namespace
metadata:
  name: emart
```
After saving the namespace configuration in a file, run kubectl cmd to create it:

```
$ kubectl create -f namespace.yaml
```
Run get namespace command to confirm it is created successfully:

```
$ kubectl get namespaces

NAME          STATUS   AGE
default       Active   25m
emart         Active   34s
```

From now onwards we will use emart as the namespace for all resource provisioning.

### 3) Install CRD

The first step in installing the Operator is to install the custom resource definition (CRD) that describes the CouchbaseCluster resource type. This can be achieved with the following command:

```
kubectl create -f crd.yaml
```

### 4) Create a Operator Role

Next, we will create a [cluster role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#api-overview) that allows the Operator to access the resources that it needs to run. Since the Operator will manage many different [namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/), it is best to create a cluster role first because you can assign that role to a [service account](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#service-account-permissions) in any namespace.

To create the cluster role for the Operator, run the following command:

```
$ kubectl create -f operator-role.yaml --namespace emart
```

This cluster role only needs to be created once.

### 5) Create a Service Account

After the cluster role is created, you need to create a service account in the namespace where you are installing the Operator. To create the service account:

```
$ kubectl create serviceaccount couchbase-operator --namespace emart
```

Now assign the operator role to the service account:

```
$ kubectl create rolebinding couchbase-operator --role couchbase-operator \
--serviceaccount emart:couchbase-operator --namespace emart

output:

clusterrolebinding.rbac.authorization.k8s.io/couchbase-operator created
```

Now before we proceed further let's make sure all the roles and service accounts are created under the namespace _emart_. To do that run these three checks and make sure each get returns something:

```
Kubectl get roles -n emart
Kubectl get rolebindings -n emart
Kubectl get sa -n emart
```

### 6) Deploy Couchbase Operator

We now have all the roles and privileges for our operator to be deployed. Deploying the operator is as simple as running the operator.yaml file from the Couchbase Autonomous Operator directory.

```
$ kubectl create -f operator-deployment.yaml --namespace emart

output:

deployment.apps/couchbase-operator created
```

Above command will download the Operator Docker image (specified in the operator.yaml file) and creates a deployment, which manages a single instance of the Operator. The Operator uses a deployment so that it can restart if the pod it’s running in dies.

It would take less than a minute for Kubernetes to deploy the Operator and for the Operator to be ready to run.

#### a) Verify the Status of the Deployment

You can use the following command to check on the status of the deployment:

```
  $ kubectl get deployments --namespace emart
```

If you run the this command immediately after the Operator is deployed, the output will look something like the following:

```
NAME           	    DESIRED    CURRENT     UP-TO-DATE      AVAILABLE        AGE
couchbase-operator    1          1          1               0                21s
```
Note: Above output means your Couchbase operator is deployed and you can go ahead with deploying Couchbase cluster next.

#### b) Verify the Status of the Operator

You can use the following command to verify that the Operator has started successfully:

```
$ kubectl get pods -l app=couchbase-operator --namespace emart
```

If the Operator is up and running, the command returns an output where the READY field shows 1/1, such as:

```
NAME                                    READY   STATUS   RESTARTS   AGE
couchbase-operator-f6f7b6f75-wdbtd      1/1     Running  0          57s
```

You can also check the logs to confirm that the Operator is up and running. Look for the message: CRD initialized, listening for events…​ module=controller.

```
$ kubectl logs couchbase-operator-f6f7b6f75-wdbtd --namespace emart --tail 20

output:

time="2019-08-08T19:18:50Z" level=info msg="couchbase-operator v1.2.0 (release)" module=main
time="2019-08-08T19:18:50Z" level=info msg="Obtaining resource lock" module=main
time="2019-08-08T19:18:50Z" level=info msg="Starting event recorder" module=main
time="2019-08-08T19:18:50Z" level=info msg="Attempting to be elected the couchbase-operator leader" module=main
time="2019-08-08T19:18:50Z" level=info msg="I'm the leader, attempt to start the operator" module=main
time="2019-08-08T19:18:50Z" level=info msg="Creating the couchbase-operator controller" module=main
time="2019-08-08T19:18:50Z" level=info msg="Event(v1.ObjectReference{Kind:\"Endpoints\", Namespace:\"emart\", Name:\"couchbase-operator\", UID:\"5a5fb656-ba11-11e9-98c4-42010a840059\", APIVersion:\"v1\", ResourceVersion:\"20334\", FieldPath:\"\"}): type: 'Normal' reason: 'LeaderElection' couchbase-operator-f6f7b6f75-wdbtd became leader" module=event_recorder
```

# Deploy Couchbase cluster using persistent volumes

In a production environment where performance and SLA of the system matters most, we should always plan on deploying Couchbase cluster using persistent volumes because it helps in:

* **Data Recoverability**: Persistent Volumes allow the data associated within Pods to be recovered in the case that a Pod is terminated. This helps prevent data-loss and avoid time-consuming index building when using the data or index services.

* **Pod Relocation**: Kubernetes may decide to evict pods that reach resource thresholds such as CPU and Memory Limits. Pods that are backed with Persistent Volumes can be terminated and restarted on different nodes without incurring any downtime or data-loss.
* **Dynamic Provisioning**: The Operator will create Persistent Volumes on-demand as your cluster scales, alleviating the need to pre-provision your cluster storage prior to deployment.

* **Cloud Integration**: Kubernetes integrates with native storage provisioners available on major cloud vendors such as AWS and GCE.

In this next section we will see how you can define storage classes in different availability zone and build persistent volume claim template, which will be used in [couchbase-cluster-with-pv.yaml](files/couchbase-cluster-with-pv.yaml) file.

### 1) Create Secret for Couchbase Admin Console

First thing we need to do is create a secret credential which will be used by the administrative web console during login. For convenience, a sample secret is provided in the Operator package. When you push it to your Kubernetes cluster, the secret sets the username to Administrator and the password to password.

To push the secret into your Kubernetes cluster, run the following command:

```
$ kubectl create -f secret.yaml --namespace emart

Output:

Secret/cb-example-auth created
```

### 2) Create Google storage class for the GKS cluster

Now in order to use PersistentVolume for Couchbase services (data, index, search, etc.), we need to create Storage Classes (SC) first in each of the Availability Zones (AZ). Let’s begin by checking what storage classes exist in our environment.

Let’s use kubectl command to find that out:
```
$ kubectl get storageclass
NAME                 PROVISIONER            AGE
standard (default)   kubernetes.io/gce-pd   31m
```

Above output means we just have default gce-pd storage class and we need to create separate storage-classes in all of the AZs where we are planning to deploy our Couchbase cluster.

We will run below steps to create three different storage classes of type gce-pd to store data, index and Couchbase binaries.

**1) Create an Google storage class manifest file for your storage class.** Below example defines a storage class that uses the Google gce-pd-ssd volume type. For more information about the options available for GKE storage classes, see [GKE](https://kubernetes.io/docs/concepts/storage/storage-classes/#gke) in the Kubernetes documentation.

* Create a storage definition file [sc-gce-pd-ssd.yaml](files/sc-gce-pd-ssd.yaml) that represent storage class of _pd-ssd_ type (aka general purpose SSD drive), which we will later use it in our _VolumeClaimTemplate_.

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: sc-fast-storage
parameters:
  type: pd-ssd
provisioner: kubernetes.io/gce-pd
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```
We have used reclaimPolicy to _Delete_ which tells K8 to delete the volumes of deleted Pods but you can change it to _Retain_ depending on your needs or if for troubleshooting purpose you would like to keep the volumes of deleted pods.

2) We will now use kubectl command to physically create three storage classes from the manifest files we defined above.

```
$ kubectl create -f sc-gce-pd-ssd.yaml --namespace emart 

storageclass.storage.k8s.io/sc-fast-storage created
```

**3) Verify New Storage Class**
Once you’ve created all the storage classes, you can verify them through kubectl command:

```
$ kubectl get sc  --namespace emart

NAME                 PROVISIONER            AGE
sc-fast-storage      kubernetes.io/gce-pd   59s
standard (default)   kubernetes.io/gce-pd   2d19h
```

### 2) Add Storage Class to Persistent Volume Claim Template:

Now that we have created SCs in each of the three AZs, we can use them to create dynamic storage volumes and mount them of each of the Couchbase services that requires persistent data. There is one last thing to do before we can use persistent volumes and that is define Persistent Volume Claim Template in our couchbase-cluster.yaml file (which can be found from the operator folder).

Since we have a Storage Class for three zones, we’ll need to create a Persistent Volume Claim Template for each Zone. The following is an example configuration required for using storage classes across 3 different zones:


```
Spec:
  volumeClaimTemplates:
    - metadata:
        name: pvc-default
      spec:
        storageClassName: standard
        resources:
          requests:
            storage: 1Gi
    - metadata:
        name: pvc-fast-data
      spec:
        storageClassName: sc-fast-storage
        resources:
          requests:
            storage: 5Gi
    - metadata:
        name: pvc-fast-index
      spec:
        storageClassName: sc-fast-storage
        resources:
          requests:
            storage: 3Gi
```

Now that the templates are added, the final step is to pair the volume claim template with server groups according in each of the zones. For instance, Pods within Server-Group named data-east-1a should use volumeClaimTemplate named _pvc-fast-data_ to store data and _pvc-default_ for Couchbase binaries and log files.

For example, the following shows the pairing of a Server Group and its associated VolumeClaimTemplate:

```
spec:
  servers:
    - name: data-europe-west1-b
      size: 1
      services:
        - data
      serverGroups:
       - europe-west1-b
      pod:
        volumeMounts:
          default: pvc-default
          data: pvc-fast-data
    - name: data-europe-west1-c
      size: 1
      services:
        - data
      serverGroups:
       - europe-west1-c
      pod:
        volumeMounts:
          default: pvc-default
          data: pvc-fast-data
    - name: data-europe-west1-d
      size: 1
      services:
        - data
      serverGroups:
       - europe-west1-d
      pod:
        volumeMounts:
          default: pvc-default
          data: pvc-fast-data
```

Notice that we have created three separate data server groups (data-europe-west1-b/-c/-d), each located in its own AZ, using persistent volume claim templates from that AZ. Now using the same concept we will add index, and query services and allocate them in separate server groups so they can scale independently of data nodes.


### 3) Add TLS Certificate to non-default namespace 'emart'

```
kubectl create secret generic couchbase-server-tls --from-file chain.pem --from-file pkey.key --namespace emart
```

```
kubectl create secret generic couchbase-operator-tls --from-file pki/ca.crt --namespace emart
```


### 4) Deploy Couchbase Cluster

The full spec for deploying Couchbase cluster across 3 different zones using persistent volumes can be seen in the [couchbase-cluster-with-pv-1.2.yaml](files/couchbase-cluster-with-pv-1.2.yaml) file. This file along with other sample yaml files used in this article can be downloaded from this git repo.

Please open the yaml file and note that we are deploying data service in three AZs but deploying index & query service in two AZs only. You can change the configuration to meet your production requirements.

Now use kubectl to deploy the cluster.

```
$ kubectl create -f couchbase-cluster-with-pv-1.2.yaml  --namespace emart
```

This will start deploying the Couchbase cluster and if all goes fine then we will have five Couchbase cluster pods hosting the services as per the configuration file above. To check the progress run this command, which will watch (-w argument) the progress of pods creating:

```
$ kubectl get pods --namespace emart -w

output:

NAME                                 READY     STATUS              RESTARTS   AGE
cb-eks-demo-0000                     1/1       Running             0          2m
cb-eks-demo-0001                     1/1       Running             0          1m
cb-eks-demo-0002                     1/1       Running             0          1m
cb-eks-demo-0003                     1/1       Running             0          37s
cb-eks-demo-0004                     1/1       ContainerCreating   0          1s
couchbase-operator-8c554cbc7-n8rhg   1/1       Running             0          19h
```

If for any reason there is an exception, then you can find the details of exception from the couchbase-operator log file. To display the last 20 lines of the log, copy the name of your operator pod and run below command by replacing the operator name with the name in your environment.

```

$ kubectl logs couchbase-operator-8c554cbc7-98dkl --namespace emart --tail 20

output:

time="2019-02-13T18:32:26Z" level=info msg="Cluster does not exist so the operator is attempting to create it" cluster-name=cb-eks-demo module=cluster
time="2019-02-13T18:32:26Z" level=info msg="Creating headless service for data nodes" cluster-name=cb-eks-demo module=cluster
time="2019-02-13T18:32:26Z" level=info msg="Creating NodePort UI service (cb-eks-demo-ui) for data nodes" cluster-name=cb-eks-demo module=cluster
time="2019-02-13T18:32:26Z" level=info msg="Creating a pod (cb-eks-demo-0000) running Couchbase enterprise-5.5.3" cluster-name=cb-eks-demo module=cluster
time="2019-02-13T18:32:34Z" level=warning msg="node init: failed with error [Post http://cb-eks-demo-0000.cb-eks-demo.emart.svc:8091/node/controller/rename: dial tcp: lookup cb-eks-demo-0000.cb-eks-demo.emart.svc on 10.100.0.10:53: no such host] ...retrying" cluster-name=cb-eks-demo module=cluster
time="2019-02-13T18:32:39Z" level=info msg="Operator added member (cb-eks-demo-0000) to manage" cluster-name=cb-eks-demo module=cluster
time="2019-02-13T18:32:39Z" level=info msg="Initializing the first node in the cluster" cluster-name=cb-eks-demo module=cluster
time="2019-02-13T18:32:39Z" level=info msg="start running..." cluster-name=cb-eks-demo module=cluster
```

When all the pods are ready then you can port forward one of Couchbase cluster pod so that we can view the cluster status from the web-console. Run this command to port forward it.


```
$ kubectl port-forward cb-eks-demo-0000 8091:8091 --namespace emart
```

At this point you can open up a browser and type http://locahost:8091 which will bring Couchbase web-console from where you can monitor server stats, create buckets, run queries all from one single place.

![](assets/step02-gke-couchbase-cluster.png)

![](https://blog.couchbase.com/wp-content/uploads/2019/04/K8-Cluster--1024x516.png)

Figure 2: Five node Couchbase cluster using persistent volumes.






# TLS 

```
$ git clone http://github.com/OpenVPN/easy-rsa
Cloning into 'easy-rsa'...
warning: redirecting to https://github.com/OpenVPN/easy-rsa/
remote: Enumerating objects: 53, done.
remote: Counting objects: 100% (53/53), done.
remote: Compressing objects: 100% (37/37), done.
remote: Total 1313 (delta 17), reused 44 (delta 16), pack-reused 1260
Receiving objects: 100% (1313/1313), 5.53 MiB | 2.12 MiB/s, done.
Resolving deltas: 100% (594/594), done.
```

```
$ cd easy-rsa/easyrsa3
```
```
$ ./easyrsa init-pki

  init-pki complete; you may now create a CA or requests.
  Your newly created PKI dir is: /Users/ram.dhakne/Documents/work/k8s/gcloud/easy-rsa/easyrsa3/pki
```
```
$ ./easyrsa build-ca

Using SSL: openssl OpenSSL 1.0.2p  14 Aug 2018

Enter New CA Key Passphrase:
Re-Enter New CA Key Passphrase:
Generating RSA private key, 2048 bit long modulus
.....................................+++++
..................................................................................+++++
e is 65537 (0x10001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
```

-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:cb-gke-k8s-tls

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/Users/ram.dhakne/Documents/work/k8s/gcloud/easy-rsa/easyrsa3/pki/ca.crt


### You may be asked to enter passphrase that was used to generate the CA
```
$ ./easyrsa --subject-alt-name=DNS:*.cb-gke-k8s-tls.default.svc build-server-full couchbase-server nopass

Using SSL: openssl OpenSSL 1.0.2p  14 Aug 2018
Generating a 2048 bit RSA private key
..................................................+++++
.........................................................+++++
writing new private key to '/Users/ram.dhakne/Documents/work/k8s/gcloud/easy-rsa/easyrsa3/pki/private/couchbase-server.key.o8DoOo42GM'
```

-----
Using configuration from /Users/ram.dhakne/Documents/work/k8s/gcloud/easy-rsa/easyrsa3/pki/safessl-easyrsa.cnf
Enter pass phrase for /Users/ram.dhakne/Documents/work/k8s/gcloud/easy-rsa/easyrsa3/pki/private/ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'couchbase-server'
Certificate is to be certified until Mar 13 16:52:49 2022 GMT (1080 days)

Write out database with 1 new entries
Data Base Updated
```
$ cp pki/private/couchbase-server.key pkey.key
```
```
$ cp pki/issued/couchbase-server.crt chain.pem
```
```
$ openssl rsa -in pkey.key -out pkey.key.der -outform DER
```
writing RSA key

```
$ openssl rsa -in pkey.key.der -inform DER -out pkey.key -outform PEM
```
writing RSA key

### for default namespace

```
kubectl create secret generic couchbase-server-tls --from-file chain.pem --from-file pkey.key
```
```
kubectl create secret generic couchbase-operator-tls --from-file pki/ca.crt 
```

### for non-default namespace, say namespace 'k8s'
```
kubectl create secret generic couchbase-server-tls --from-file chain.pem --from-file pkey.key --namespace k8s
```
```
kubectl create secret generic couchbase-operator-tls --from-file pki/ca.crt --namespace k8s
```

## Serving Groups

Setting up server groups is also straightforward, which will be discussed in the following sections when we deploy the couchbase cluster yaml file.


## Persistent Volumes
Persistent Volumes provide way for a reliable way to run stateful applications. Creating them on public cloud is one click operation.

First we can check what storageclass is available for use
```
$ kubectl get storageclass
NAME                 PROVISIONER         AGE
standard (default) kubernetes.io/gce-pd  1d
```


All the worker nodes available in the k8s cluster should failure domain labels like below
```
$ kubectl get nodes -o yaml | grep zone
failure-domain.beta.kubernetes.io/zone: us-east1-b
failure-domain.beta.kubernetes.io/zone: us-east1-b
failure-domain.beta.kubernetes.io/zone: us-east1-d
failure-domain.beta.kubernetes.io/zone: us-east1-d
failure-domain.beta.kubernetes.io/zone: us-east1-c
failure-domain.beta.kubernetes.io/zone: us-east1-c
```

NOTE: I don’t have to add any failure domain labels, GKE added automatically.

Create PV for each AZ
```
$ kubectl apply -f svrgp-pv.yaml
```
yaml file svrgp-pv.yaml, can be found here.

Create secret for accessing couchbase UI
```
$ kubectl apply -f secret.yaml
```

Finally deploy couchbase cluster with TLS support, along with Server Groups(which are Az aware) and on persistent volumes (which are also AZ aware).
```
$ kubectl apply -f couchbase-persistent-tls-svrgps.yaml
```
yaml file couchbase-persistent-tls-svrgps.yaml, can be found here

Give a few mins, and couchbase cluster will come up, and it should look like this

```
$ kubectl get pods
NAME            READY STATUS RESTARTS AGE
cb-gke-demo-0000 1/1 Running 0 1d
cb-gke-demo-0001 1/1 Running 0 1d
cb-gke-demo-0002 1/1 Running 0 1d
cb-gke-demo-0003 1/1 Running 0 1d
cb-gke-demo-0004 1/1 Running 0 1d
cb-gke-demo-0005 1/1 Running 0 1d
cb-gke-demo-0006 1/1 Running 0 1d
cb-gke-demo-0007 1/1 Running 0 1d
couchbase-operator-6cbc476d4d-mjhx5 1/1 Running 0 1d
couchbase-operator-admission-6f97998f8c-cp2mp 1/1 Running 0 1d
```

Quick check on persistent volumes claims can be done like below
```
$ kubectl get pvc
```

In order to access the Couchbase Cluster UI, either we can port-foward port 8091 of any pod or service itself, on local laptop, or local machine, or it can be exposed via lb.

```
$ kubectl port-forward service/cb-gke-demo-ui 8091:8091
```
port-forward any pod like below

```
$ kubectl port-forward cb-gke-demo-0002 8091:8091
```

# Operations

At this point couchbase server is up and running and we have way to access it.

Perform Server Group Autofailover
Server Group auto-failover
When a couchbase cluster node fails, then it can auto-failover and without any user intervention ALL the working set is available, no user intervention is needed and Application won’t see downtime.

If Couchbase cluster is setup to be Server Group(SG) or AZ or Rack Zone(RZ) aware, then even if we lose entire SG then entire server groups fails over and working set is available, no user intervention is needed and Application won’t see downtime.

In order to have Disaster Recovery, XDCR can be used to replicate Couchbase data to other Couchbase Cluster. This helps in the event if entire source Data Center or Region is lost, Applications can cut over to Remote site and application won’t see downtime.

Lets take down the Server Group. Before that, lets see how the cluster looks like


Delete all pods in group us-east1-b, once the pods are deleted, Couchbase cluster will see that nodes are 
Operator is constantly watching the cluster definition and it will see that server group is lost, and it spins the 3 pods, re-establishes the claims on the PVs and performs delta-node recovery, and then eventually performs rebalance operation and cluster is healthy again. All with no user-intervention whatsoever.

After sometime, cluster is back and up and running.


From the operator logs,

```
$ kubectl logs -f couchbase-operator-6cbc476d4d-mjhx5
```

we can see that cluster is automatically rebalanced.





# Conclusion

Couchbase Autonomous Operator makes management and orchestration of Couchbase Cluster seamless on the Kubernetes platform. What makes this operator unique is its ability to easily use storage classes offered by different cloud vendors (AWS, Azure, GCP, RedHat OpenShift, etc) to create persistent volumes, which is then used by the Couchbase database cluster to persistently store the data. In the event of pod or container failure, Kubernetes re-instantiate a new pod/container automatically and simply remounts the persistent volumes back, making the recovery fast. It also helps maintain the SLA of the system during infrastructure failure recovery because only delta recovery is needed as opposed to full-recovery, if persistent volumes are not being used.

We walked through step-by-step on how you will setup persistent volumes on Google Cloud GKS in this article but the same steps would also be applicable if you are using any other open-source Kubernetes environment (AKS, GKE, etc). We hope you will give Couchbase Autonomous Operator a spin and let us know of your experience.





--- 

josemolina@EMEA-JoseMolina  ~/couchbase/kubernetes/operator/gke-emart  kubectl create -f couchbase-cluster-with-pv-tls-serverGroups_1.2.yaml --namespace emart
Error from server: error when creating "couchbase-cluster-with-pv-tls-serverGroups_1.2.yaml": admission webhook "couchbase-operator-admission.default.svc" denied the request: validation failure list:
spec.servers[0].default should be one of []
spec.servers[0].data should be one of []
spec.servers[1].default should be one of []
spec.servers[1].data should be one of []
spec.servers[2].default should be one of []
spec.servers[2].data should be one of []
spec.servers[3].default should be one of []
spec.servers[3].index should be one of []
spec.servers[4].default should be one of []
spec.servers[4].index should be one of []
certificate cannot be verified: x509: certificate is valid for cb-gke-emart-tls, not verify.cb-gke-emart-tls.emart.svc



kubectl create -f couchbase-cluster-with-pv-tls-serverGroups_1.2.yaml --namespace emart
Error from server: error when creating "couchbase-cluster-with-pv-tls-serverGroups_1.2.yaml": admission webhook "couchbase-operator-admission.default.svc" denied the request: validation failure list:
spec.servers[0].default should be one of []
spec.servers[0].data should be one of []
spec.servers[1].default should be one of []
spec.servers[1].data should be one of []
spec.servers[2].default should be one of []
spec.servers[2].data should be one of []
spec.servers[3].default should be one of []
spec.servers[3].index should be one of []
spec.servers[4].default should be one of []
spec.servers[4].index should be one of []