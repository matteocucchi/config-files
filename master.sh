echo "[task 1] modifica file host"
echo 172.16.16.100 kmaster kmaster.example.com | sudo tee -a /etc/hosts
echo 172.16.16.101 kworker1 kworker1.example.com | sudo tee -a /etc/hosts

echo "[task 2] disabilitare selinux"
sudo setenforce 0
sudo sed -i 's/SELINUX=permissive\|SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

echo "[task 3] disabilitare firewalld"
sudo systemctl disable firewalld --now
sudo systemctl stop firewalld

echo "[task 4] disabilitare swap"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "[task 5] networking kubernetes"
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
EOF
sudo sysctl --system

echo "[task 6] Docker installation"
sudo yum check-update -y
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce -y
sudo mkdir -p /etc/docker
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
sudo systemctl start docker
sudo systemctl enable docker --now

echo "[task 7] kubernetes installation"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo yum install -y kubectl kubeadm kubelet
sudo systemctl enable --now kubelet

echo "[task 8] delete config file containerd"
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd

echo "[task 9] kubeadm init master"
sudo kubeadm init --apiserver-advertise-address=172.16.16.100 --pod-network-cidr=10.244.0.0/16

echo "[task 10] enable kubectl for user"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[task 11] flannel"
sudo yum install wget -y
wget https://raw.githubusercontent.com/matteocucchi/config-files/main/kube-flannel.yml
kubectl apply -f kube-flannel.yml