# Couchbase Autonomous Operator on OpenShift Setup

This workshop will guide you through provisioning, scaling, failing-over & rebalancing, and rolling upgrades of a Couchbase cluster running on OpenShift 4.0. We will also deploy a real-time application that streams data into Couchbase ontop of the Couchbase cluster and observe how it responds during a Couchbase node failure and a Couchbase cluster upgrade.

## Setting up and Accessing OpenShift 4.x

### Prerequisites

- Access to an AWS account
- A domain configured in AWS Route53
- For the second section, "Deploying the Twitter App", you will need Twitter API Keys

This workshop should be performed on OpenShift 4. OpenShift 4 is easy to install if you have access to an AWS account.

Go to https://try.openshift.com and follow the steps. The output of the installer will print how to access the cluster from the command line and browser.

### Login to OpenShift

Login to the OCP cluster from both the command line and OCP UI (your URL will be different):

```
oc login https://api.CLUSTER_ID.couchbasedemos.com:6443

In browser:
https://console-openshift-console.apps.CLUSTER_ID.couchbasedemos.com/

Username: kubeadmin
Password: <YOUR CLUSTER PASSWORD>
```

## Couchbase Autonomous Operator Deployment

The next set of steps will guide you through deploying the Operator.

### Create Project

```bash
oc new-project cb-example
```

### Download the Couchbase Autonomous Operator Package

First download the Couchbase Autonomous Operator 1.2 package (zip file) for OpenShift from https://couchbase.com/downloads

**Unzip it into your current working directory and cd into it from the command line.**

### Create Couchbase Admin Secret

First, we’ll create a secret which we will later use to authenticate with the Couchbase Admin UI

```bash
oc create -f secret.yaml
```

### Install the Admission Controller

Next, we’ll install the Admission Controller. The Admission Controller is a special controller that ensures our CouchbaseCluster configurations are valid. You can read more about it at https://docs.couchbase.com/operator/current/install-admission-controller.html

```bash
oc create -f admission.yaml
```

You can check the status by running `oc get pods`. Once you see the admission controller pod running, you can move onto the next step.

### Install the Operator Role and Service Account

First, we must install the Custom Resource Definition for Couchbase. A Custom Resource Definition allows to “extend” the Kubernetes API by enabling a new type of resource called a “CouchbaseCluster”. The Operator will monitor the cluster for any state changes related to any CouchbaseCluster resources and respond accordingly.

```bash
oc create -f crd.yaml
```

Next, we need to setup a role, a service account, and then bind them together. The service account will run the Operator for us. You can run these commands individually or paste them all at once. The command line tools will process them one at a time.

```bash
oc create -f operator-role.yaml --namespace cb-example

oc create serviceaccount couchbase-operator --namespace cb-example

oc create rolebinding couchbase-operator-rolebinding --role couchbase-operator --serviceaccount cb-example:couchbase-operator
```

### Install the Operator

Finally we are ready to install the Operator.

```bash
oc create -f operator-deployment.yaml
```

To monitor the status, run oc get pods -w. This will “watch” the state of your pods. You should eventually see the operator pod is running. At this point you should have 2 running pods. One for the Admission Controller, and one for the Operator. The out put of oc get pods should look something like this:

```bash
> oc get pods
couchbase-operator-796cd485df-7m866            1/1       Running   0          1m
couchbase-operator-admission-7565fb447-7pgf7   1/1       Running   0          10m
```

### Install a Storage Class for Persistent Volumes

The Couchbase Autonomous Operator uses dynamic provisioning to create persistent volumes for our Couchbase nodes. You can read more at https://docs.couchbase.com/operator/1.2/persistent-volumes-guide.html

Copy and paste the following yaml to a file named `couchbase-sc.yaml` your current working directory:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  labels:
    k8s-addon: storage-aws.addons.k8s.io
  name: couchbase-sc
parameters:
  type: gp2
  zone: us-west-2a
provisioner: kubernetes.io/aws-ebs
reclaimPolicy: Delete
```

Alternatively, if you checked out this repo, the `couchbase-sc.yaml` file is in the yaml directory.

**Make sure you update the zone parameter to the AWS availability zone where your OpenShift nodes are located**. This isn’t required, but performance improves the closer your PersistentVolumes are to your Couchbase nodes.

Now let’s install the storage class:

```bash
oc create -f couchbase-sc.yaml
```

You can confirm that the storage class was installed by running `oc get sc`. You should see the couchbase-sc storage class listed in the output.

## Deploy a 2 Node Couchbase Cluster

Now we are ready to install a Couchbase cluster that uses the new Storage Class that we just created. Copy and paste the following yaml to a file in your current working directory, I call it `couchbase-cluster-pvs.yaml`. Alternatively you find this yaml file in the `yaml` directory of this repo.

```yaml
apiVersion: couchbase.com/v1
kind: CouchbaseCluster
metadata:
  name: cb-example
spec:
  authSecret: cb-example-auth
  exposeAdminConsole: true
  adminConsoleServices:
    - data
  exposedFeatures:
    - xdcr
  exposedFeatureServiceType: NodePort
  softwareUpdateNotifications: true
  disableBucketManagement: false
  logRetentionTime: 604800s
  logRetentionCount: 20
  baseImage: registry.connect.redhat.com/couchbase/server
  buckets:
    - conflictResolution: seqno
      enableFlush: true
      evictionPolicy: fullEviction
      ioPriority: high
      memoryQuota: 128
      conflictResolution: seqno
      name: tweets
      replicas: 1
      type: couchbase
      compressionMode: passive
  cluster:
    analyticsServiceMemoryQuota: 1024
    autoFailoverMaxCount: 3
    autoFailoverOnDataDiskIssues: true
    autoFailoverOnDataDiskIssuesTimePeriod: 120
    autoFailoverServerGroup: false
    autoFailoverTimeout: 10
    clusterName: cb-example
    dataServiceMemoryQuota: 512
    eventingServiceMemoryQuota: 256
    indexServiceMemoryQuota: 512
    indexStorageSetting: memory_optimized
    searchServiceMemoryQuota: 256
  servers:
    - name: all_services
      services:
        - data
        - index
        - query
      size: 2
      pod:
        volumeMounts:
          default: couchbase
          data: couchbase
  version: 6.0.1-1         
  volumeClaimTemplates:
  - metadata:
      name: couchbase
    spec:
      storageClassName: "couchbase-sc"
      resources:
        requests:
          storage: 5Gi  
```

Now create the couchbase cluster by running:

```bash
oc create -f couchbase-cluster-pvs.yaml
```

At this point you should start seeing Couchbase Pods being created. Run `oc get pods -w` to watch the status of the pods. Once both pods are running (cb-example-0000 and cb-example-0001) you can move on to the next step.


### Expose Couchbase Admin UI

**Create route for Couchbase Admin** - Go to **Networking > Routes**, click “Create Route”.

Fill in the details and select the “cb-example-ui” service:

![](img/11.png)

After creating the route, you will be shown a URL on the next page:

![](img/12.png)

Click on this link and login to Couchbase with “Administrator” and “password”. Go to the **Servers** page, show the warning about not enough nodes:

![](img/13.png)

## Scaling the Cluster to 3 nodes

We made a mistake in the previous step (on purpose!) We need at least 3 nodes to support the redundancy we want. Couchbase recommends at least 3 nodes regardless to ensure a quorum.

To fix this, edit `couchbase-cluster-pvs.yaml`, and change line 51 to `size: 3`:

```yaml
      size: 3
```

Now run:

```bash
oc replace -f couchbase-cluster-pvs.yaml
```

Once again, you can run `oc get pods -w` to watch the new pod come online. You can also watch the new node appear from the Couchbase Admin. Once the new node is added the warning will go away.


## Deploying the Twitter App

![](img/15.png)

Next we are going to deploy an application that will ingest tweets in real-time from twitter.

Run the following commands in the following order:

### Deploy API service

```
oc new-app registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:latest~https://github.com/couchbase-partners/redhat-pds.git#release-2.0 \
      -e COUCHBASE_CLUSTER=cb-example \
      -e COUCHBASE_USER=Administrator \
      -e COUCHBASE_PASSWORD=password \
      -e COUCHBASE_TWEET_BUCKET=tweets \
      --context-dir=cb-rh-twitter/twitter-api \
      --name=twitter-api
```

You can watch the build from the OpenShift Ui by going to **Builds > Builds > twitter-api > Logs**

When the build is completed, a service is also created. We need to expose the route to the API service. Follow the same steps as we did for the Couchbase service by going to Networking > Routes. Name the route twitter-api and point it to port 8080. 

**Open the URL in your browser**. Add “/tweetcount” to the URL to test the API is working. It should return a 0. For example: http://twitter-api-cb-example0.apps.CLUSTER_ID.couchbasedemos.com/tweetcount

### Deploy the UI

This command just points to an existing container image on Docker Hub. OCP will deploy it and create a service for us.

```
oc new-app ezeev/twitter-ui:release-1.0
```

Create a route called “twitter-ui” using the same steps as the previous routes. This service is running on port 5000. Open the URL: 

http://twitter-ui-cb-example0.apps.CLUSTER_ID.couchbasedemos.com/

Add the following the twitter URL in your browser:

```
?apiBase=<url to api service>
```

For example:

http://twitter-ui-cb-example0.apps.CLUSTER_ID.couchbasedemos.com/?apiBase=http://twitter-api-cb-example0.apps.CLUSTER_ID.couchbasedemos.com


### Deploy the Tweet Ingester

The final step is to deploy the tweet ingester. We don’t need to create any routes for this service because it only communicates internally with Couchbase.

Note the `TWITTER_FILTER` variable below. Replace this with 1-3 trending hashtags or topics (comma separated) of interest on Twitter in order to get a good sized dataset.

```
oc new-app registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:latest~https://github.com/couchbase-partners/redhat-pds.git#release-2.0 \
       -e TWITTER_CONSUMER_KEY=YOUR_TWITTER_CONSUMER_KEY \
       -e TWITTER_CONSUMER_SECRET=YOUR_TWITTER_CONSUMER_SECRET \
       -e TWITTER_TOKEN=YOUR_TWITTER_TOKEN \
       -e TWITTER_SECRET=YOUR_TWITTER_SECRET \
       -e TWITTER_FILTER='#TuesdayThoughts,#TuesdayMotivation' \
       -e COUCHBASE_CLUSTER=cb-example \
       -e COUCHBASE_USER=Administrator \
       -e COUCHBASE_PASSWORD=password \
       -e COUCHBASE_TWEET_BUCKET=tweets \
       --context-dir=cb-rh-twitter/twitter-streamer \
       --name=twitter-streamer

```

Once the build is complete, you will see tweets flowing into the tweets bucket, and you should see the Twitter UI presenting data.

## Kill a Couchbase node

Next, we are going to manually kill a Couchbase node and watch the Operator "heal" our cluster by bringing it back to our desired number of nodes.

There should be a pod named `cb-example-0002`. Lets kill this one by running:

```bash
oc delete pod cb-example-0002
```

It does not matter which Couchbase pod you choose to delete. At this point you should see the Couchbase Admin alerting you that a node is unresponsive. Over the next couple of minutes you will see a new Couchbase pod get created, added to the cluster, and then finally the data will rebalance automatically to populated the new node with data.

The whole time this is happening, you should also see the Twitter UI showing new data. The cluster should heal itself with no interruption to our application or loss of data.

## Perform a Rolling Upgrade

Next we are going to upgrade our Couchbase cluster from version 6.0.1 to 6.0.2.

To do this, edit line 56 in `couchbase-cluster-pvs.yaml`. Change it to:

```yaml
  version: 6.0.2-1 
```

Then, run:

```bash
oc replace -f couchbase-cluster-pvs.yaml
```

You will see a 4th Couchbase pod created and added to the cluster. The new pod will be running version 6.0.2. Once the 4th pod is added and rebalanced, one of the first 6.0.1 pod will be deleted, and then another new 6.0.2 pod will get created. This cycle will repeat until all Couchbase pods have been upgraded to 6.0.2.


## Appendix
Cleaning up the app services manually
The quickest way to reset the cluster back to the beginning, is to just delete the project. Alternatively you can run these commands:

```
oc delete dc twitter-streamer
oc delete bc twitter-streamer
oc delete svc twitter-streamer

oc delete dc twitter-api
oc delete bc twitter-api
oc delete svc twitter-api
oc delete route twitter-api

oc delete dc twitter-ui
oc delete bc twitter-ui
oc delete svc twitter-ui
oc delete route twitter-ui

oc delete route cb-admin-ui
```