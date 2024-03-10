### Provisioning Pod Network

Container Network Interface (CNI) is a standard for managing IP networks between containers across nodes. We use CNI - [Weave](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/) for networking.

### Deploy Weave Network

Despite WeaveWorks no longer trading, Weave remains a valid CNI as it is open source and compatible with Kubernetes. We continue to use it due to its simpler configuration compared to alternatives like Calico or Cilium.

Deploy the Weave network on the `controlplane01` node:

```bash
kubectl apply -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml"
```

Wait up to 60 seconds for the Weave pods to be ready.

### Verification

Check the status of the Weave pods:

```bash
kubectl rollout status daemonset weave-net -n kube-system --timeout=90s
kubectl get pods -n kube-system
```

Expected output:

```
NAME              READY   STATUS    RESTARTS   AGE
weave-net-58j2j   2/2     Running   0          89s
weave-net-rr5dk   2/2     Running   0          89s
```

Verify the nodes are ready:

```bash
kubectl get nodes
```

Expected output:

```
NAME       STATUS   ROLES    AGE     VERSION
node01     Ready    <none>   4m11s   v1.28.4
node02     Ready    <none>   2m49s   v1.28.4
```
