# Setup EKS Cluster

The following section will walk through the steps to create the EKS cluster.  This EKS cluster will be used to deploy Couchbase Autonomous Operator later in the lab.

## Set up EKS Creation Script

 In order to automate the setup we have written python based scripts which can be configured to deploy the EKS Cluster under anybody's AWS account. Please follow through the steps below:

### Step 1. Clone EKS Creation Scripts repo

```
  $ git clone https://github.com/couchbaselabs/cbsummit-create-eks-cluster.git
  Cloning into 'create_eks_cluster'...
  remote: Enumerating objects: 30, done.
  remote: Counting objects: 100% (30/30), done.
  remote: Compressing objects: 100% (21/21), done.
  remote: Total 30 (delta 13), reused 20 (delta 7), pack-reused 0
  Unpacking objects: 100% (30/30), done.
```


### Step 2. CD into newly clone directory
```
$ cd cbsummit-create-eks-cluster
$ ls -l
total 48
-rw-r--r--  1 mmaster  staff  4633 14 Jan 06:40 README.md
-rw-r--r--  1 mmaster  staff  8893 14 Jan 06:40 create_eks_script.py
-rw-r--r--  1 mmaster  staff  1383 14 Jan 06:55 parameters.py
```
More details on this script can be found in the [README.md](https://github.com/couchbaselabs/cbsummit-create-eks-cluster/blob/master/README.md) provided within the repository

### Step 3. Change the parameters for your set up

The following shows the list of parameters in [parameters.py](https://github.com/couchbaselabs/cbsummit-create-eks-cluster/blob/master/parameters.py) that you are likely to change. It is required to change VPC_STACK_NAME, EKS_CLUSTER_NAME, EKS_NODES_STACK_NAME, and EKS_NODE_GROUP_NAME. The value of EKS_CLUSTER_NAME is the cluster name that will be provided to the participants/users. All other parameters can be left as default or adjusted based on the requirements of the summit, e.g. number of participants expected:

| Parameter Name              | Description |
| --------------------- | ----------- |
|VPC_STACK_NAME  |  This is the name of the Stack for the VPC|
| EKS_CLUSTER_NAME  | This is the name of the EKS Cluster to create|
|EKS_NODES_STACK_NAME  | This is the name of the Stack for the EC2 worker nodes|
|EKS_NODE_GROUP_NAME  | This is the name of the Autoscaling group for the EC2 worker nodes|
|EKS_NODE_AS_GROUP_MIN  | The minimum size of the autoscaling group|
|EKS_NODE_AS_GROUP_MAX  | The maximum size of the autoscaling group|
|EKS_NODE_AS_GROUP_DESIRED | The desired cluster size, should be >= * EKS_NODE_AS_GROUP_MIN and <= EKS_NODE_AS_GROUP_MAX|
|EKS_NODE_INSTANCE_TYPE. | The type of instance you want to use as a worker node|
|EKS_IMAGE_ID  | This only needs to be changed if you are not deploying into the us-east-2 region.|
|EKS_NODE_VOLUME_SIZE  | If you need additional disk space|

```
$ cat parameters.py
ATTEMPTS=10
WAIT_SEC=120

#===============================
#	VPC Information
#===============================
VPC_STACK_NAME="ckteststackmm"
VPC_TEMPLATE="https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-12-10/amazon-eks-vpc-sample.yaml"

#===============================
#	EKS Cluster
#===============================
EKS_CLUSTER_NAME="cktestclustermm"
EKS_ROLE_ARN="arn:aws:iam::669678783832:role/cbd-eks-role"

#===============================
#	EKS Worker Nodes
#===============================
EKS_NODES_TEMPLATE="https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-12-10/amazon-eks-nodegroup.yaml"
EKS_NODES_STACK_NAME="cktestclustermm-nodes"
EKS_NODE_GROUP_NAME="cktestclustermm-eks-nodes"
EKS_NODE_AS_GROUP_MIN="3"
EKS_NODE_AS_GROUP_MAX="3"
EKS_NODE_AS_GROUP_DESIRED="3"

#Amazon instance type - Refer to Amazon Documentation for available values
EKS_NODE_INSTANCE_TYPE="m4.xlarge"

#Amazon Image Id - Refer to https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html for full list.  The region is important for AMI to use.  The below is for us-east-2
EKS_IMAGE_ID="ami-053cbe66e0033ebcf"

#The IAM Key to use
EKS_KEY_NAME="cb-day-se"

EKS_NODE_VOLUME_SIZE="20"

#===============================
#	Secondary User
#===============================
AWS_SECOND_USER_ARN="arn:aws:iam::669678783832:user/cb-day-participant"
AWS_SECOND_USER_NAME="cb-day-participant"
```

**EKS_IMAGE_ID**
If you are not deploying to the us-east-2 region, first validate that the region supports EKS, and also that you are using the correct AMI for that region.  The following table lists the regions with the assigned regions for each SE team, i.e. US & Canada should use us-east-2 and EMEA should use eu-west-1.

The list of AMI’s for available regions can be found at the below [here](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#eks-launch-workers).


### Step 4:  Execute the create_eks_script

This step will create the EKS cluster and the nodes as defined in the [parameters.py](https://github.com/couchbaselabs/cbsummit-create-eks-cluster/blob/master/parameters.py) file. The name of the EKS cluster defined earlier in the parameters file is what will have to be provided to the participants/users. This will appear in the output of the command, e.g. _cktestclustermm_ as shown in the example below for the aws eks create-cluster command. Verify that the correct cluster name has been issued in that command and provide that cluster name to the participants.

See the [README.md](https://github.com/couchbaselabs/cbsummit-create-eks-cluster/blob/master/README.md) for more details.

```
$ python create_eks_script.py install

--------------------------------------
Starting installation of EKS from step 0
--------------------------------------
--------------------------------------
Running aws cloudformation create-stack --stack-name ckteststackmm --template-url https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-12-10/amazon-eks-vpc-sample.yaml
--------------------------------------
Executing command : aws cloudformation create-stack --stack-name ckteststackmm --template-url https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-12-10/amazon-eks-vpc-sample.yaml
{

    "StackId": "arn:aws:cloudformation:us-east-2:669678783832:stack/ckteststackmm/d278e040-265a-11e9-a4be-02649197f7a0"

}

Checking completion status...
Checking attempt #0
Status :: "CREATE_IN_PROGRESS"
Checking attempt #1
Status :: "CREATE_COMPLETE"
Adding key SecurityGroups with value sg-0677229e743e97317
Adding key VpcId with value vpc-074ac91b494db16f2
Adding key SubnetIds with value subnet-06d16b69a017ce7a6,subnet-07d794f0b706800a3,subnet-0a4aee63ad0296add
--------------------------------------
Running aws eks create-cluster --name cktestclustermm --role-arn arn:aws:iam::669678783832:role/cbd-eks-role --resources-vpc-config subnetIds=subnet-06d16b69a017ce7a6,subnet-07d794f0b706800a3,subnet-0a4aee63ad0296add,securityGroupIds=sg-0677229e743e97317
--------------------------------------
Executing command : aws eks create-cluster --name cktestclustermm --role-arn arn:aws:iam::669678783832:role/cbd-eks-role --resources-vpc-config subnetIds=subnet-06d16b69a017ce7a6,subnet-07d794f0b706800a3,subnet-0a4aee63ad0296add,securityGroupIds=sg-0677229e743e97317
{

    "cluster": {

        "status": "CREATING",

        "name": "cktestclustermm",

        "certificateAuthority": {},

        "roleArn": "arn:aws:iam::669678783832:role/cbd-eks-role",

        "resourcesVpcConfig": {

            "subnetIds": [

                "subnet-06d16b69a017ce7a6",

                "subnet-07d794f0b706800a3",

                "subnet-0a4aee63ad0296add"

            ],

            "vpcId": "vpc-074ac91b494db16f2",

            "securityGroupIds": [

                "sg-0677229e743e97317"

            ]

        },

        "version": "1.11",

        "arn": "arn:aws:eks:us-east-2:669678783832:cluster/cktestclustermm",

        "platformVersion": "eks.1",

        "createdAt": 1549050837.583

    }

}

Checking completion status...
Checking attempt #0
Status :: "CREATING"
Checking attempt #1
Status :: "CREATING"
Checking attempt #2
Status :: "CREATING"
Checking attempt #3
Status :: "CREATING"
Checking attempt #4
Status :: "CREATING"
Checking attempt #5
Status :: "ACTIVE"
--------------------------------------
Executing command : aws eks update-kubeconfig --name cktestclustermm
Updated context arn:aws:eks:us-east-2:669678783832:cluster/cktestclustermm in /Users/mmaster/.kube/config

--------------------------------------
Running aws cloudformation create-stack --stack-name cktestclustermm-nodes --template-url https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-12-10/amazon-eks-nodegroup.yaml --parameters ParameterKey=ClusterName,ParameterValue=cktestclustermm ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=sg-0677229e743e97317 ParameterKey=NodeGroupName,ParameterValue=cktestclustermm-eks-nodes ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=3 ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=3 ParameterKey=NodeInstanceType,ParameterValue=m4.4xlarge ParameterKey=NodeImageId,ParameterValue=ami-053cbe66e0033ebcf ParameterKey=KeyName,ParameterValue=cb-day-se ParameterKey=VpcId,ParameterValue=vpc-074ac91b494db16f2 ParameterKey=Subnets,ParameterValue='subnet-06d16b69a017ce7a6\,subnet-07d794f0b706800a3\,subnet-0a4aee63ad0296add' ParameterKey=NodeVolumeSize,ParameterValue=20 --capabilities CAPABILITY_IAM
--------------------------------------
Executing command : aws cloudformation create-stack --stack-name cktestclustermm-nodes --template-url https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-12-10/amazon-eks-nodegroup.yaml --parameters ParameterKey=ClusterName,ParameterValue=cktestclustermm ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=sg-0677229e743e97317 ParameterKey=NodeGroupName,ParameterValue=cktestclustermm-eks-nodes ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=3 ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=3 ParameterKey=NodeInstanceType,ParameterValue=m4.4xlarge ParameterKey=NodeImageId,ParameterValue=ami-053cbe66e0033ebcf ParameterKey=KeyName,ParameterValue=cb-day-se ParameterKey=VpcId,ParameterValue=vpc-074ac91b494db16f2 ParameterKey=Subnets,ParameterValue='subnet-06d16b69a017ce7a6\,subnet-07d794f0b706800a3\,subnet-0a4aee63ad0296add' ParameterKey=NodeVolumeSize,ParameterValue=20 --capabilities CAPABILITY_IAM
{

    "StackId": "arn:aws:cloudformation:us-east-2:669678783832:stack/cktestclustermm-nodes/8640ef40-265c-11e9-8cdb-0659c08a3f80"

}

Checking completion status...
Checking attempt #0
Status :: "CREATE_IN_PROGRESS"
Checking attempt #1
Status :: "CREATE_IN_PROGRESS"
Checking attempt #2
Status :: "CREATE_COMPLETE"
--------------------------------------
Executing command : curl -O https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-12-10/aws-auth-cm.yaml
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current

                                 Dload  Upload   Total   Spent    Left  Speed

100   282  100   282    0     0    828      0 --:--:-- --:--:-- --:--:--   826

Adding key NodeInstanceRole with value arn:aws:iam::669678783832:role/cktestclustermm-nodes-NodeInstanceRole-9TNSS18FKU3L
Adding key NodeSecurityGroup with value sg-0c3e6913ef7c0f3cf
--------------------------------------
Executing command : kubectl apply -f aws-auth-cm.yaml
configmap/aws-auth created

--------------------------------------
Executing command : kubectl get -n kube-system configmap/aws-auth -o yaml > aws-auth-patch.yaml
--------------------------------------
Executing command : kubectl apply -n kube-system -f aws-auth-patch.yaml
configmap/aws-auth configured
```

This script will then run through the different steps to create the EKS Cluster, which can take up to 20 minutes. When completed you should see the output shown above.



### Step 5: Verify number of nodes
Make sure number of nodes requested in [parameters.py](https://github.com/couchbaselabs/cbsummit-create-eks-cluster/blob/master/parameters.py) is what has been deployed
```
$ kubectl get nodes

NAME                                        	STATUS   ROLES	AGE   VERSION
ip-192-168-166-206.us-east-2.compute.internal   Ready	<none>   11m   v1.11.5
ip-192-168-248-36.us-east-2.compute.internal	Ready	<none>   11m   v1.11.5
ip-192-168-64-16.us-east-2.compute.internal 	Ready	<none>   11m   v1.11.5
```
