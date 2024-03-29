﻿# config-files
1) modificare file hosts (/etc/hosts)

echo 172.16.16.100 kmaster kmaster.example.com >> /etc/hosts
echo 172.16.16.101 kworker1 kworker1.example.com >> /etc/hosts

2) disabilitare selinux

setenforce 0
sed -i 's/SELINUX=permissive\|SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
reboot


3) disabilitare firewalld

sudo systemctl disable firewalld
sudo systemctl stop firewalld

4) disabilitare swap

sudo swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

5) creazione file per networking di kubernetes

touch /etc/sysctl.d/kubernetes.conf
echo net.bridge.bridge-nf-call-ip6tables=1 >> /etc/sysctl.d/kubernetes.conf
echo net.bridge.bridge-nf-call-iptables=1 >> /etc/sysctl.d/kubernetes.conf
sysctl --system

6) aggiunta repo ed installazione docker

sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce

6.1) set docker daemon to use systemd per il management dei container

mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

6.2) enable docker service

sudo systemctl start docker
sudo systemctl enable docker --now

7) aggiunta repo kubernetes

touch /etc/yum.repos.d/kubernetes.repo
echo [kubernetes] >> /etc/yum.repos.d/kubernetes.repo
echo name=kubernetes >> /etc/yum.repos.d/kubernetes.repo
echo baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64 >> /etc/yum.repos.d/kubernetes.repo
echo enabled=1 >> /etc/yum.repos.d/kubernetes.repo
echo gpgcheck=1 >> /etc/yum.repos.d/kubernetes.repo
echo repo gpgcheck=1 >> /etc/yum.repos.d/kubernetes.repo
echo gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg >> /etc/yum.repos.d/kubernetes.repo

8) installazione kubernetes ed attivazione servizio kubelet

sudo yum install -y kubectl kubeadm kubelet
sudo systemctl enable --now kubelet

9) eliminare file di configurazione di containerd

rm /etc/containerd/config.toml
systemctl restart containerd

10) eseguire sul master kubeadm init

sudo kubeadm init --apiserver-advertise-address=172.16.16.100 --pod-network-cidr=192.168.0.0/16

11) eseguire comandi per abilitare utente ad usare kubectl

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

12) flannel
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
vi kube-flannel.yml
/flannel
/args
aggiungere - --iface=eth1
eseguire kubectl apply

13) aggiungere nodo worker al cluster

lanciare comando sotto nel master per ottenere il comando che aggiunge un nodo da eseguire nel worker
kubeadm token create --print-join-command
