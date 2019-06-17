# Introduction

Modern business applications are expected to be up 24/7, even during the planned rollout of new features and periodic patching of Operating System or application. Achieving this feat requires tools and technologies that ensure the speed of development, infrastructure stability and ability to scale.

Container orchestration tools like Kubernetes is revolutionizing the way applications are being developed and deployed today by abstracting away the physical machines it manages. With Kubernetes, you can describe the amount of memory, compute power you want, and have it available without worrying about the underlying infrastructure.

Pods (unit of computing resource) and containers (where the applications are run) in Kubernetes environment can self-heal in the event of any type of failure. They are, in essence, ephemeral. This works just fine when you have a stateless microservice but applications that require their state maintained for example database management systems like Couchbase, you need to be able to externalize the storage from the lifecycle management of Pods & Containers so that the data can be recovered quickly by simply remounting the storage volumes to a newly elected Pod.

This is what Persistent Volumes enables in Kubernetes based deployments. Couchbase Autonomous Operator is one of the first adopters of this technology to make recovery from any infrastructure-based failure seamless and most importantly faster.

In this article we will take a step-by-step look at how you can deploy Couchbase cluster on Amazon Elastic Container Service for Kubernetes (Amazon EKS):
* using multiple Couchbase server groups that can be mapped to a separate availability zone for high availability
* leverage persistent volumes for fast recovery from infrastructure failure.

![](https://blog.couchbase.com/wp-content/uploads/2019/04/K8-Animation.gif)

Figure 1: Couchbase Autonomous Operator for Kubernetes self-monitors and self-heals Couchbase database platform.

# Prerequisites

There are two important prerequisites before we begin the deployment of Couchbase Autonomous Operator on EKS:

1. You have installed _kubectl_ & _AWS CLI_ on your local machine as described in the [guide](./guides/prerequisite-tools.md).

2. You have AWS account and have setup Amazon EKS cluster as per the [EKS Instruction Guide](./guides/eks-setup.md).

In the labs below we will be using us-east-1 as the region and us-east-1a/1b/1c as three availability-zones but you can deploy to any region/zones by making minor changes to YAML files in the examples below.


# Deploy Couchbase Autonomous Operator

Before we begin with the setup of Couchbase Operator, run ‘kubectl get nodes’ command from the local machine to confirm EKS cluster is up and running.


```
$ kubectl get nodes

NAME                              STATUS    ROLES     AGE       VERSION
ip-192-168-106-132.ec2.internal   Ready     <none>    110m      v1.11.9
ip-192-168-153-241.ec2.internal   Ready     <none>    110m      v1.11.9
ip-192-168-218-112.ec2.internal   Ready     <none>    110m      v1.11.9
```

After we have tested that we can connect to Kubernetes control plane running on Amazon EKS cluster from our local machine, we can now begin with the steps required to deploy Couchbase Autonomous Operator, which is the glue technology enabling Couchbase Server cluster to be managed by Kubernetes.

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

Create a namespace that will allow cluster resources to be nicely separated between multiple users. To do that we will use a unique namespace called emart for our deployment and later will use this namespace to deploy Couchbase Cluster.

In your working directory create a [namespace.yaml](https://github.com/sahnianuj/cb-operator/blob/master/namespace.yaml) file with this content and save it in the Couchbase operator directory itself:

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

output:

NAME          STATUS    AGE
default       Active    1h
emart         Active    12s
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
couchbase-operator   1          1          1               0               10s
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
couchbase-operator-8c554cbc7-6vqgf      1/1         Running  0          57s
```
You can also check the logs to confirm that the Operator is up and running. Look for the message: CRD initialized, listening for events…​ module=controller.

```
$ kubectl logs couchbase-operator-8c554cbc7-6vqgf --namespace emart --tail 20

output:

time="2019-05-30T23:00:58Z" level=info msg="couchbase-operator v1.2.0 (release)" module=main
time="2019-05-30T23:00:58Z" level=info msg="Obtaining resource lock" module=main
time="2019-05-30T23:00:58Z" level=info msg="Starting event recorder" module=main
time="2019-05-30T23:00:58Z" level=info msg="Attempting to be elected the couchbase-operator leader" module=main
time="2019-05-30T23:00:58Z" level=info msg="I'm the leader, attempt to start the operator" module=main
time="2019-05-30T23:00:58Z" level=info msg="Creating the couchbase-operator controller" module=main
time="2019-05-30T23:00:58Z" level=info msg="Event(v1.ObjectReference{Kind:\"Endpoints\", Namespace:\"emart\", Name:\"couchbase-operator\", UID:\"c96ae600-832e-11e9-9cec-0e104d8254ae\", APIVersion:\"v1\", ResourceVersion:\"950158\", FieldPath:\"\"}): type: 'Normal' reason: 'LeaderElection' couchbase-operator-6cbc476d4d-2kps4 became leader" module=event_recorder
```

# Deploy Couchbase cluster using persistent volumes

In a production environment where performance and SLA of the system matters most, we should always plan on deploying Couchbase cluster using persistent volumes because it helps in:

* **Data Recoverability**: Persistent Volumes allow the data associated within Pods to be recovered in the case that a Pod is terminated. This helps prevent data-loss and avoid time-consuming index building when using the data or index services.

* **Pod Relocation**: Kubernetes may decide to evict pods that reach resource thresholds such as CPU and Memory Limits. Pods that are backed with Persistent Volumes can be terminated and restarted on different nodes without incurring any downtime or data-loss.
* **Dynamic Provisioning**: The Operator will create Persistent Volumes on-demand as your cluster scales, alleviating the need to pre-provision your cluster storage prior to deployment.

* **Cloud Integration**: Kubernetes integrates with native storage provisioners available on major cloud vendors such as AWS and GCE.

In this next section we will see how you can define storage classes in different availability zone and build persistent volume claim template, which will be used in [couchbase-cluster-with-pv.yaml](https://github.com/sahnianuj/cb-operator/blob/master/couchbase-cluster-with-pv.yaml) file.

### 1) Create Secret for Couchbase Admin Console

First thing we need to do is create a secret credential which will be used by the administrative web console during login. For convenience, a sample secret is provided in the Operator package. When you push it to your Kubernetes cluster, the secret sets the username to Administrator and the password to password.

To push the secret into your Kubernetes cluster, run the following command:

```
$ kubectl create -f secret.yaml --namespace emart

Output:

Secret/cb-example-auth created
```

### 2) Create AWS storage class for the EKS cluster

Now in order to use PersistentVolume for Couchbase services (data, index, search, etc.), we need to create Storage Classes (SC) first in each of the Availability Zones (AZ). Let’s begin by checking what storage classes exist in our environment.

Let’s use kubectl command to find that out:
```
$ kubectl get storageclass

Output:

gp2 (default)   kubernetes.io/aws-ebs   12m
```

Above output means we just have default gp2 storage class and we need to create separate storage-classes in all of the AZs where we are planning to deploy our Couchbase cluster.

We will run below steps to create three different storage classes of type gp2 to store data, index and Couchbase binaries.

1) Create an AWS storage class manifest file for your storage class. Below example defines a storage class that uses the Amazon EBS gp2 volume type. For more information about the options available for AWS storage classes, see [AWS](https://kubernetes.io/docs/concepts/storage/storage-classes/#aws) in the Kubernetes documentation.

* Create a storage definition file [sc-gp2.yaml](https://github.com/sahnianuj/cb-operator/blob/master/sc-gp2.yaml) that represent storage class of _gp2_ type (aka general purpose SSD drive), which we will later use it in our _VolumeClaimTemplate_.

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  labels:
    k8s-addon: storage-aws.addons.k8s.io
  name: gp2-multi-zone
parameters:
  type: gp2
provisioner: kubernetes.io/aws-ebs
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```
We have used reclaimPolicy to _Delete_ which tells K8 to delete the volumes of deleted Pods but you can change it to _Retain_ depending on your needs or if for troubleshooting purpose you would like to keep the volumes of deleted pods.

2) We will now use kubectl command to physically create three storage classes from the manifest files we defined above.

```
$ kubectl create -f sc-gp2.yaml

Output:

storageclass.storage.k8s.io/gp2-multi-zone created
```

3) Verify New Storage Class
Once you’ve created all the storage classes, you can verify them through kubectl command:

```
$ kubectl get sc  --namespace emart

output:

NAME            PROVISIONER             AGE
gp2 (default)   kubernetes.io/aws-ebs   16h
gp2-multi-zone  kubernetes.io/aws-ebs   96s
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
        storageClassName: gp2-multi-zone
        resources:
          requests:
            storage: 1Gi
    - metadata:
        name: pvc-data
      spec:
        storageClassName: gp2-multi-zone
        resources:
          requests:
            storage: 5Gi
    - metadata:
        name: pvc-index
      spec:
        storageClassName: gp2-multi-zone
        resources:
          requests:
            storage: 3Gi
```
Now that the templates are added, the final step is to pair the volume claim template with server groups according in each of the zones. For instance, Pods within Server-Group named data-east-1a should use volumeClaimTemplate named _pvc-data_ to store data and _pvc-default_ for Couchbase binaries and log files.

For example, the following shows the pairing of a Server Group and its associated VolumeClaimTemplate:

```
spec:
  servers:
    - name: data-east-1a
      size: 1
      services:
        - data
      serverGroups:
       - us-east-1a
      pod:
        volumeMounts:
          default: pvc-default
          data: pvc-data
    - name: data-east-1b
      size: 1
      services:
        - data
      serverGroups:
       - us-east-1b
      pod:
        volumeMounts:
          default: pvc-default
          data: pvc-data
    - name: data-east-1c
      size: 1
      services:
        - data
      serverGroups:
       - us-east-1c
      pod:
        volumeMounts:
          default: pvc-default
          data: pvc-data
```

Notice that we have created three separate data server groups (data-east-1a/-1b/-1c), each located in its own AZ, using persistent volume claim templates from that AZ. Now using the same concept we will add index, and query services and allocate them in separate server groups so they can scale independently of data nodes.

### 3) Deploy Couchbase Cluster

The full spec for deploying Couchbase cluster across 3 different zones using persistent volumes can be seen in the [couchbase-cluster-with-pv-1.2.yaml](https://github.com/sahnianuj/cb-operator/blob/master/couchbase-cluster-with-pv-1.2.yaml) file. This file along with other sample yaml files used in this article can be downloaded from this git repo.

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

![](https://blog.couchbase.com/wp-content/uploads/2019/04/K8-Cluster--1024x516.png)

Figure 2: Five node Couchbase cluster using persistent volumes.

# Conclusion

Couchbase Autonomous Operator makes management and orchestration of Couchbase Cluster seamless on the Kubernetes platform. What makes this operator unique is its ability to easily use storage classes offered by different cloud vendors (AWS, Azure, GCP, RedHat OpenShift, etc) to create persistent volumes, which is then used by the Couchbase database cluster to persistently store the data. In the event of pod or container failure, Kubernetes re-instantiate a new pod/container automatically and simply remounts the persistent volumes back, making the recovery fast. It also helps maintain the SLA of the system during infrastructure failure recovery because only delta recovery is needed as opposed to full-recovery, if persistent volumes are not being used.

We walked through step-by-step on how you will setup persistent volumes on Amazon EKS in this article but the same steps would also be applicable if you are using any other open-source Kubernetes environment (AKS, GKE, etc). We hope you will give Couchbase Autonomous Operator a spin and let us know of your experience.
