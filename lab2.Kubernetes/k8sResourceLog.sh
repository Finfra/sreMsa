#!/bin/bash
#
#  chmod +x k8sResourceLog.sh
#  sudo cp k8sResourceLog.sh /usr/local/bin
#  k8sResourceLog.sh
#  kubectl create deployment --image=nginx --port=80 nginx
#  k8sResourceLog.sh
#  diff $(ls  /tmp/k8sResourceLog-*|tail -n 2)

echo "
kubectl get pods                 --all-namespaces
kubectl get replicasets          --all-namespaces
kubectl get services             --all-namespaces
kubectl get namespaces           --all-namespaces
kubectl get nodes                --all-namespaces
kubectl get endpoints            --all-namespaces
kubectl get daemonsets           --all-namespaces
kubectl get deployments          --all-namespaces
" > /tmp/do.sh
bash /tmp/do.sh >/tmp/k8sResourceLog-$(date '+%F-%R:%S').log
