#!/usr/bin/env bash

# Update /etc/hosts with entries from /tmp/hostentries
sudo sed -i "/$(hostname)/d" /etc/hosts
cat /tmp/hostentries | sudo tee -a /etc/hosts > /dev/null

# Set environment variables for primary IP and architecture
echo "PRIMARY_IP=$(ip route | grep default | awk '{ print $9 }')" | sudo tee -a /etc/environment > /dev/null
echo "ARCH=arm64" | sudo tee -a /etc/environment > /dev/null

# Enable password authentication in SSH
sudo sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/#\?Include \/etc\/ssh\/sshd_config.d\/\*.conf/#Include \/etc\/ssh\/sshd_config.d\/\*.conf/' /etc/ssh/sshd_config
sudo sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Install sshpass on controlplane01
if [ "$(hostname)" = "controlplane01" ]; then
    sudo apt update > /dev/null
    sudo apt-get install -y sshpass > /dev/null
fi

# Set password for ubuntu user
echo 'ubuntu:ubuntu' | sudo chpasswd