### Bootstrapping the Kubernetes Control Plane

#### Prerequisites

- Run commands on each controller instance (`controlplane01` and `controlplane02`) using SSH.

#### Provision the Kubernetes Control Plane

1. **Download and Install Kubernetes Binaries:**

   ```bash
   KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
   wget -q --show-progress --https-only --timestamping \
     "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-apiserver" \
     "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-controller-manager" \
     "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-scheduler" \
     "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kubectl"
   chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
   sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
   ```

2. **Configure the Kubernetes API Server:**

   - Place key pairs in the Kubernetes data directory:
     ```bash
     sudo mkdir -p /var/lib/kubernetes/pki
     sudo cp ca.crt ca.key /var/lib/kubernetes/pki
     for c in kube-apiserver service-account apiserver-kubelet-client etcd-server kube-scheduler kube-controller-manager
     do
       sudo mv "$c.crt" "$c.key" /var/lib/kubernetes/pki/
     done
     sudo chown root:root /var/lib/kubernetes/pki/*
     sudo chmod 600 /var/lib/kubernetes/pki/*
     ```
   - Retrieve internal IP addresses:
     ```bash
     LOADBALANCER=$(dig +short loadbalancer)
     CONTROL01=$(dig +short controlplane01)
     CONTROL02=$(dig +short controlplane02)
     ```
   - Create `kube-apiserver.service` systemd unit file:

     ```bash
     cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
     [Unit]
     Description=Kubernetes API Server
     Documentation=https://github.com/kubernetes/kubernetes

     [Service]
     ExecStart=/usr/local/bin/kube-apiserver \\
       --advertise-address=${PRIMARY_IP} \\
       --allow-privileged=true \\
       --apiserver-count=2 \\
       --audit-log-maxage=30 \\
       --audit-log-maxbackup=3 \\
       --audit-log-maxsize=100 \\
       --audit-log-path=/var/log/audit.log \\
       --authorization-mode=Node,RBAC \\
       --bind-address=0.0.0.0 \\
       --client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
       --enable-admission-plugins=NodeRestriction,ServiceAccount \\
       --enable-bootstrap-token-auth=true \\
       --etcd-cafile=/var/lib/kubernetes/pki/ca.crt \\
       --etcd-certfile=/var/lib/kubernetes/pki/etcd-server.crt \\
       --etcd-keyfile=/var/lib/kubernetes/pki/etcd-server.key \\
       --etcd-servers=https://${CONTROL01}:2379,https://${CONTROL02}:2379 \\
       --event-ttl=1h \\
       --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
       --kubelet-certificate-authority=/var/lib/kubernetes/pki/ca.crt \\
       --kubelet-client-certificate=/var/lib/kubernetes/pki/apiserver-kubelet-client.crt \\
       --kubelet-client-key=/var/lib/kubernetes/pki/apiserver-kubelet-client.key \\
       --runtime-config=api/all=true \\
       --service-account-key-file=/var/lib/kubernetes/pki/service-account.crt \\
       --service-account-signing-key-file=/var/lib/kubernetes/pki/service-account.key \\
       --service-account-issuer=https://${LOADBALANCER}:6443 \\
       --service-cluster-ip-range=${SERVICE_CIDR} \\
       --service-node-port-range=30000-32767 \\
       --tls-cert-file=/var/lib/kubernetes/pki/kube-apiserver.crt \\
       --tls-private-key-file=/var/lib/kubernetes/pki/kube-apiserver.key \\
       --v=2
     Restart=on-failure
     RestartSec=5

     [Install]
     WantedBy=multi-user.target
     EOF
     ```

3. **Configure the Kubernetes Controller Manager:**

   - Move the `kube-controller-manager` kubeconfig:
     ```bash
     sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
     ```
   - Create `kube-controller-manager.service` systemd unit file:

     ```bash
     cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
     [Unit]
     Description=Kubernetes Controller Manager
     Documentation=https://github.com/kubernetes/kubernetes

     [Service]
     ExecStart=/usr/local/bin/kube-controller-manager \\
       --allocate-node-cidrs=true \\
       --authentication-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
       --authorization-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
       --bind-address=127.0.0.1 \\
       --client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
       --cluster-cidr=${POD_CIDR} \\
       --cluster-name=kubernetes \\
       --cluster-signing-cert-file=/var/lib/kubernetes/pki/ca.crt \\
       --cluster-signing-key-file=/var/lib/kubernetes/pki/ca.key \\
       --controllers=*,bootstrapsigner,tokencleaner \\
       --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
       --leader-elect=true \\
       --node-cidr-mask-size=24 \\
       --requestheader-client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
       --root-ca-file=/var/lib/kubernetes/pki/ca.crt \\
       --service-account-private-key-file=/var/lib/kubernetes/pki/service-account.key \\
       --service-cluster-ip-range=${SERVICE_CIDR} \\
       --use-service-account-credentials=true \\
       --v=2
     Restart=on-failure
     RestartSec=5

     [Install]
     WantedBy=multi-user.target
     EOF
     ```

4. **Configure the Kubernetes Scheduler:**

   - Move the `kube-scheduler` kubeconfig:
     ```bash
     sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
     ```
   - Create `kube-scheduler.service` systemd unit file:

     ```bash
     cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
     [Unit]
     Description=Kubernetes Scheduler
     Documentation=https://github.com/kubernetes/kubernetes

     [Service]
     ExecStart=/usr/local/bin/kube-scheduler \\
       --kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig \\
       --leader-elect=true \\
       --v=2
     Restart=on-failure
     RestartSec=5

     [Install]
     WantedBy=multi-user.target
     EOF
     ```

5. **Secure kubeconfigs:**

   ```bash
   sudo chmod 600 /var/lib/kubernetes/*.kubeconfig
   ```

6. **Start the Controller Services:**

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
   sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
   ```

7. **Verification:**
   - Run on `controlplane01`:
     ```bash
     kubectl get componentstatuses --kubeconfig admin.kubeconfig
     ```

### Provision the Kubernetes Frontend Load Balancer

1. **Install HAProxy:**

   ```bash
   sudo apt-get update && sudo apt-get install -y haproxy
   ```

2. **Configure HAProxy:**

   - Retrieve IP addresses:
     ```bash
     CONTROL01=$(dig +short controlplane01)
     CONTROL02=$(dig +short controlplane02)
     LOADBALANCER=$(dig +short loadbalancer)
     ```
   - Create HAProxy configuration:

     ```bash
     cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
     frontend kubernetes
         bind ${LOADBALANCER}:6443
         option tcplog
         mode tcp
         default_backend kubernetes-controlplane-nodes

     backend kubernetes-controlplane-nodes
         mode tcp
         balance roundrobin
         option tcp-check
         server controlplane01 ${CONTROL01}:6443 check fall 3 rise 2
         server controlplane02 ${CONTROL02}:6443 check fall 3 rise 2
     EOF
     sudo systemctl restart haproxy
     ```

3. **Verification:**
   - Check Kubernetes version:
     ```bash
     curl -k https://${LOADBALANCER}:6443/version
     ```

This summary retains the essential steps and commands required to bootstrap the Kubernetes control plane and configure the load balancer, ensuring high availability and proper setup.
