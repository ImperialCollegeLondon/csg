#!/bin/bash
# Adapted from CentOS script - Requires further testing!
set -x
set -e

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check to make sure script is running on Ubuntu
if [ ! -f /etc/os-release ]; then
        echo "This script is for Ubuntu"
        exit
fi

# Swap must be off
swapoff -a
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# RHEL Only replace with Ubuntu firewall conf - UFW? IPTABLES? FIREWALLD?
#wget -P /etc/firewalld/services https://raw.githubusercontent.com/wrightrocket/k8s-firewalld/master/k8s-worker.xml
#systemctl enable firewalld
#systemctl start firewalld
#firewall-cmd --reload
#firewall-cmd --add-service k8s-worker --permanent
#firewall-cmd --reload



# Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"
apt-get update
apt-get install docker-ce
docker run hello-world

# Kubernetes Repo
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt-get install software-properties-common -y


# Install Kubernetes
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
systemctl enable kubelet
systemctl start kubelet

# Network forwarding 
#cat << EOF | sudo tee /etc/sysctl.d/k8s.conf
#net.bridge.bridge-nf-call-ip6tables = 1
#net.bridge.bridge-nf-call-iptables = 1
#EOF
#sysctl --system

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

# Node is ready
echo Join node to cluster with token.
echo "eg. kubeadm join --token <token> vm-k8s-01.doc.ic.ac.uk:6443"
echo on Kubernetes master use kubeadm token list to fetch token
echo If there is no current token create one with kubeadm token create --ttl 3600
read -p 'Token: ' token
# Ignoring CA Hashes verficaton for now #tofix
kubeadm join --token $token vm-k8s-01.doc.ic.ac.uk:6443 --discovery-token-unsafe-skip-ca-verification

#Configure flannel
#yum -y install flannel

# The etcd prefix value in the file /etc/sysconfig/flanneld is not correct, so the flanneld will fail to start as it is not able to retrieve the prefix given. The value of FLANNEL_ETCD_PREFIX must changed to the following:
#sed -i 's|FLANNEL_ETCD_PREFIX="/atomic.io/network"|FLANNEL_ETCD_PREFIX="/coreos.com/network"|g' /etc/sysconfig/flanneld

# Enable and start flanneld
#systemctl enable flanneld --now

# Configure kubectl for user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config