## Installing the Client Tools

### Access All VMs

1. **Log into `controlplane01`:**

   - For VirtualBox: `vagrant ssh`
   - For Apple Silicon: `multipass shell`

2. **Generate SSH Key Pair:**

   - Run on `controlplane01`:
     ```bash
     ssh-keygen
     ```
   - Press `ENTER` to accept defaults.

3. **Add Key to `authorized_keys`:**

   ```bash
   cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
   ```

4. **Copy Key to Other Hosts:**

   - Use the following commands, entering the password when prompted:
     - VirtualBox password: `vagrant`
     - Apple Silicon password: `ubuntu`

   ```bash
   ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@controlplane02
   ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@loadbalancer
   ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@node01
   ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@node02
   ```

5. **Verify SSH Connections:**

   ```bash
   ssh controlplane01
   exit

   ssh controlplane02
   exit

   ssh node01
   exit

   ssh node02
   exit
   ```

### Install `kubectl`

1. **Download and Install `kubectl`:**

   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   ```

2. **Verify Installation:**
   ```bash
   kubectl version --client
   ```
   - Expected output:
     ```
     Client Version: v1.29.0
     Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
     ```
