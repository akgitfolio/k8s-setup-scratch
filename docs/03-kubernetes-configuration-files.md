## Generating Kubernetes Configuration Files for Authentication

Create Kubernetes configuration files (kubeconfigs) to enable clients to locate and authenticate to the Kubernetes API Servers.

### Client Authentication Configs

You will generate kubeconfig files for the `controller manager`, `kube-proxy`, `scheduler` clients, and the `admin` user.

### Kubernetes Public IP Address

First, get the load balancer's IP address:

```bash
LOADBALANCER=$(dig +short loadbalancer)
```

### kube-proxy Configuration File

Generate a kubeconfig file for the `kube-proxy` service:

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://${LOADBALANCER}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=/var/lib/kubernetes/pki/kube-proxy.crt \
    --client-key=/var/lib/kubernetes/pki/kube-proxy.key \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}
```

### kube-controller-manager Configuration File

Generate a kubeconfig file for the `kube-controller-manager` service:

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=/var/lib/kubernetes/pki/kube-controller-manager.crt \
    --client-key=/var/lib/kubernetes/pki/kube-controller-manager.key \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}
```

### kube-scheduler Configuration File

Generate a kubeconfig file for the `kube-scheduler` service:

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=/var/lib/kubernetes/pki/kube-scheduler.crt \
    --client-key=/var/lib/kubernetes/pki/kube-scheduler.key \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}
```

### admin Configuration File

Generate a kubeconfig file for the `admin` user:

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
}
```

### Distribute the Configuration Files

Copy the `kube-proxy` kubeconfig files to each worker instance:

```bash
for instance in node01 node02; do
  scp kube-proxy.kubeconfig ${instance}:~/
done
```

Copy the `admin.kubeconfig`, `kube-controller-manager`, and `kube-scheduler` kubeconfig files to each controller instance:

```bash
for instance in controlplane01 controlplane02; do
  scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done
```

### Optional - Verify kubeconfigs

On `controlplane01` and `controlplane02` nodes, run:

```bash
./cert_verify.sh
```
