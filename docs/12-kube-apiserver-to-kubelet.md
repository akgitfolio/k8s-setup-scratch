## RBAC for Kubelet Authorization

To configure RBAC permissions for the Kubernetes API Server to access the Kubelet API on each worker node, follow these steps:

1. **Create the ClusterRole**:

   ```bash
   cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     annotations:
       rbac.authorization.kubernetes.io/autoupdate: "true"
     labels:
       kubernetes.io/bootstrapping: rbac-defaults
     name: system:kube-apiserver-to-kubelet
   rules:
     - apiGroups:
         - ""
       resources:
         - nodes/proxy
         - nodes/stats
         - nodes/log
         - nodes/spec
         - nodes/metrics
       verbs:
         - "*"
   EOF
   ```

2. **Bind the ClusterRole to the User**:
   ```bash
   cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
     name: system:kube-apiserver
     namespace: ""
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: system:kube-apiserver-to-kubelet
   subjects:
     - apiGroup: rbac.authorization.k8s.io
       kind: User
       name: kube-apiserver
   EOF
   ```

The Kubernetes API Server uses the `system:kube-apiserver` user, authenticated via the client certificate specified by the `--kubelet-client-certificate` flag, to access the Kubelet API.
