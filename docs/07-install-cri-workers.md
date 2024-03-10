### Installing Container Runtime on Kubernetes Worker Nodes

Installing Container Runtime Interface (CRI) on both worker nodes. Since Kubernetes v1.24, dockershim has been deprecated and removed, with `containerd` replacing Docker as the container runtime. This setup also requires CNI plugins for network configuration and `runc` for running containers.

#### Steps to Install Container Runtime and CNI Tools

1. **Update Package Index and Install Required Packages:**

   ```bash
   sudo apt-get update
   sudo apt-get install -y apt-transport-https ca-certificates curl
   ```

2. **Set Up Required Kernel Modules:**

   ```bash
   cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
   overlay
   br_netfilter
   EOF

   sudo modprobe overlay
   sudo modprobe br_netfilter
   ```

3. **Configure Kernel Parameters:**

   ```bash
   cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
   net.bridge.bridge-nf-call-iptables  = 1
   net.bridge.bridge-nf-call-ip6tables = 1
   net.ipv4.ip_forward                 = 1
   EOF

   sudo sysctl --system
   ```

4. **Determine Latest Kubernetes Version:**

   ```bash
   KUBE_LATEST=$(curl -L -s https://dl.k8s.io/release/stable.txt | awk 'BEGIN { FS="." } { printf "%s.%s", $1, $2 }')
   ```

5. **Download Kubernetes Public Signing Key:**

   ```bash
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
   ```

6. **Add Kubernetes APT Repository:**

   ```bash
   echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
   ```

7. **Install Container Runtime and CNI Components:**

   ```bash
   sudo apt update
   sudo apt-get install -y containerd kubernetes-cni kubectl ipvsadm ipset
   ```

8. **Configure Containerd to Use Systemd Cgroups:**

   1. Create default configuration:

      ```bash
      sudo mkdir -p /etc/containerd
      containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml
      ```

   2. Restart containerd:
      ```bash
      sudo systemctl restart containerd
      ```
