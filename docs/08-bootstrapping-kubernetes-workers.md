## Bootstrapping Kubernetes Worker Nodes

### Prerequisites

- Certificates and configuration created on `controlplane01` and copied to worker nodes using `scp`.
- SSH into `node01`.

### Provisioning Kubelet Client Certificates

Generate a certificate and private key for `node01` on `controlplane01`:

```bash
NODE01=$(dig +short node01)
cat > openssl-node01.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = node01
IP.1 = ${NODE01}
EOF

openssl genrsa -out node01.key 2048
openssl req -new -key node01.key -subj "/CN=system:node:node01/O=system:nodes" -out node01.csr -config openssl-node01.cnf
openssl x509 -req -in node01.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out node01.crt -extensions v3_req -extfile openssl-node01.cnf -days 1000
```

### Kubelet Kubernetes Configuration File

Generate a kubeconfig file for `node01` on `controlplane01`:

```bash
LOADBALANCER=$(dig +short loadbalancer)
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://${LOADBALANCER}:6443 \
    --kubeconfig=node01.kubeconfig

  kubectl config set-credentials system:node:node01 \
    --client-certificate=/var/lib/kubernetes/pki/node01.crt \
    --client-key=/var/lib/kubernetes/pki/node01.key \
    --kubeconfig=node01.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:node01 \
    --kubeconfig=node01.kubeconfig

  kubectl config use-context default --kubeconfig=node01.kubeconfig
}
```

### Copy Files to Worker Node

On `controlplane01`:

```bash
scp ca.crt node01.crt node01.key node01.kubeconfig node01:~/
```

### Download and Install Worker Binaries

On `node01`:

```bash
KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
wget -q --show-progress --https-only --timestamping \
  https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-proxy \
  https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kubelet

sudo mkdir -p /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes/pki /var/run/kubernetes
chmod +x kube-proxy kubelet
sudo mv kube-proxy kubelet /usr/local/bin/
```

### Configure the Kubelet

On `node01`:

```bash
sudo mv ${HOSTNAME}.key ${HOSTNAME}.crt /var/lib/kubernetes/pki/
sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubelet.kubeconfig
sudo mv ca.crt /var/lib/kubernetes/pki/
sudo mv kube-proxy.crt kube-proxy.key /var/lib/kubernetes/pki/
sudo chown root:root /var/lib/kubernetes/pki/*
sudo chmod 600 /var/lib/kubernetes/pki/*
sudo chown root:root /var/lib/kubelet/*
sudo chmod 600 /var/lib/kubelet/*
```

Set CIDR ranges:

```bash
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/16
CLUSTER_DNS=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.10", $1, $2, $3) }')
```

Create `kubelet-config.yaml`:

```bash
cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: /var/lib/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
clusterDomain: cluster.local
clusterDNS:
  - ${CLUSTER_DNS}
cgroupDriver: systemd
resolvConf: /run/systemd/resolve/resolv.conf
runtimeRequestTimeout: "15m"
tlsCertFile: /var/lib/kubernetes/pki/${HOSTNAME}.crt
tlsPrivateKeyFile: /var/lib/kubernetes/pki/${HOSTNAME}.key
registerNode: true
EOF
```

Create `kubelet.service`:

```bash
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --kubeconfig=/var/lib/kubelet/kubelet.kubeconfig \\
  --node-ip=${PRIMARY_IP} \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubernetes Proxy

On `node01`:

```bash
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/
```

Create `kube-proxy-config.yaml`:

```bash
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: /var/lib/kube-proxy/kube-proxy.kubeconfig
mode: iptables
clusterCIDR: ${POD_CIDR}
EOF
```

Create `kube-proxy.service`:

```bash
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Start the Worker Services

On `node01`:

```bash
sudo systemctl daemon-reload
sudo systemctl enable kubelet kube-proxy
sudo systemctl start kubelet kube-proxy
```

### Verification

On `controlplane01`:

```bash
kubectl get nodes --kubeconfig admin.kubeconfig
```

Output:

```
NAME       STATUS     ROLES    AGE   VERSION
node01     NotReady   <none>   93s   v1.28.4
```

The node is not ready as pod networking is not yet installed.
