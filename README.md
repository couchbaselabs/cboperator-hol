# Couchbase Operator

Modern business applications are expected to be up 24/7, even during the planned rollout of new features and periodic patching of Operating System or application. Achieving this feat requires tools and technologies that ensure the speed of development, infrastructure stability and ability to scale.

Container orchestration tools like Kubernetes is revolutionizing the way applications are being developed and deployed today by abstracting away the physical machines it manages. With Kubernetes, you can describe the amount of memory, compute power you want, and have it available without worrying about the underlying infrastructure.

Pods (unit of computing resource) and containers (where the applications are run) in Kubernetes environment can self-heal in the event of any type of failure. They are, in essence, ephemeral. This works just fine when you have a stateless microservice but applications that require their state maintained for example database management systems like Couchbase, you need to be able to externalize the storage from the lifecycle management of Pods & Containers so that the data can be recovered quickly by simply remounting the storage volumes to a newly elected Pod.

This is what Persistent Volumes enables in Kubernetes based deployments. Couchbase Autonomous Operator is one of the first adopters of this technology to make recovery from any infrastructure-based failure seamless and most importantly faster.

In these workshops we will take a step-by-step look at how you can deploy Couchbase cluster on different cloud platforms:
* using multiple Couchbase server groups that can be mapped to a separate availability zone (wherever applicable) for high availability
* leverage persistent volumes for fast recovery from infrastructure failure.

![](https://blog.couchbase.com/wp-content/uploads/2019/04/K8-Animation.gif)

Figure 1: Couchbase Autonomous Operator for Kubernetes self-monitors and self-heals Couchbase database platform.


**Repository guides**:

|![Open-Source](assets/on-premise.png)|![EKS](assets/eks.png)|![GKE](assets/gke.png)|![AKS](assets/aks.png)|
| :--- | :--- | :--- | :--- |
| [Open-Source]() | [Amazon EKS](eks) | [Google GKE](gke) | [Azure AKS]() |


## Deployments On-premise
* [Add here your new guide...]()

## Deployments on Cloud

### Amazon EKS

* [Couchbase Operator guide](eks/cb-operator-guide)

### Google GKE

* [Helm deployment](gke/helm-guide)

### Azure AKS

* [Add here your new AKS guide...]()
