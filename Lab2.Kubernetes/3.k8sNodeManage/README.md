# Node 추가
## Terraform 작업
1. Terraform 파일 수정 (실습용 Console서버)
```
cd ~/sreMsa/Lab1.Kubespray/Lab3.InstanceForKubernetes/
vi vars.tf # "instance_count"를 4로 변경
terraform apply --auto-approve

```
2. Hosts파일 셋팅
```
bash doSetHosts.sh
```

## Kubespray 셋팅
1. inventory파일 수정
```
cd ~/kubespray
cat > inventory/inventory.ini << EOF
[all]
vm01 etcd_member_name=etcd1
vm02 etcd_member_name=etcd2
vm03 etcd_member_name=etcd3
vm04 etcd_member_name=etcd4

[kube-master]
vm01
vm02

[etcd]
vm01
vm02
vm03

[kube-node]
vm01
vm02
vm03
vm04

[k8s-cluster:children]
kube-master
kube-node

EOF
```


2. Kubespray 다시 실행
```
ansible-playbook --flush-cache -u ubuntu -b --become --become-user=root \
  -i inventory/inventory.ini \
  cluster.yml
```

3. instance 추가확인 [vm01 instance]
```
kubectl get nodes
```


# Node 제거
## Terraform 작업
1. Terraform 파일 수정(실습용 Console서버)
```
cd sreMsa/Lab1.Kubespray/Lab3.InstanceForKubernetes/
vi vars.tf # "instance_count"를 3으로 변경
terraform apply -auto-approve

```
2. Hosts파일 셋팅
```
sudo vi /etc/hosts   # vm04제거 (필수아님)
```

## Kubespray 셋팅
1. inventory파일 수정
```
cd ~/kubespray
cat > inventory/inventory.ini << EOF
[all]
vm01 etcd_member_name=etcd1
vm02 etcd_member_name=etcd2
vm03 etcd_member_name=etcd3

[kube-master]
vm01
vm02

[etcd]
vm01
vm02
vm03

[kube-node]
vm01
vm02
vm03

[k8s-cluster:children]
kube-master
kube-node

EOF
```


2. Kubespray 다시 실행
```
ansible-playbook --flush-cache -u ubuntu -b --become --become-user=root \
  -i inventory/inventory.ini \
  cluster.yml
```

3. instance 확인
```
kubectl get nodes
```

4. Kubernetes단에서 노드 제거
```
kubectl delete node vm04
```

5. instance 제거 확인
```
kubectl get nodes
```
