## Generating the Data Encryption Config and Key

Kubernetes allows encryption of cluster data at rest, including secrets stored in `etcd`.

### Encryption Key

Generate a 32-byte encryption key and encode it in base64:

```bash
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

### Encryption Config File

Create the `encryption-config.yaml` file:

```bash
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
```

Copy the `encryption-config.yaml` file to each controller instance:

```bash
for instance in controlplane01 controlplane02; do
  scp encryption-config.yaml ${instance}:~/
done
```

Move the `encryption-config.yaml` file to the appropriate directory:

```bash
for instance in controlplane01 controlplane02; do
  ssh ${instance} sudo mkdir -p /var/lib/kubernetes/
  ssh ${instance} sudo mv encryption-config.yaml /var/lib/kubernetes/
done
```
