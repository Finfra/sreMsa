## k8s Single Node install on ubuntu24.04
1. Ansible 설치
```
sudo -i 
ANSIBE_VERSION="9.5.1"           # core 2.16.6
apt install -y python3-full
apt install -y python3-pip
pip3 install --break-system-packages netaddr jinja2
pip3 install --break-system-packages ansible==$ANSIBE_VERSION
echo "127.0.0.1 vm01" >> /etc/hosts
```

2. Requirement 수정
```
cat >requirements.txt<<EOF
ansible==9.5.1
cryptography
jinja2==3.1.4
jmespath==1.0.1
MarkupSafe==2.1.5
netaddr==1.2.1
pbr==6.0.0
ruamel.yaml==0.18.6
ruamel.yaml.clib==0.2.8
jsonschema
EOF
pip3 install --break-system-packages -r requirements.txt
```

3. key 생성 및 Local 접소 가능하게 하기
```
exit
ssh-keygen -f ~/.ssh/id_rsa -N ''
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

3. Kubespary Downloads
```
cd
git clone https://github.com/kubernetes-sigs/kubespray
cd ~/kubespray
```

5. inventory 
```
cat > inventory/inventory.ini <<EOF
[all]
vm01 etcd_member_name=etcd1
[kube-master]
vm01

[etcd]
vm01

[kube-node]
vm01

[k8s-cluster:children]
kube-master
kube-node
EOF
```

6. playbook 실행
```
ansible-playbook --flush-cache -u $(whoami) -b --become --become-user=root \
      -i inventory/inventory.ini \
      cluster.yml
```

7. test
```
kubectl get no
```
