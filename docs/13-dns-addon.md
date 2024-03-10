### Deploying the DNS Cluster Add-on

To deploy the DNS add-on for service discovery in a Kubernetes cluster, follow these steps:

1. **Deploy CoreDNS:**

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/procwrangler/kubernetes-the-hard-way/master/deployments/coredns.yaml
   ```

   **Expected Output:**

   ```
   serviceaccount/coredns created
   clusterrole.rbac.authorization.k8s.io/system:coredns created
   clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
   configmap/coredns created
   deployment.extensions/coredns created
   service/kube-dns created
   ```

2. **Verify CoreDNS Pods:**

   ```bash
   kubectl get pods -l k8s-app=kube-dns -n kube-system
   ```

   **Expected Output:**

   ```
   NAME                       READY   STATUS    RESTARTS   AGE
   coredns-699f8ddd77-94qv9   1/1     Running   0          20s
   coredns-699f8ddd77-gtcgb   1/1     Running   0          20s
   ```

3. **Create a Busybox Pod:**

   ```bash
   kubectl run busybox -n default --image=busybox:1.28 --restart Never --command -- sleep 180
   ```

4. **Verify Busybox Pod:**

   ```bash
   kubectl get pods -n default -l run=busybox
   ```

   **Expected Output:**

   ```
   NAME                      READY   STATUS    RESTARTS   AGE
   busybox-bd8fb7cbd-vflm9   1/1     Running   0          10s
   ```

5. **Execute DNS Lookup:**

   ```bash
   kubectl exec -ti -n default busybox -- nslookup kubernetes
   ```

   **Expected Output:**

   ```
   Server:    10.96.0.10
   Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

   Name:      kubernetes
   Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
   ```
