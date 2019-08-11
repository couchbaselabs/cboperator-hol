# Setup GKS Cluster

The following section will walk through the steps to create the GKS cluster.  This GKS cluster will be used to deploy Couchbase Autonomous Operator later in the lab.

## Set up GKS Creation Script

 In order to automate the setup we have written python based scripts which can be configured to deploy the GKS Cluster under anybody's Google account. Please follow through the steps below:

### Step 1. Google SDK Setup & Create your project **_my-couchbase-helm_** 
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
| Set your default project | ``` $ gcloud config set project my-couchbase-helm ```|
| Set default region | ```$ gcloud config set compute/region europe-west3```|
| Set default zone | ```$ gcloud config set compute/zone europe-west3-a```|

### Step 4. **Setup Network Setup**

*   **4.1. Create Custom Network configuration**
```  
$ gcloud compute networks create helm-network --subnet-mode custom
```

*   **4.2. Create Subnet on region europe-west1**
```
$ gcloud compute networks subnets create my-subnet-europe-west1 --network helm-network --region europe-west1 --range 10.0.0.0/12
```
*   **4.3. Create Subnet on region europe-west3**
```
$ gcloud compute networks subnets create my-subnet-europe-west3 --network helm-network --region europe-west3 --range 10.16.0.0/12
```
*   **4.4. Add Firewall rules:**
```
$ gcloud compute firewall-rules create my-network-allow-all-private --network helm-network --direction INGRESS --source-ranges 10.0.0.0/8 --allow all
```

### Step 5. **Provisioning Instances for the Kubernetes-Helm Cluster**

*   **5.1. Create instances for Cluster 1 in europe-west1 zone b**
```
$ gcloud container clusters create my-cluster-europe-west1-b --machine-type n1-standard-2 --cluster-version 1.13.6-gke.0 --zone europe-west1-b --network helm-network --subnetwork my-subnet-europe-west1 --num-nodes 3
```

*   **5.2. Create three instances for cluster 2 in europe-west3 zone a**
```
$ gcloud container clusters create my-cluster-europe-west3-a --machine-type n1-standard-2 --cluster-version 1.13.6-gke.0 --zone europe-west3-a --network helm-network --subnetwork my-subnet-europe-west3 --num-nodes 3
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
Make sure number of nodes requested in [parameters.py](https://github.com/couchbaselabs/cbsummit-create-eks-cluster/blob/master/parameters.py) is what has been deployed

```
$ kubectl get nodes

NAME                                        	STATUS   ROLES	AGE   VERSION
ip-192-168-166-206.us-east-2.compute.internal   Ready	<none>   11m   v1.11.5
ip-192-168-248-36.us-east-2.compute.internal	Ready	<none>   11m   v1.11.5
ip-192-168-64-16.us-east-2.compute.internal 	Ready	<none>   11m   v1.11.5
```


--- ----------
This page shows how to install the Google Cloud SDK, initialize it, and run core gcloud commands from the command-line.

# Before you begin

➜  ~ python -V
Python 2.7.10

Download
https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-257.0.0-darwin-x86_64.tar.gz


Install 
➜  google-cloud-sdk ./install.sh  
Welcome to the Google Cloud SDK!

To help improve the quality of this product, we collect anonymized usage data
and anonymized stacktraces when crashes are encountered; additional information
is available at <https://cloud.google.com/sdk/usage-statistics>. You may choose
to opt out of this collection now (by choosing 'N' at the below prompt), or at
any time in the future by running the following command:

    gcloud config set disable_usage_reporting true

Do you want to help improve the Google Cloud SDK (Y/n)?  Y


Your current Cloud SDK version is: 257.0.0
The latest available version is: 257.0.0

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                 Components                                                 │
├───────────────┬──────────────────────────────────────────────────────┬──────────────────────────┬──────────┤
│     Status    │                         Name                         │            ID            │   Size   │
├───────────────┼──────────────────────────────────────────────────────┼──────────────────────────┼──────────┤
│ Not Installed │ App Engine Go Extensions                             │ app-engine-go            │ 56.4 MiB │
│ Not Installed │ Cloud Bigtable Command Line Tool                     │ cbt                      │  7.3 MiB │
│ Not Installed │ Cloud Bigtable Emulator                              │ bigtable                 │  6.6 MiB │
│ Not Installed │ Cloud Datalab Command Line Tool                      │ datalab                  │  < 1 MiB │
│ Not Installed │ Cloud Datastore Emulator                             │ cloud-datastore-emulator │ 18.4 MiB │
│ Not Installed │ Cloud Datastore Emulator (Legacy)                    │ gcd-emulator             │ 38.1 MiB │
│ Not Installed │ Cloud Firestore Emulator                             │ cloud-firestore-emulator │ 36.1 MiB │
│ Not Installed │ Cloud Pub/Sub Emulator                               │ pubsub-emulator          │ 34.8 MiB │
│ Not Installed │ Cloud SQL Proxy                                      │ cloud_sql_proxy          │  3.7 MiB │
│ Not Installed │ Emulator Reverse Proxy                               │ emulator-reverse-proxy   │ 14.5 MiB │
│ Not Installed │ Google Cloud Build Local Builder                     │ cloud-build-local        │  5.9 MiB │
│ Not Installed │ Google Container Registry's Docker credential helper │ docker-credential-gcr    │  1.8 MiB │
│ Not Installed │ gcloud Alpha Commands                                │ alpha                    │  < 1 MiB │
│ Not Installed │ gcloud Beta Commands                                 │ beta                     │  < 1 MiB │
│ Not Installed │ gcloud app Java Extensions                           │ app-engine-java          │ 85.9 MiB │
│ Not Installed │ gcloud app PHP Extensions                            │ app-engine-php           │ 21.9 MiB │
│ Not Installed │ gcloud app Python Extensions                         │ app-engine-python        │  6.0 MiB │
│ Not Installed │ gcloud app Python Extensions (Extra Libraries)       │ app-engine-python-extras │ 28.5 MiB │
│ Not Installed │ kubectl                                              │ kubectl                  │  < 1 MiB │
│ Installed     │ BigQuery Command Line Tool                           │ bq                       │  < 1 MiB │
│ Installed     │ Cloud SDK Core Libraries                             │ core                     │ 11.3 MiB │
│ Installed     │ Cloud Storage Command Line Tool                      │ gsutil                   │  3.6 MiB │
└───────────────┴──────────────────────────────────────────────────────┴──────────────────────────┴──────────┘
To install or remove components at your current SDK version [257.0.0], run:
  $ gcloud components install COMPONENT_ID
  $ gcloud components remove COMPONENT_ID

To update your SDK installation to the latest version [257.0.0], run:
  $ gcloud components update



To take a quick anonymous survey, run:
  $ gcloud alpha survey


Modify profile to update your $PATH and enable shell command 
completion?

Do you want to continue (Y/n)?  Y


# Initialize the SDK

 gcloud init --console-only
Welcome! This command will take you through the configuration of gcloud.

Settings from your current configuration [couchbase-helm-config] are:
compute:
  region: europe-west3
  zone: europe-west3-a
core:
  account: jose.molina@couchbase.com
  disable_usage_reporting: 'False'
  project: my-couchbase-helm

Pick configuration to use:
 [1] Re-initialize this configuration [couchbase-helm-config] with new settings 
 [2] Create a new configuration
 [3] Switch to and re-initialize existing configuration: [default]
Please enter your numeric choice:  2

Enter configuration name. Names start with a lower case letter and 
contain only lower case letters a-z, digits 0-9, and hyphens '-':  my-couchbase-gke
Your current configuration has been set to: [my-couchbase-gke]

You can skip diagnostics next time by using the following flag:
  gcloud init --skip-diagnostics

Network diagnostic detects and fixes local network connection issues.
Checking network connection...done.                                            
Reachability Check passed.
Network diagnostic passed (1/1 checks passed).

Choose the account you would like to use to perform operations for 
this configuration:
 [1] jose.molina@couchbase.com
 [2] Log in with a new account
Please enter your numeric choice:  1

You are logged in as: [jose.molina@couchbase.com].

Pick cloud project to use: 
 [1] couchbase-gke
 [2] couchbase-se-west-us
 [3] helmchart
 [4] my-couchbase-helm
 [5] Create a new project
Please enter numeric choice or text value (must exactly match list 
item):  1

Your current project has been set to: [couchbase-gke].

Not setting default zone/region (this feature makes it easier to use
[gcloud compute] by setting an appropriate default value for the
--zone and --region flag).
See https://cloud.google.com/compute/docs/gcloud-compute section on how to set
default compute region and zone manually. If you would like [gcloud init] to be
able to do this for you the next time you run it, make sure the
Compute Engine API is enabled for your project on the
https://console.developers.google.com/apis page.

Your Google Cloud SDK is configured and ready to use!

* Commands that require authentication will use jose.molina@couchbase.com by default
* Commands will reference project `couchbase-gke` by default
Run `gcloud help config` to learn how to change individual settings

This gcloud configuration is called [my-couchbase-gke]. You can create additional configurations if you work with multiple accounts and/or projects.
Run `gcloud topic configurations` to learn more.

Some things to try next:

* Run `gcloud --help` to see the Cloud Platform services you can interact with. And run `gcloud help COMMAND` to get help on any gcloud command.
* Run `gcloud topic --help` to learn about advanced features of the SDK like arg files and output formatting


gcloud auth list
      Credentialed Accounts
ACTIVE  ACCOUNT
*       jose.molina@couchbase.com

To set the active account, run:
    $ gcloud config set account `ACCOUNT`
    
    

gcloud config list
[core]
account = jose.molina@couchbase.com
disable_usage_reporting = False
project = couchbase-gke

Your active configuration is: [my-couchbase-gke]

gcloud info
Google Cloud SDK [257.0.0]

Platform: [Mac OS X, x86_64] ('Darwin', 'EMEA-JoseMolina.local', '18.6.0', 'Darwin Kernel Version 18.6.0: Thu Apr 25 23:16:27 PDT 2019; root:xnu-4903.261.4~2/RELEASE_X86_64', 'x86_64', 'i386')
Locale: ('en_GB', 'UTF-8')
Python Version: [2.7.10 (default, Feb 22 2019, 21:55:15)  [GCC 4.2.1 Compatible Apple LLVM 10.0.1 (clang-1001.0.37.14)]]
Python Location: [/System/Library/Frameworks/Python.framework/Versions/2.7/Resources/Python.app/Contents/MacOS/Python]
Site Packages: [Disabled]

Installation Root: [/Users/josemolina/google-cloud-sdk]
Installed Components:
  core: [2019.08.02]
  gsutil: [4.41]
  bq: [2.0.46]
System PATH: [/Users/josemolina/google-cloud-sdk/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/share/dotnet:~/.dotnet/tools:/Library/Frameworks/Mono.framework/Versions/Current/Commands:/Applications/Xamarin Workbooks.app/Contents/SharedSupport/path-bin]
Python PATH: [/Users/josemolina/google-cloud-sdk/lib/third_party:/Users/josemolina/google-cloud-sdk/lib:/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python27.zip:/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/:/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/plat-darwin:/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/plat-mac:/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/plat-mac/lib-scriptpackages:/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/lib-tk:/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/lib-old:/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/lib-dynload]
Cloud SDK on PATH: [True]
Kubectl on PATH: [/usr/local/bin/kubectl]

Installation Properties: [/Users/josemolina/google-cloud-sdk/properties]
User Config Directory: [/Users/josemolina/.config/gcloud]
Active Configuration Name: [my-couchbase-gke]
Active Configuration Path: [/Users/josemolina/.config/gcloud/configurations/config_my-couchbase-gke]

Account: [jose.molina@couchbase.com]
Project: [couchbase-gke]

Current Properties:
  [core]
    project: [couchbase-gke]
    account: [jose.molina@couchbase.com]
    disable_usage_reporting: [False]

Logs Directory: [/Users/josemolina/.config/gcloud/logs]
Last Log File: [/Users/josemolina/.config/gcloud/logs/2019.08.08/19.11.01.037516.log]

git: [git version 2.20.1 (Apple Git-117)]
ssh: [OpenSSH_7.9p1, LibreSSL 2.7.3]


Set default region

gcloud config set compute/region europe-west3

Updated property [compute/region].

# Network

gcloud compute networks create my-network --subnet-mode custom
Created [https://www.googleapis.com/compute/v1/projects/my-couchbase-helm/global/networks/my-network].
NAME        SUBNET_MODE  BGP_ROUTING_MODE  IPV4_RANGE  GATEWAY_IPV4
my-network  CUSTOM       REGIONAL

Instances on this network will not be reachable until firewall rules
are created. As an example, you can allow all internal traffic between
instances as well as SSH, RDP, and ICMP by running:

$ gcloud compute firewall-rules create <FIREWALL_NAME> --network my-network --allow tcp,udp,icmp --source-ranges <IP_RANGE>
$ gcloud compute firewall-rules create <FIREWALL_NAME> --network my-network --allow tcp:22,tcp:3389,icmp


gcloud compute networks subnets create my-subnet-europe-west1 --network my-network --region europe-west1 --range 10.0.0.0/12
Created [https://www.googleapis.com/compute/v1/projects/my-couchbase-helm/regions/europe-west1/subnetworks/my-subnet-europe-west1].
NAME                    REGION        NETWORK     RANGE
my-subnet-europe-west1  europe-west1  my-network  10.0.0.0/12
➜  ~ gcloud compute networks subnets create my-subnet-europe-west3 --network my-network --region europe-west3 --range 10.16.0.0/12
Created [https://www.googleapis.com/compute/v1/projects/my-couchbase-helm/regions/europe-west3/subnetworks/my-subnet-europe-west3].
NAME                    REGION        NETWORK     RANGE
my-subnet-europe-west3  europe-west3  my-network  10.16.0.0/12



gcloud compute firewall-rules create my-network-allow-all-private --network my-network --direction INGRESS --source-ranges 10.0.0.0/8 --allow all
Creating firewall...⠧Created [https://www.googleapis.com/compute/v1/projects/my-couchbase-helm/global/firewalls/my-network-allow-all-private].                                       
Creating firewall...done.                                                                                                                                                            
NAME                          NETWORK     DIRECTION  PRIORITY  ALLOW  DENY  DISABLED
my-network-allow-all-private  my-network  INGRESS    1000      all          False



## Troubleshooting

➜  ~ gcloud container clusters create my-cluster-europe-west1-b --machine-type n1-standard-2 --cluster-version 1.13.6-gke.0 --region europe-west1 --network helm-network --subnetwork my-subnet-europe-west1 --num-nodes 1

WARNING: In June 2019, node auto-upgrade will be enabled by default for newly created clusters and node pools. To disable it, use the `--no-enable-autoupgrade` flag.
WARNING: Starting in 1.12, new clusters will have basic authentication disabled by default. Basic authentication can be enabled (or disabled) manually using the `--[no-]enable-basic-auth` flag.
WARNING: Starting in 1.12, new clusters will not have a client certificate issued. You can manually enable (or disable) the issuance of the client certificate using the `--[no-]issue-client-certificate` flag.
WARNING: Currently VPC-native is not the default mode during cluster creation. In the future, this will become the default mode and can be disabled using `--no-enable-ip-alias` flag. Use `--[no-]enable-ip-alias` flag to suppress this warning.
WARNING: Starting in 1.12, default node pools in new clusters will have their legacy Compute Engine instance metadata endpoints disabled by default. To create a cluster with legacy instance metadata endpoints disabled in the default node pool, run `clusters create` with the flag `--metadata disable-legacy-endpoints=true`.
WARNING: Your Pod address range (`--cluster-ipv4-cidr`) can accommodate at most 1008 node(s). 
This will enable the autorepair feature for nodes. Please see https://cloud.google.com/kubernetes-engine/docs/node-auto-repair for more information on node autorepairs.
ERROR: (gcloud.container.clusters.create) ResponseError: code=400, message=Master version "1.13.6-gke.0" is unsupported.
➜  ~ gcloud container clusters create my-cluster-europe-west1-b --machine-type n1-standard-2 **--cluster-version 1.13.6-gke.0** --zone europe-west1-b --network helm-network --subnetwork my-subnet-europe-west1 --num-nodes 3

cluster version... 

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
- 1.12.8-gke.10
- 1.12.7-gke.25
- 1.11.10-gke.5
validNodeVersions:
- 1.14.3-gke.9
- 1.14.2-gke.9
- 1.14.1-gke.5
- 1.13.7-gke.8
- 1.13.7-gke.0
- 1.13.6-gke.13
- 1.13.6-gke.6
- 1.13.6-gke.5
- 1.13.6-gke.0
- 1.13.5-gke.10
- 1.12.9-gke.7
- 1.12.9-gke.3
- 1.12.8-gke.10
- 1.12.8-gke.7
- 1.12.8-gke.6
- 1.12.7-gke.25
- 1.12.7-gke.24
- 1.12.7-gke.21
- 1.12.7-gke.17


gcloud container clusters create my-cluster-europe-west1-b --machine-type n1-standard-2  --zone europe-west1-b --network my-network --subnetwork my-subnet-europe-west1 --num-nodes 3 **--cluster-version 1.13.7-gke.8**




