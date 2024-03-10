## Bootstrapping an etcd Cluster

### Prerequisites

Run the following commands on each controller instance: `controlplane01` and `controlplane02`. Use SSH to log in to each instance.

### Running Commands in Parallel with tmux

Use [tmux](https://github.com/tmux/tmux/wiki) to run commands on multiple instances simultaneously.

### Download and Install etcd Binaries

Download the etcd release binaries:

```bash
ETCD_VERSION="v3.5.9"
wget -q --show-progress --https-only --timestamping \
  "https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz"
```

Extract and install the binaries:

```bash
{
  tar -xvf etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz
  sudo mv etcd-${ETCD_VERSION}-linux-${ARCH}/etcd* /usr/local/bin/
}
```

### Configure the etcd Server

Set up directories and copy certificates:

```bash
{
  sudo mkdir -p /etc/etcd /var/lib/etcd /var/lib/kubernetes/pki
  sudo cp etcd-server.key etcd-server.crt /etc/etcd/
  sudo cp ca.crt /var/lib/kubernetes/pki/
  sudo chown root:root /etc/etcd/*
  sudo chmod 600 /etc/etcd/*
  sudo chown root:root /var/lib/kubernetes/pki/*
  sudo chmod 600 /var/lib/kubernetes/pki/*
  sudo ln -s /var/lib/kubernetes/pki/ca.crt /etc/etcd/ca.crt
}
```

Retrieve internal IP addresses:

```bash
CONTROL01=$(dig +short controlplane01)
CONTROL02=$(dig +short controlplane02)
```

Set the etcd name:

```bash
ETCD_NAME=$(hostname -s)
```

Create the `etcd.service` systemd unit file:

```bash
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-server.crt \\
  --peer-key-file=/etc/etcd/etcd-server.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${PRIMARY_IP}:2380 \\
  --listen-peer-urls https://${PRIMARY_IP}:2380 \\
  --listen-client-urls https://${PRIMARY_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${PRIMARY_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controlplane01=https://${CONTROL01}:2380,controlplane02=https://${CONTROL02}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Start the etcd Server

Reload systemd and start etcd:

```bash
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}
```

### Verification

List the etcd cluster members:

```bash
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/etcd-server.crt \
  --key=/etc/etcd/etcd-server.key
```

Expected output:

```
45bf9ccad8d8900a, started, controlplane02, https://192.168.56.12:2380, https://192.168.56.12:2379
54a5796a6803f252, started, controlplane01, https://192.168.56.11:2380, https://192.168.56.11:2379
```
