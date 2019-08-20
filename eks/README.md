
# Content

1. **Prerequisites**
2. **Deploy Couchbase Autonomous Operator**

	2.1. **Download Operator package**
	2.2. **Install Admission Control**
	2.3. **Create a namespace**
	2.4. **Install CRD**
	2.5. **Create a Operator Role**
	2.6. **Create a Service Account**
	2.7. **Deploy Couchbase Operator**

3. **Deploy Couchbase cluster using persistent volumes**

	3.1. **Create Secret for Couchbase Admin Console**
	3.2. **Create Google storage class for the GKS cluster**
	3.3. **Server Group Awareness**
	3.4. **Add Storage Class to Persistent Volume Claim Template**
	3.5. **Add TLS Certificate**
	3.6. **Deploy Couchbase Cluster**

4. **Operations**

	4.1. **Self-Recovery from Failure**
	4.2. **On-Demand Scaling - Up & Down**
	4.3. **Couchbase Automated Upgrade**

5. **Conclusion**


# 1. Prerequisites

There are two important prerequisites before we begin the deployment of Couchbase Autonomous Operator on EKS:

1. You have installed _kubectl_ & _AWS CLI_ on your local machine as described in the [guide](./cb-operator-guide/guides/prerequisite-tools.md).

2. You have AWS account and have setup Amazon EKS cluster as per the [EKS Instruction Guide](./cb-operator-guide/guides/eks-setup.md).

In the labs below we will be using us-east-1 as the region and us-east-1a/1b/1c as three availability-zones but you can deploy to any region/zones by making minor changes to YAML files in the examples below.


# 2. Deploy Couchbase Autonomous Operator

Before we begin with the setup of Couchbase Operator, run ‘kubectl get nodes’ command from the local machine to confirm EKS cluster is up and running.


```
$ kubectl get nodes

NAME                              STATUS    ROLES     AGE       VERSION
ip-192-168-106-132.ec2.internal   Ready     <none>    110m      v1.11.9
ip-192-168-153-241.ec2.internal   Ready     <none>    110m      v1.11.9
ip-192-168-218-112.ec2.internal   Ready     <none>    110m      v1.11.9
```

After we have tested that we can connect to Kubernetes control plane running on Amazon EKS cluster from our local machine, we can now begin with the steps required to deploy Couchbase Autonomous Operator, which is the glue technology enabling Couchbase Server cluster to be managed by Kubernetes.

### 2.1. Download Operator package

Let’s first begin by downloading the latest [Couchbase Autonomous Operator](https://www.couchbase.com/downloads?family=kubernetes) and unzip onto the local machine. Change directory to the operator folder so we can find YAML files we need to deploy Couchbase operator:


```
$ cd couchbase-autonomous-operator-kubernetes_1.2.0-981_linux-x86_64

$ ls

License.txt			couchbase-cli-create-user.yaml	operator-role-binding.yaml	secret.yaml
README.txt			couchbase-cluster.yaml		operator-role.yaml
admission.yaml			crd.yaml			operator-service-account.yaml
bin				operator-deployment.yaml	pillowfight-data-loader.yaml
```

### 2.2. Install Admission Controller

The admission controller is a required component of the Couchbase Autonomous Operator and needs to be installed separately. The primary purpose of the admission controller is to validate Couchbase cluster configuration changes before the Operator acts on them, thus protecting your Couchbase deployment (and the Operator) from any accidental damage that might arise from an invalid configuration. For architecture details please visit documentation page on the [Admission Controller](https://docs.couchbase.com/operator/current/install-admission-controller.html#architecture)

Use the following steps to deploy the the admission controller:

- From Couchbase operator directory run the following command to create the admission controller:

```
$ kubectl create -f admission.yaml
```
- Confirm the admission controller has deployed successfully:

```
$ kubectl get deployments

NAME                           DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
couchbase-operator-admission   1         1         1            1           1m
```

### 2.3. Create a namespace

Create a namespace that will allow cluster resources to be nicely separated between multiple users. To do that we will use a unique namespace called emart for our deployment and later will use this namespace to deploy Couchbase Cluster.

In your working directory create a [namespace.yaml](./cb-operator-guide/files/namespace.yaml) file with this content and save it in the Couchbase operator directory itself:

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

### 2.4. Install CRD

The first step in installing the Operator is to install the custom resource definition (CRD) that describes the CouchbaseCluster resource type. This can be achieved with the following command:

```
kubectl create -f crd.yaml
```

### 2.5. Create a Operator Role

Next, we will create a [cluster role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#api-overview) that allows the Operator to access the resources that it needs to run. Since the Operator will manage many different [namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/), it is best to create a cluster role first because you can assign that role to a [service account](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#service-account-permissions) in any namespace.

To create the cluster role for the Operator, run the following command:

```
$ kubectl create -f operator-role.yaml --namespace emart
```

This cluster role only needs to be created once.

### 2.6. Create a Service Account

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

### 2.7. Deploy Couchbase Operator

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

# 3. Deploy Couchbase cluster using persistent volumes

In a production environment where performance and SLA of the system matters most, we should always plan on deploying Couchbase cluster using persistent volumes because it helps in:

* **Data Recoverability**: Persistent Volumes allow the data associated within Pods to be recovered in the case that a Pod is terminated. This helps prevent data-loss and avoid time-consuming index building when using the data or index services.

* **Pod Relocation**: Kubernetes may decide to evict pods that reach resource thresholds such as CPU and Memory Limits. Pods that are backed with Persistent Volumes can be terminated and restarted on different nodes without incurring any downtime or data-loss.
* **Dynamic Provisioning**: The Operator will create Persistent Volumes on-demand as your cluster scales, alleviating the need to pre-provision your cluster storage prior to deployment.

* **Cloud Integration**: Kubernetes integrates with native storage provisioners available on major cloud vendors such as AWS and GCE.

In this next section we will see how you can define storage classes in different availability zone and build persistent volume claim template, which will be used in [[couchbase-cluster-with-pv-1.2.yaml](./cb-operator-guide/files/couchbase-cluster-with-pv-1.2.yaml) file.

### 3.1. Create Secret for Couchbase Admin Console

First thing we need to do is create a secret credential which will be used by the administrative web console during login. For convenience, a sample secret is provided in the Operator package. When you push it to your Kubernetes cluster, the secret sets the username to Administrator and the password to password.

To push the secret into your Kubernetes cluster, run the following command:

```
$ kubectl create -f secret.yaml --namespace emart

Output:

Secret/cb-example-auth created
```

### 3.2 Create AWS storage class for the EKS cluster

Now in order to use PersistentVolume for Couchbase services (data, index, search, etc.), we need to create Storage Classes (SC) first in each of the Availability Zones (AZ). Let’s begin by checking what storage classes exist in our environment.

Let’s use kubectl command to find that out:
```
$ kubectl get storageclass

Output:

gp2 (default)   kubernetes.io/aws-ebs   12m
```

Above output means we just have default gp2 storage class and we need to create separate storage-classes in all of the AZs where we are planning to deploy our Couchbase cluster.

1) Create a AWS storage class manifest file. Below example defines the structure of the storage class ([sc-gp2.yaml](./cb-operator-guide/files/sc-gp2.yaml)), which uses the Amazon EBS gp2 volume type (aka general purpose SSD drive). This storage we will later use in our _VolumeClaimTemplate_.

	For more information about the options available for AWS storage classes, see [AWS](https://kubernetes.io/docs/concepts/storage/storage-classes/#aws) in the Kubernetes documentation.

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
	Above we used ```reclaimPolicy``` to _Delete_ which tells K8 to delete the volumes of deleted Pods but you can change it to _Retain_ depending on your needs or if for troubleshooting purpose you would like to keep the volumes of deleted pods.

2) We will now use kubectl command to physically create storage class from the manifest files we defined above.

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

### 3.3. Server Groups Awareness

Server Group Awareness provides enhanced availability as it protects a cluster from large-scale infrastructure failure, through the definition of groups.

Groups should be defined in accordance with the physical distribution of cluster-nodes. For example, a group should only include the nodes that are in a single server rack, or in the case of cloud deployments, a single availability zone. Thus, if the server rack or availability zone becomes unavailable due to a power or network failure, Group Failover, if enabled, allows continued access to the affected data.

We  therefore going to place Couchbase servers onto separate ```spec.servers.serverGroups```, which are going to be mapped to physically separated EKS node running in three different AZs (us-east-1a/b/c):

```
spec:
  servers:
    - name: data-east-1a
      size: 1
      services:
        - data
      serverGroups:
       - us-east-1a
```

### 3.4. Add Storage Class to Persistent Volume Claim Template

With Server groups defined, and Storage Classes available in all three AZs, we are now going to create dynamic storage volumes and mount them of each of the Couchbase server that requires persistent data. In order to do that we will first define Persistent Volume Claim Template in our [couchbase-cluster.yaml](./cb-operator-guide/files/couchbase-cluster-with-pv-1.2.yaml) file (which can be found from the operator folder).

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
After claim template being added the final step is to pair the volume claim template with server groups accordingly in each of the zones. For instance, Pods within Server-Group named data-east-1a should use volumeClaimTemplate named _pvc-data_ to store data and _pvc-default_ for Couchbase binaries and log files.

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



### 3.5. Add TLS Certificate

Create secret for Couchbase Operator and servers with a given certificate. See [how to create a custom certificate](../guides/configure-tls.md) section if you don't have one.

```
$ kubectl create secret generic couchbase-server-tls --from-file </dir/to>/chain.pem \
--from-file </dir/to>/pkey.key --namespace emart

secret/couchbase-server-tls created
```
```
$ kubectl create secret generic couchbase-operator-tls --from-file </dir/to>pki/ca.crt \
--namespace emart

secret/couchbase-operator-tls created
```

### 3.6. Deploy Couchbase Cluster

The full spec for deploying Couchbase cluster across 3 different zones using persistent volumes can be seen in the [couchbase-cluster-with-pv-1.2.yaml](./cb-operator-guide/files/couchbase-cluster-with-pv-1.2.yaml) file. This file along with other sample yaml files used in this article can be downloaded from this git repo.

Please open the yaml file and note that we are deploying data service in three AZs but deploying index & query service in two AZs only. You can change the configuration to meet your production requirements.

Now use kubectl to deploy the cluster.

```
$ kubectl create -f couchbase-cluster-with-pv-1.2.yaml --save-config --namespace emart
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
$ kubectl port-forward cb-eks-demo-0000 18091:18091 --namespace emart
```

At this point you can open up a browser and type https://locahost:18091 which will bring Couchbase web-console from where you can monitor server stats, create buckets, run queries all from one single place.

![](https://blog.couchbase.com/wp-content/uploads/2019/04/K8-Cluster--1024x516.png)

Figure 2: Five node Couchbase cluster using persistent volumes.

# 4. Operations

In this section we are going to perform some operational tasks like cluster expansion, cluster upgrade and test self-recovery feature of the Couchbase Autonomous operator. Let's start with the last topic first.

### 4.1. Self-Recovery from Failure

One of the best feature of Kubernetes in general is that it provides Auto-Healing capability to the services that are managed by it. With Couchbase Autonomous Operator we leverage the same Auto-Healing capability of K8 for Couchbase Cluster.

We are going to test this capability by manually deleting the pod, which would be detected by K8 as an exception, which will inform the operator to bring back the current state of the cluster to the desired state as specified in the [couchbase-cluster-with-pv-1.2.yaml](./cb-operator-guide/files/couchbase-cluster-with-pv-1.2.yaml) file.

Let's induce the fault now using kubectl delete command:

```
$ kubectl get pod --namespace emart
NAME                                 READY     STATUS    RESTARTS   AGE
cb-eks-demo-0000                     1/1       Running   0          8m17s
cb-eks-demo-0001                     1/1       Running   0          7m23s
cb-eks-demo-0002                     1/1       Running   0          6m32s
cb-eks-demo-0003                     1/1       Running   0          5m42s
cb-eks-demo-0004                     1/1       Running   0          4m52s
couchbase-operator-f6f7b6f75-tbxdj   1/1       Running   0          45m

$ kubectl delete pod cb-eks-demo-0001 --namespace emart
pod "cb-eks-demo-0001" deleted

```
![](./cb-operator-guide/assets/server-dropped.png)
Figure 3: One of the Data pod is dropped.

After Couchbase Autonomous Operator detects the failure it triggers the healing process.

![](./cb-operator-guide/assets/server-recovered.png)
Figure 4: Data node with same name and persistent volume will be restored automatically.

### 4.2. On-Demand Scaling - Up & Down

If you have ever scaled-out or scaled-in a database cluster you would know that it is a non-trivial process as it entails lot of manually triggered steps which are not only time consuming but also error prone.

With Couchbase Autonomous Operator scaling-out or scaling-in is as simple as changing the desired number servers for a specific service in the [couchbase-cluster-with-pv-1.2.yaml](./cb-operator-guide/files/couchbase-cluster-with-pv-1.2.yaml) file. Let's open this YAML file again and add one server node in us-east-1a server-group running Index and Query service.

Notice we don't have any Index and Query service in the **us-east-1a** serverGroups:

  ```
  - name: query-east-1b
    size: 1
    services:
      - query
      - index
    serverGroups:
     - us-east-1b
    pod:
      volumeMounts:
        default: pvc-default
        index: pvc-index
  - name: query-east-1c
    size: 1
    services:
      - index
      - query
    serverGroups:
     - us-east-1c
    pod:
      volumeMounts:
        default: pvc-default
        index: pvc-index
  ```  
So we are going to add one more server in **us-east-1a** server group hosting both index and query service like this:

  ```
  - name: query-east-1a
    size: 1
    services:
      - query
      - index
    serverGroups:
     - us-east-1a
    pod:
      volumeMounts:
        default: pvc-default
        index: pvc-index
  - name: query-east-1b
    ....
  - name: query-east-1c
    ....
  ```
A separate [couchbase-cluster-sout-with-pv-1.2.yaml](./cb-operator-guide/files/couchbase-cluster-sout-with-pv-1.2.yaml) file is provided just for convenience but if you want you can also make changes yourself in the [couchbase-cluster-with-pv-1.2.yaml](./cb-operator-guide/files/couchbase-cluster-with-pv-1.2.yaml)

  ```
  $ kubectl apply -f couchbase-cluster-sout-with-pv-1.2.yaml  --namespace emart

  couchbasecluster.couchbase.com/cb-eks-demo configured
```
Notice a new pod will be getting ready to be added to the cluster:
```
  $ kubectl get pods --namespace emart -w
NAME                                 READY     STATUS     RESTARTS   AGE
cb-eks-demo-0000                     1/1       Running    0          44m
cb-eks-demo-0001                     1/1       Running    0          34m
cb-eks-demo-0002                     1/1       Running    0          42m
cb-eks-demo-0003                     1/1       Running    0          41m
cb-eks-demo-0004                     1/1       Running    0          40m
cb-eks-demo-0005                     0/1       Init:0/1   0          11s
  ```

  After pod is ready you can view it from the Web Console as well.

  ![](./cb-operator-guide/assets/scaled-out.png)
  Figure 5: Cluster now has three Couchbase server pods hosting Index and Query services spread across three server-groups.


### 4.3.  Couchbase Automated Upgrade

Any software in service goes through continuous improvement and there is definitely going to be the moments when you would like to upgrade Couchbase Autonomous Operator too because of some new feature or the patch which is critical for your business.

Upgrading a distributed cluster like Couchbase requires careful orchestration of steps if you manually run the online upgrade operation. With Couchbase Autonomous Operator the whole symphony of these operations are completely automated, so the management becomes very easy.

Let's take a look at how you can upgrade the system in an online fashion.

#### 4.3.1. Preparing for Upgrade
Before beginning an upgrade to your Kubernetes cluster, review the following considerations and prerequisites:

- As an eviction deletes a pod, ensure that the Couchbase cluster is scaled correctly so that it can handle the increased load of having a pod down while a new pod is balanced into the cluster.

- To minimize disruption, ensure that a short failover period is configured with the autoFailoverTimeout parameter to reduce down time before another node takes over the load.

- Ensure that there is capacity in your Kubernetes cluster to handle the scheduling of replacement Couchbase pods. For example, if a Couchbase cluster were running on Kubernetes nodes marked exclusively for use by Couchbase, and anti-affinity were enabled as per the deployment [best practices](https://docs.couchbase.com/operator/current/best-practices.html), the Kubernetes cluster would require at least one other node capable of scheduling and running your Couchbase workload.

#### 4.3.2. Perform Automatic Upgrade
To prevent downtime or a data loss scenario, the Operator provides controls for how automated Kubernetes upgrades proceed.

A PodDisruptionBudget is created for each CouchbaseCluster resource created. The PodDisruptionBudget specifies that at least the cluster size minus one node (N-1) be ready at any time. This constraint allows, at most, one node to be evicted at a time. As a result, it’s recommended that to support an automatic Kubernetes upgrade, the cluster be deployed with anti-affinity enabled to guarantee only a single eviction at a time.

Now let's open [couchbase-cluster-with-pv-1.2.yaml](./cb-operator-guide/files/couchbase-cluster-with-pv-1.2.yaml) file and change:

```
spec:
  baseImage: couchbase/server
  version: enterprise-5.5.4
  ```
  to
  ```
  spec:
    baseImage: couchbase/server
    version: enterprise-6.0.2
  ```
  Now using kubectl to deploy the cluster.

  ```
  $ kubectl apply -f couchbase-cluster-with-pv-1.2.yaml  --namespace emart
  ```
At this point you would notice the pods will be evicted one by one and new pod will be joined to the existing cluster but with an upgraded Couchbase version (6.0.2).

![](./cb-operator-guide/assets/upgrade.png)
Figure 6: Couchbase Cluster getting upgraded one pod at a time in and online fashion.

Note: At some point during upgrade when your cb-eks-demo-0000 pod is upgraded to a newer pod (cb-eks-demo-0005), you might need to reset the forwarding to newly upgraded pod like this:

  ```
  $ kubectl port-forward cb-eks-demo-0005 18091:18091 --namespace emart
  ```
Just wait for some time and cluster will upgraded one pod at a time in a rolling fashion.


# Conclusion

Couchbase Autonomous Operator makes management and orchestration of Couchbase Cluster seamless on the Kubernetes platform. What makes this operator unique is its ability to easily use storage classes offered by different cloud vendors (AWS, Azure, GCP, RedHat OpenShift, etc) to create persistent volumes, which is then used by the Couchbase database cluster to persistently store the data. In the event of pod or container failure, Kubernetes re-instantiate a new pod/container automatically and simply remounts the persistent volumes back, making the recovery fast. It also helps maintain the SLA of the system during infrastructure failure recovery because only delta recovery is needed as opposed to full-recovery, if persistent volumes are not being used.

We walked through step-by-step on how you will setup persistent volumes on Amazon EKS in this article but the same steps would also be applicable if you are using any other open-source Kubernetes environment (AKS, GKE, etc). We hope you will give Couchbase Autonomous Operator a spin and let us know of your experience.
