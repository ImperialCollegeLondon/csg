#!/bin/bash
set -x
set -e

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check to make sure script is running on CentOS/Redhat
if [ ! -f /etc/redhat-release ]; then
        echo "This script is for CentOS"
        exit
fi

# Swap must be off
swapoff -a
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configure FirewallD
wget -P /etc/firewalld/services https://raw.githubusercontent.com/wrightrocket/k8s-firewalld/master/k8s-worker.xml
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --reload
firewall-cmd --add-service k8s-worker --permanent
firewall-cmd --reload

# Kubernetes Repo
cat << EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# disable SELinux
setenforce 0
sed -i 's/enforcing/permissive/g' /etc/selinux/config /etc/selinux/config

# Install Kubernetes
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet
systemctl start kubelet

# Network forwarding 
cat << EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Run on master node only!
#kubeadm init --pod-network-cidr=10.244.0.0/16
#mkdir -p $HOME/.kube
#cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#chown $(id -u):$(id -g) $HOME/.kube/config

# Verify node is ready
#kubectl get nodes
#read -p "Press [Enter] to confirm"

# Verify kube-system pods are ready
#kubectl get pods --all-namespaces
#read -p "Press [Enter] to confirm"

# Install Flannel networking
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml

# Retrieve setup token
#kubeadm token list

# Master is ready
echo Join node to cluster with token.
echo kubeadm join --token <token> vm-k8s-01.doc.ic.ac.uk6443
echo on Kubernetes master use kubeadm token list to fetch token
echo If there is no current token create one with kubeadm token create --ttl 3600