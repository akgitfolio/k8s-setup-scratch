## Configuring kubectl for Remote Access

### Generate kubeconfig for `admin` User

Run the following commands from the directory where the admin client certificates were generated.

1. **Get Load Balancer IP:**

   ```bash
   LOADBALANCER=$(dig +short loadbalancer)
   ```

2. **Create kubeconfig File:**

   ```bash
   kubectl config set-cluster kubernetes-the-hard-way \
     --certificate-authority=ca.crt \
     --embed-certs=true \
     --server=https://${LOADBALANCER}:6443

   kubectl config set-credentials admin \
     --client-certificate=admin.crt \
     --client-key=admin.key

   kubectl config set-context kubernetes-the-hard-way \
     --cluster=kubernetes-the-hard-way \
     --user=admin

   kubectl config use-context kubernetes-the-hard-way
   ```

### Verification

1. **Check Cluster Health:**

   ```bash
   kubectl get componentstatuses
   ```

   Expected output:

   ```
   NAME                 STATUS    MESSAGE             ERROR
   controller-manager   Healthy   ok
   scheduler            Healthy   ok
   etcd-1               Healthy   {"health":"true"}
   etcd-0               Healthy   {"health":"true"}
   ```

2. **List Cluster Nodes:**

   ```bash
   kubectl get nodes
   ```

   Expected output:

   ```
   NAME       STATUS      ROLES    AGE    VERSION
   node01     NotReady    <none>   118s   v1.28.4
   node02     NotReady    <none>   118s   v1.28.4
   ```
