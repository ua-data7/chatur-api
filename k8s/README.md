# k8s manifests
This directory contains a list of k8s manifests for installing chatur.

Also note that you need to create a Secret named `apisix-config-secrets` in `apisix` namespace before applying `apisix-config.yaml`. There is a commented out example at the top of `apisix-config.yaml`.

# helm charts
In additional to the k8s manifests in this directory, you will also need to install some helm charts before you apply those manifests.

### ingress-nginx
```shell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx
```

### cert-manager
```shell
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.3
```

### apisix
> change the replicaCount of etcd if necessary (chart default is `3`), this needs to be less than or equal to the number of nodes in the cluster.
```shell
helm repo add apisix https://charts.apiseven.com
helm repo update
helm install apisix apisix/apisix --create-namespace  --namespace apisix  --set etcd.replicaCount=1 --set 'apisix.admin.allow.ipList={0.0.0.0/0}'
```
