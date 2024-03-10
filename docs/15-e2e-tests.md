## Run End-to-End Tests

### System Requirements

- **RAM**: Minimum 16GB (less may cause failures)
- **Processor**: Server-grade recommended (e.g., Intel Core i7-7800X Desktop Processor). Laptop processors may cause instability.

### Installation Steps

#### Install Latest Go

```bash
GO_VERSION=$(curl -s 'https://go.dev/VERSION?m=text' | head -1)
wget "https://dl.google.com/go/${GO_VERSION}.linux-${ARCH}.tar.gz"
sudo tar -C /usr/local -xzf ${GO_VERSION}.linux-${ARCH}.tar.gz
sudo ln -s /usr/local/go/bin/go /usr/local/bin/go
sudo ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt
source <(go env)
export PATH=$PATH:$GOPATH/bin
```

#### Install kubetest2 and Google Cloud CLI

```bash
go install sigs.k8s.io/kubetest2/...@latest
sudo snap install google-cloud-cli --classic
```

### Run Tests

```bash
KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
NUM_CPU=$(cat /proc/cpuinfo | grep '^processor' | wc -l)

cd ~
kubetest2 noop --kubeconfig ${PWD}/.kube/config --test=ginkgo -- \
  --focus-regex='\[Conformance\]' --test-package-version $KUBE_VERSION --parallel $NUM_CPU
```

### Monitor Cluster Activity

```bash
watch kubectl get all -A
```
