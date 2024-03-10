### Provisioning a CA and Generating TLS Certificates

#### Certificate Authority

1. **Set Up Environment Variables:**

   ```bash
   CONTROL01=$(dig +short controlplane01)
   CONTROL02=$(dig +short controlplane02)
   LOADBALANCER=$(dig +short loadbalancer)
   SERVICE_CIDR=10.96.0.0/24
   API_SERVICE=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.1", $1, $2, $3) }')
   ```

2. **Create CA Certificate:**
   ```bash
   openssl genrsa -out ca.key 2048
   openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA/O=Kubernetes" -out ca.csr
   openssl x509 -req -in ca.csr -signkey ca.key -CAcreateserial -out ca.crt -days 1000
   ```

#### Client and Server Certificates

1. **Admin Client Certificate:**

   ```bash
   openssl genrsa -out admin.key 2048
   openssl req -new -key admin.key -subj "/CN=admin/O=system:masters" -out admin.csr
   openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out admin.crt -days 1000
   ```

2. **Kube-Controller-Manager Certificate:**

   ```bash
   openssl genrsa -out kube-controller-manager.key 2048
   openssl req -new -key kube-controller-manager.key -subj "/CN=system:kube-controller-manager/O=system:kube-controller-manager" -out kube-controller-manager.csr
   openssl x509 -req -in kube-controller-manager.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-controller-manager.crt -days 1000
   ```

3. **Kube-Proxy Certificate:**

   ```bash
   openssl genrsa -out kube-proxy.key 2048
   openssl req -new -key kube-proxy.key -subj "/CN=system:kube-proxy/O=system:node-proxier" -out kube-proxy.csr
   openssl x509 -req -in kube-proxy.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-proxy.crt -days 1000
   ```

4. **Kube-Scheduler Certificate:**

   ```bash
   openssl genrsa -out kube-scheduler.key 2048
   openssl req -new -key kube-scheduler.key -subj "/CN=system:kube-scheduler/O=system:kube-scheduler" -out kube-scheduler.csr
   openssl x509 -req -in kube-scheduler.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-scheduler.crt -days 1000
   ```

5. **Kubernetes API Server Certificate:**
   ```bash
   cat > openssl.cnf <<EOF
   [req]
   req_extensions = v3_req
   distinguished_name = req_distinguished_name
   [req_distinguished_name]
   [v3_req]
   basicConstraints = critical, CA:FALSE
   keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
   extendedKeyUsage = serverAuth
   subjectAltName = @alt_names
   [alt_names]
   DNS.1 = kubernetes
   DNS.2 = kubernetes.default
   DNS.3 = kubernetes.default.svc
   DNS.4 = kubernetes.default.svc.cluster
   DNS.5 = kubernetes.default.svc.cluster.local
   IP.1 = ${API_SERVICE}
   IP.2 = ${CONTROL01}
   IP.3 = ${CONTROL02}
   IP.4 = ${LOADBALANCER}
   IP.5 = 127.0.0.1
   EOF
   ```

### Generate Certificates for Kubernetes Components

#### Kube-apiserver Certificate

```bash
openssl genrsa -out kube-apiserver.key 2048

openssl req -new -key kube-apiserver.key \
  -subj "/CN=kube-apiserver/O=Kubernetes" -out kube-apiserver.csr -config openssl.cnf

openssl x509 -req -in kube-apiserver.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-apiserver.crt -extensions v3_req -extfile openssl.cnf -days 1000
```

#### API Server Kubelet Client Certificate

Create configuration file:

```bash
cat > openssl-kubelet.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF
```

Generate the certificate:

```bash
openssl genrsa -out apiserver-kubelet-client.key 2048

openssl req -new -key apiserver-kubelet-client.key \
  -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" -out apiserver-kubelet-client.csr -config openssl-kubelet.cnf

openssl x509 -req -in apiserver-kubelet-client.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial -out apiserver-kubelet-client.crt -extensions v3_req -extfile openssl-kubelet.cnf -days 1000
```

#### ETCD Server Certificate

Create configuration file:

```bash
cat > openssl-etcd.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = ${CONTROL01}
IP.2 = ${CONTROL02}
IP.3 = 127.0.0.1
EOF
```

Generate the certificate:

```bash
openssl genrsa -out etcd-server.key 2048

openssl req -new -key etcd-server.key \
  -subj "/CN=etcd-server/O=Kubernetes" -out etcd-server.csr -config openssl-etcd.cnf

openssl x509 -req -in etcd-server.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd-server.crt -extensions v3_req -extfile openssl-etcd.cnf -days 1000
```

#### Service Account Key Pair

Generate the certificate and key:

```bash
openssl genrsa -out service-account.key 2048

openssl req -new -key service-account.key \
  -subj "/CN=service-accounts/O=Kubernetes" -out service-account.csr

openssl x509 -req -in service-account.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial -out service-account.crt -days 1000
```

#### Verify the PKI

Run the verification script:

```bash
./cert_verify.sh
```

Expected output:

```
PKI generated correctly!
```

#### Distribute the Certificates

Copy certificates and keys to control plane instances:

```bash
for instance in controlplane01 controlplane02; do
  scp -o StrictHostKeyChecking=no ca.crt ca.key kube-apiserver.key kube-apiserver.crt \
    apiserver-kubelet-client.crt apiserver-kubelet-client.key \
    service-account.key service-account.crt \
    etcd-server.key etcd-server.crt \
    kube-controller-manager.key kube-controller-manager.crt \
    kube-scheduler.key kube-scheduler.crt \
    ${instance}:~/
done

for instance in node01 node02; do
  scp ca.crt kube-proxy.crt kube-proxy.key ${instance}:~/
done
```

#### Optional - Check Certificates on controlplane02

Run the verification script on `controlplane02`:

```bash
ssh controlplane02 './cert_verify.sh'
```
