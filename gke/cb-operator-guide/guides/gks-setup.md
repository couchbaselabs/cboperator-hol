# Setup GKS Cluster

The following section will walk through the steps to create the GKS cluster.  This GKS cluster will be used to deploy Couchbase Autonomous Operator later in the lab.

## Set up GKS Creation Script

 In order to automate the setup we have written python based scripts which can be configured to deploy the GKS Cluster under anybody's Google account. Please follow through the steps below:

### Step 1. Google SDK Setup & Create your project **_my-couchbase-project_** 
```
$ gcloud init --console-only
```

### Step 2. **Log in** 
```
$ gcloud auth login
```

### Step 3. **Set default config values**

|config| command |
| :--- | :--- |
| Set your default project | ``` $ gcloud config set project my-couchbase-project ```|
| Set default region | ```$ gcloud config set compute/region europe-west3```|
| Set default zone | ```$ gcloud config set compute/zone europe-west3-a```|


### Step 4. **Setup Network Setup**

*   **4.1. Create Custom Network configuration**
```  
$ gcloud compute networks create my-network --subnet-mode custom
```

*   **4.2. Create Subnet on region europe-west1**
```
$ gcloud compute networks subnets create my-subnet-europe-west1 --network my-network --region europe-west1 --range 10.0.0.0/12
```
*   **4.3. Create Subnet on region europe-west3**
```
$ gcloud compute networks subnets create my-subnet-europe-west3 --network my-network --region europe-west3 --range 10.16.0.0/12
```
*   **4.4. Add Firewall rules:**
```
$ gcloud compute firewall-rules create my-network-allow-all-private --network my-network --direction INGRESS --source-ranges 10.0.0.0/8 --allow all
```

### Step 5. **Provisioning Instances for the Kubernetes GKE Cluster**

*   **5.1. Check your region cluster version**

```
gcloud container get-server-config --region europe-west1

Fetching server config for europe-west1
defaultClusterVersion: 1.12.8-gke.10
defaultImageType: COS
validImageTypes:
- COS_CONTAINERD
- WINDOWS_SAC
- COS
- UBUNTU
validMasterVersions:
- 1.13.7-gke.8
- 1.13.6-gke.13
- 1.12.9-gke.7
....
```

*   **5.2. Create instances for Cluster 1 in europe-west1 zone b**

```
$ gcloud container clusters create my-cluster-europe-west1-b --machine-type n1-standard-2 --cluster-version 1.13.7-gke.8 --zone europe-west1-b --network my-network --subnetwork my-subnet-europe-west1 --num-nodes 3
```

*   **5.2. Create three instances for cluster 2 in europe-west3 zone a**

```
$ gcloud container clusters create my-cluster-europe-west3-a --machine-type n1-standard-2 --cluster-version 1.13.7-gke.8 --zone europe-west3-a --network my-network --subnetwork my-subnet-europe-west3 --num-nodes 3
```

*   **5.3. List Clusters**

```
$ gcloud container clusters list
```

### Step 6. **Get Cluster Credentials** and **setup Kubernetes** environment

*   **6.1. Get Cluster Credentials from my-cluster-europe-west1-b**
```
$ gcloud container clusters get-credentials my-cluster-europe-west1-b --zone europe-west1-b --project my-couchbase
```

*   **6.2. Setup your local Kubernetes with the GKE Cluster**
```
$ kubectl create clusterrolebinding your-admin-binding --clusterrole cluster-admin --user $(gcloud config get-value account)
```

### Step 7: Verify number of nodes
Make sure number of nodes requested is what has been deployed

```
$ kubectl get nodes

NAME                                                  STATUS   ROLES    AGE    VERSION
gke-my-cluster-europe-we-default-pool-46ad3425-h8rp   Ready    <none>   3d2h   v1.13.7-gke.8
gke-my-cluster-europe-we-default-pool-46ad3425-x3pk   Ready    <none>   3d2h   v1.13.7-gke.8
gke-my-cluster-europe-we-default-pool-90043a7f-4r65   Ready    <none>   3d2h   v1.13.7-gke.8
gke-my-cluster-europe-we-default-pool-90043a7f-csrw   Ready    <none>   3d2h   v1.13.7-gke.8
gke-my-cluster-europe-we-default-pool-e1610aae-3vnh   Ready    <none>   3d2h   v1.13.7-gke.8
gke-my-cluster-europe-we-default-pool-e1610aae-s5gv   Ready    <none>   3d2h   v1.13.7-gke.8
```

