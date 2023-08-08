# Kubernetes Install With Kubespray
0. 변수 셋팅 파일 생성 후 실행
* 아래와 같은 내용을 ~/.bashrc에 추가하고 실행해 줍니다.
```
su - ubuntu
echo '
export TF_VAR_AWS_ACCESS_KEY="xxxxxxx"
export TF_VAR_AWS_SECRET_KEY="xxxxxxxxxxxxxxx"
export TF_VAR_AWS_REGION="ap-northeast-2"
'>> ~/.bashrc
. ~/.bashrc
```

1. OS key 생성 [있으면 생략]
```
ssh-keygen -f ~/.ssh/id_rsa -N ''
```
* cf) 설치 대상 host에 Public-key 배포
    ssh-copy-id root@10.0.2.10

2. Terrform 으로 host 셋팅
```
cd
git clone https://github.com/Finfra/sreMsa
cd ~/sreMsa/Lab1.Kubespray/Lab3.InstanceForKubernetes
terraform init
terraform apply --auto-approve
```


3. Hosts파일 셋팅
```
aws configure
  # security setting
    AWS Access Key ID [None]: xxxxxxxxxx
    AWS Secret Access Key [None]: xxxxxxxxxxxxxxxxxxx
    Default region name [None]: ap-northeast-2
    Default output format [None]: text
cd ~/sreMsa/Lab1.Kubespray/Lab3.InstanceForKubernetes
bash doSetHosts.sh
```

* cf) 아래와 같이 /etc/hosts파일을 직접 셋팅 해도 됨
```
52.213.183.141 vm01
54.75.118.15   vm02
54.75.118.154  vm03
```

4. git Clone
```
cd
git clone https://github.com/kubernetes-sigs/kubespray
```

5. inventory파일 생성
```
cd kubespray
cat > inventory/inventory.ini <<EOF
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

6. kubesparyInstall.sh 실행
```
cat > k8sInstallByKubesray.sh <<EOF
if [ ! -f requirements.txt ]; then
    echo "go to kubespray install folder"
else
    sudo pip3.10 install -r requirements.txt
    ansible-playbook --flush-cache -u ubuntu -b --become --become-user=root \
      -i inventory/inventory.ini \
      cluster.yml
fi
EOF

bash k8sInstallByKubesray.sh
```

# Admin
## Shutdown All Instance
```
for i in $(seq 3); do ssh ubuntu@vm0$i sudo sh -c 'shutdown -h now'; done
```
## Startup all Instance
```
ids=$(aws ec2 describe-instances  --filters "Name=tag-value,Values=vm0*" --query "Reservations[].Instances[].InstanceId" --output text)
for i in $ids; do     aws ec2 start-instances --instance-ids $i ;done
```
