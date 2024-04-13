# Chatur Middleware

This repository contains the middleware for the Chatur project.

## Automatic Installation

There are some Terraform templates in the `deploy` subdirectory that can be used to create a fresh installation.

## Manual Installation

If you'd like to install everything manually, you can follow these steps:

### Prerequisites

#### Kubernetes Cluster

Any Kubernetes cluster will work fine. We've been using [k3s][1] because it's easy to deploy and will automatically
detect and configure support for GPUs. We also have an [Ansible role][2] that can be used to deploy k3s clusters easily.

Note that the Kubernetes cluster should have GPUs installed. The LLM requests will work without a GPU, but the response
times will be much slower.

#### NGINX Ingress Controller

The [NGINX Ingress Controller][3] is used to provide access to the cluster and to manage TLS. You can find instructions
for installing it in their [Getting Started Guide][4] or you can run these commands (assuming you have [helm][5]
installed):

``` shell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx
```

#### cert-manager

We're currently using [cert-manager][6] to manage certificates signed by [Let's Encrypt][7]. The certificate management
itself is defined in the file `k8s/cert-issuer.yaml`. You may have to edit some of the details in this file if you're
deploying this software outside of CyVerse. You can use the [cert-manager installation instructions][8] to get started
or you can follow these instructions:

``` shell
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.3
```

#### APISIX

We're using [Apache APISIX][9] to provide OIDC integration and to easily expose endpoints. You can find installation
instructions in the [APISIX documentation][10] or you can follow these instructions:

``` shell
helm repo add apisix https://charts.apiseven.com
helm repo update
helm install \
    apisix apisix/apisix
    --create-namespace  --namespace apisix \
    --set etcd.replicaCount=1 \
    --set 'apisix.admin.allow.ipList={0.0.0.0/0}'
```

### Deploying

It may be necessary to edit some of the settings in the Kubernetes manifests, so it will be necessary to review all of
the YAML files in the k8s directory to verify that the configuration settings are correct. Some things that you may have
to change are configuration options, host names, and locations of files in the data store. Once all of the prerequisites
are in place, you can deploy the services by running `kubectl apply -f k8s`.

[1]: https://k3s.io/
[2]: https://github.com/CyVerse-Ansible/ansible-k3s
[3]: https://github.com/kubernetes/ingress-nginx
[4]: https://kubernetes.github.io/ingress-nginx/deploy/
[5]: https://helm.sh/
[6]: https://cert-manager.io/
[7]: https://letsencrypt.org/
[8]: https://cert-manager.io/docs/installation/
[9]: https://apisix.apache.org/
[10]: https://apisix.apache.org/docs/apisix/getting-started/README/
