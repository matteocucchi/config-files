echo "[task 1] creazione token per addare worker"
kubeadm token create --print-join-command

echo "[task 2] flannel"
kubectl apply -f https://raw.githubusercontent.com/matteocucchi/config-files/main/kube-flannel.yml