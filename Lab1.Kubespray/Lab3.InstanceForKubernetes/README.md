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

[kube_control_plane]
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
kube_control_plane
kube-node
EOF
```

6. kubesparyInstall.sh 실행
* pip error시 requirements.txt파일에서 에러나는 페키지의 "=="부터 줄의 끝까지 제거.
* python3.12버전에서는 --break-system-packages 옵션 필요. 
```
sudo apt remove -y python3-jsonschema
sudo python -m pip install --break-system-packages -r requirements.txt
sudo python -m pip install --break-system-packages ara[server]
export ANSIBLE_CALLBACK_PLUGINS=$(python3 -m ara.setup.callback_plugins)
ara-manage runserver&
hosts=(vm03)
for host in "${hosts[@]}"; do
   # ssh "$host" "sudo sudo apt-get remove --purge docker docker-engine docker.io containerd runc"
   ssh "$host" "sudo apt-get install -y docker.io"
   ssh "$host" "sudo systemctl start docker"
   ssh "$host" "sudo systemctl enable docker"
   ssh "$host" "sudo ln -sf /usr/bin/ctr /usr/local/bin/ctr"
done

ansible-playbook --flush-cache -u ubuntu -b --become --become-user=root \
  -i inventory/inventory.ini \
  cluster.yml
```

# Admin
## Set hostname setting for vm01~vm03
```
# 호스트 이름 리스트
hostname=i1
echo i1 > /etc/hostname
hosts=("vm01" "vm02" "vm03")
# 각 호스트에 대해 SSH 접속 후 호스트 이름 설정
for host in "${hosts[@]}"; do
  echo "Setting hostname for $host"
  ssh $host "sudo hostnamectl set-hostname $host && echo $host | sudo tee /etc/hostname"
  if [ $? -eq 0 ]; then
    echo "$host: Hostname set successfully"
  else
    echo "$host: Failed to set hostname"
  fi
done
```
## Shutdown All Instance
```
for i in $(seq 3); do ssh ubuntu@vm0$i sudo sh -c 'shutdown -h now'; done
```
## Startup all Instance
```
ids=$(aws ec2 describe-instances  --filters "Name=tag-value,Values=vm0*" --query "Reservations[].Instances[].InstanceId" --output text)
for i in $ids; do     aws ec2 start-instances --instance-ids $i ;done
```

## vm destroy
```
terraform destroy --auto-approve
```
