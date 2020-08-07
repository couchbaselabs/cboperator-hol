# Setting up Monitoring with Prometheus Operator

## 1. Overview

The purpose of this guide is to describe an easy way to setup a demo for
monitoring Couchbase with Prometheus in Kubernetes. We will use the Autonomous
Operator to deploy Couchbase and the Prometheus Operator to deploy Prometheus
and Grafana.

There are different ways to install Prometheus in Kubernetes. The Prometheus
Operator provides an easy and modular way to deploy and configure Prometheus.
Instead of editing one big configuration file, we can add new exporters
and alert rules using the custom resources introduced by the operator.

## 2. Prerequisites

The guide assumes an already installed Kubernetes cluster. We will also use
helm for installing Prometheus.

The guide also includes steps to install the Autonomous Operator and deploy
a Couchbase cluster. If you have done this already you can skip the corresponding
steps. It is just important to specify the correct namespace and Couchbase cluster
name in the configuration files.

## 3. Installing Prometheus Operator

Check if the default charts repository is in the list:
```
helm repo list
```

If not add it:
```
helm repo add stable https://kubernetes-charts.storage.googleapis.com
```

We will install the Prometheus Operator in the namespace `prometheus` and
also use `prometheus` as the helm release name. You can freely choose other
names and use them consistently in the next steps.

```
kubectl create namespace prometheus

helm install -n prometheus prometheus stable/prometheus-operator
```

Let's check the services installed by the operator:
```
kubectl -n prometheus get svc
NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
alertmanager-operated                     ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   96s
prometheus-grafana                        ClusterIP   10.100.98.138    <none>        80/TCP                       108s
prometheus-kube-state-metrics             ClusterIP   10.100.255.239   <none>        8080/TCP                     108s
prometheus-operated                       ClusterIP   None             <none>        9090/TCP                     86s
prometheus-prometheus-node-exporter       ClusterIP   10.100.158.168   <none>        9100/TCP                     108s
prometheus-prometheus-oper-alertmanager   ClusterIP   10.100.91.246    <none>        9093/TCP                     108s
prometheus-prometheus-oper-operator       ClusterIP   10.100.80.42     <none>        8080/TCP,443/TCP             108s
prometheus-prometheus-oper-prometheus     ClusterIP   10.100.128.70    <none>        9090/TCP                     108s
```

## 4. Accessing Prometheus Services

To access the Prometheus and Graphana UI we can setup port forwarding for the
corresponding services (note the service names include the helm release name):

```
kubectl --namespace prometheus port-forward svc/prometheus-prometheus-oper-prometheus 9090 &
kubectl --namespace prometheus port-forward svc/prometheus-grafana 3000:80
```

Open Prometheus UI over http://localhost:9090/

To login into Graphana you will need admin password. It can be extracted by executing:

```
kubectl -n prometheus get secret prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
prom-operator
```

Open http://localhost:3000/ in the browser and login as `admin/prom-operator`

In an EKS deployment, we can easily enable access to the Prometheus services
over public DNS names by changing the service type to LoadBalancer.

To access the Prometheus, edit the service (note the service name includes
the helm release name):

```
kubectl -n prometheus edit svc prometheus-prometheus-oper-prometheus
```
Change the service type to `LoadBalancer`

```
  type: LoadBalancer
```

Check the generated DNS:
```
kubectl -n prometheus get svc prometheus-prometheus-oper-prometheus
... some-generated-id.eu-central-1.elb.amazonaws.com   9090:32231/TCP ...
```

Open http://some-generated-id.eu-central-1.elb.amazonaws.com:9090/ in the browser

Do the same to access the Grafana by changing the Grafana service type to
LoadBalancer:

```
kubectl -n prometheus edit svc prometheus-grafana
```

## 5. Installing Couchbase Autonomous Operator

Download and unpack the Autonomous Operator for your operating system.
Click here for
[AO2.0.1 on MacOS](https://packages.couchbase.com/kubernetes/2.0.1/couchbase-autonomous-operator-kubernetes_2.0.1-macos-x86_64.zip).

We will install the Operator in Couchbase into the namespace `demo`. You may
choose a different one and use consistently in the next steps.

```
kubectl create -f crd.yaml

kubectl create namespace demo

bin/cbopcfg --namespace demo | kubectl -n demo create -f -
```

## 6. Installing Couchbase Cluster with the Metrics Exporter

Create a file `demo-couchbase-cluster.yaml` with the configuration of
the Couchbase cluster. Here we deploy 3-node cluster named `demo` in
the namespace `demo` with Data, Index & Query services enabled. We also
create a bucket named `demo`.

```
apiVersion: v1
kind: Secret
metadata:
  name: cb-demo-auth
type: Opaque
data:
  username: QWRtaW5pc3RyYXRvcg== # Administrator
  password: cGFzc3dvcmQ=         # password
---
apiVersion: couchbase.com/v2
kind: CouchbaseBucket
metadata:
  name: demo
  labels:
    cluster: demo
spec:
  memoryQuota: 100Mi
  replicas: 1
---
apiVersion: couchbase.com/v2
kind: CouchbaseCluster
metadata:
  name: demo
spec:
  image: couchbase/server:6.5.1
  security:
    adminSecret: cb-demo-auth
  networking:
    exposeAdminConsole: true
  buckets:
    managed: true
  monitoring:
    prometheus:
      enabled: true
      image: couchbase/exporter:1.0.2
  servers:
  - size: 3
    name: all_services
    services:
    - data
    - index
    - query
    volumeMounts:
      default: couchbase-default
      data: couchbase-data
  volumeClaimTemplates:
    - metadata:
        name: couchbase-default
      spec:
        resources:
          requests:
            storage: 1Gi
    - metadata:
        name: couchbase-data
      spec:
        resources:
          requests:
            storage: 5Gi
```

Deploy the cluster:
```
kubectl -n demo apply -f demo-couchbase-cluster.yaml
```

For an existing Couchbase cluster just edit the cluster configuration managed
add the `monitoring` section as in the example above. In that
case a rotating configuration change will be performed: new Couchbase pods
will be created with 2 containers: one with Couchbase Server another with
the Exporter.

Now we will create a service to load balance over the metrics endpoints of
Couchbase pods.

Create a file `couchbase-metrics-service.yaml`:

```
apiVersion: v1
kind: Service
metadata:
  name: couchbase-metrics
  labels:
    app: couchbase
spec:
  ports:
  - name: metrics
    port: 9091
    protocol: TCP
  selector:
    app: couchbase
    couchbase_cluster: demo
```

Make sure you are referencing correct Couchbase cluster name and deploy
the service in the same namespace as the Couchbase cluster:

```
kubectl -n demo apply -f couchbase-metrics-service.yaml
```

To test the metrics service, setup port forwarding:
```
kubectl --namespace demo port-forward svc/couchbase-metrics 9091
```

Now if you open http://localhost:9091/metrics, you should see a list of Couchbase
metrics exported in the format expected by Prometheus.  

## 7. Exposing Couchbase Metrics in Prometheus

To expose Couchbase metrics in our Prometheus server we will create
a `ServiceMonitor`, which is a custom resource introduced by the Prometheus
Operator, which makes it easy to extend the Prometheus deployment with new
monitoring targets.

Create a file `couchbase-service-monitor.yaml`:

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: couchbase
  labels:
    app: couchbase
    release: prometheus
spec:
  jobLabel: couchbase
  selector:
    matchLabels:
      app: couchbase
  namespaceSelector:
    matchNames:
    - demo
  endpoints:
  - port: metrics
    interval: 15s
```

Note that it finds the Couchbase service by matching the label `app` to
`couchbase` and the namespace name to `demo`. Also it is important to
specify the correct prometheus release name, which is `prometheus` in our case.

We deploy the `ServiceMonitor` in the same namespace as the Prometheus installation:

```
kubectl -n prometheus apply -f couchbase-service-monitor.yaml
```

You can check if the Prometheus has found the Couchbase metrics by going into
the Prometheus UI and checking the list of targets. Now you can query Couchbase
metrics in the Prometheus UI and import Grafana dashboards.

## 8. Defining Prometheus Alerts

The alerts can be added in a modular way using `PrometheusRule` custom
resource.

Create a file `couchbase-alerts.yaml`:

```
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  labels:
    app: prometheus-operator
    release: prometheus
  name: couchbase-exporter-rules
spec:
  groups:
  - name: couchbase-exporter
    rules:
    - alert: Bucket_Info_Collector_Down
      expr: cbbucketinfo_up
      annotations:
        summary: Couchbase Exporter BucketInfo collector is down

    - alert: BucketStatCollectorUp
      expr: cbbucketstat_up
      annotations:
        summary: Couchbase Exporter BucketStats collector is down

    - alert: NodeCollectorUp
      expr: cbnode_up
      annotations:
        summary: Couchbase Exporter Node collector is down

    - alert: TaskCollectorUp
      expr: cbtask_up
      annotations:
        summary: Couchbase Exporter Task collector is down

  - name: couchbase-cluster-health
    rules:
    - alert: Couchbase_Failover
      expr: cbnode_failover - avg_over_time(cbnode_failover[1m]) > 0
      annotations:
        summary: Couchbase cluster failover
        description: Couchbase cluster suffers from a failover. Please check cluster state.

    - alert: Couchbase_Bucket_Commit_Failed
      expr: cbbucketstat_ep_item_commit_failed > 0
      annotations:
        summary: Couchbase bucket commit failed
        description: A failure occured when committing data to disk for bucket {{ $labels.bucket }}.

    - alert: Couchbase_Rebalance_Failed
      expr: cbnode_rebalance_failure - avg_over_time(cbnode_rebalance_failure[1m]) > 0
      annotations:
        summary: Couchbase rebalance failure
        description: Rebalancing failed in the Couchbase cluster. Please check cluster state.

    - alert: Couchbase_Node_Cluster_Membership
      expr: cbnode_cluster_membership == 0
      annotations:
        summary: Couchbase node cluster membership
        description: Node {{ $labels.instance }} is out of the cluster.
```

Note that in the metadata referencing the Helm release name of the Prometheus
Operator. Change it if you named the release differently.

Now let's deploy the rules:
```
kubectl -n prometheus apply -f couchbase-alerts.yaml
```

If you go to Prometheus UI and open Alerts, the Couchbase rules should
appear after a while.
