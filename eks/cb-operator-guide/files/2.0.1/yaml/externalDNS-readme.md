

## How create externalDNS [[url](https://eksctl.io/usage/iamserviceaccounts/)]

### 1: Create IAM Policy

First we need to create an IAM policy by name `AllowExternalDNSUpdates`

```BASH
$ aws iam create-policy \
  --policy-name AllowExternalDNSUpdates \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["route53:ChangeResourceRecordSets"],"Resource":["arn:aws:route53:::hostedzone/*"]},{"Effect":"Allow","Action":["route53:ListHostedZones","route53:ListResourceRecordSets"],"Resource":["*"]}]}'

```
Copy the ARN of the policy as we are going to use it next.

### 2: Associate OIDC

```BASH
$ eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=eksCluster --approve

[ℹ]  eksctl version 0.35.0
[ℹ]  using region us-west-2
[ℹ]  will create IAM Open ID Connect provider for cluster "eksCluster" in "us-west-2"
[✔]  created IAM Open ID Connect provider for cluster "eksCluster" in "us-west-2"
```


### 3: Create Service Account creation

Note we are going to create the service-account under  `default` namespace. If you want to to use a different namespace then make sure you change the same namespace under `ClusterRoleBinding` section of [externalDNS.yaml](externalDNS.yaml).

```BASH

$ eksctl create iamserviceaccount  \
  --name external-dns-sa  \
  --namespace default   \
  --cluster eksCluster   \
  --attach-policy-arn arn:aws:iam::778144681069:policy/AllowExternalDNSUpdates   \
  --approve   \
  --override-existing-serviceaccounts   \
  --region us-west-2



  [ℹ]  eksctl version 0.35.0
  [ℹ]  using region us-west-2
  [ℹ]  1 iamserviceaccount (default/external-dns-sa) was included (based on the include/exclude rules)
  [!]  metadata of serviceaccounts that exist in Kubernetes will be updated, as --override-existing-serviceaccounts was set
  [ℹ]  1 task: { 2 sequential sub-tasks: { create IAM role for serviceaccount "default/external-dns-sa", create serviceaccount "default/external-dns-sa" } }
  [ℹ]  building iamserviceaccount stack "eksctl-demoEKS-addon-iamserviceaccount-default-external-dns-sa"
  [ℹ]  deploying stack "eksctl-demoEKS-addon-iamserviceaccount-default-external-dns-sa"
  [ℹ]  created serviceaccount "default/external-dns-sa"

```


### 4: Display ARN

```BASH
$ eksctl get iamserviceaccount --cluster eksCluster --region us-west-2

NAMESPACE	NAME				ROLE ARN
default		external-dns-iam-sa-cbdb	arn:aws:iam::7781:role/eksctl-pgeDemo-addon-iamserviceaccount-defau-Role1-1AKXRKOW6CJYN
```

After creating the service account you can replace `ServiceAccount` and `ServiceAccountName` in the `external-dns.yaml` file with `external-dns-iam-sa-cbdb` value.

### 5: Replace HostedZoneID of your Domain

We would need the `hostedzone` ID of our Domain so we can paste it later on in the [externalDNS.yaml](externalDNS.yaml) file.

```BASH
$ aws route53 list-hosted-zones-by-name --output json --dns-name "cbdbdemo.com" | jq -r '.HostedZones[0].Id'
/hostedzone/Z085
```

Copy the id `Z085` and replace field `--txt-owner-id=Z085` within [externalDNS.yaml](externalDNS.yaml) file. Once done, run the below command to create the pod in default namespace:

```BASH
$kubectl create -f yaml/external-dns.yaml
```
