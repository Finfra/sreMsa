# Kubernetes Install With Kubespray
## 0. 변수 셋팅 파일 생성 후 실행
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

## 1. OS key 생성 [있으면 생략]
```
ssh-keygen -f ~/.ssh/id_rsa -N ''
```
* cf) 설치 대상 host에 Public-key 배포
    ssh-copy-id root@10.0.2.10

## 2. Terrform 으로 host 셋팅
```
cd
git clone https://github.com/Finfra/sreMsa
cd ~/sreMsa/lab1.Kubespray/3.InstanceForKubernetes
#terraform destroy -auto-approve
terraform init
terraform apply --auto-approve
source doSetHosts.sh
cd ~
```


## 3. Hosts파일 셋팅
```
aws configure
  # security setting
    AWS Access Key ID [None]: xxxxxxxxxx
    AWS Secret Access Key [None]: xxxxxxxxxxxxxxxxxxx
    Default region name [None]: ap-northeast-2
    Default output format [None]: text
cd ~/sreMsa/lab1.Kubespray/3.InstanceForKubernetes
# rm -rf ~/.ssh/known_hosts
bash doSetHosts.sh
```

## 3.1 Ansible Fact Cache 정리 (두번째 설치시)
첫 번째 실행 실패의 주요 원인인 fact cache를 미리 정리합니다:
```bash
# Ansible fact cache 정리
sudo rm -rf /tmp/ansible_facts*
sudo rm -rf /tmp/kubespray*
sudo rm -rf ~/.ansible/tmp/*

# 기존 Kubespray 디렉토리 제거
rm -rf ~/kubespray
```


# 3.2. 모든 호스트 repo update
* 필수 아님. repo상태 안좋을때만,
```
hosts=("vm01" "vm02" "vm03")
for host in "${hosts[@]}"; do
  echo "Connecting to $host ..."
  ssh "$host" << EOF
    # apt update 및 repository 추가
    sudo apt update
    REPO_LINE="deb http://mirror.kakao.com/ubuntu/ noble main universe"
    if ! grep -Fxq "\$REPO_LINE" /etc/apt/sources.list; then
      echo "\$REPO_LINE" | sudo tee -a /etc/apt/sources.list
      echo "Repository line added successfully."
    else
      echo "Repository line already exists."
    fi
    sudo apt-get update
EOF
  if [ $? -eq 0 ]; then
    echo "Script executed successfully on $host."
  else
    echo "Failed to execute script on $host."
  fi
done
#cf : deb http://ftp.daum.net/ubuntu/ noble main universe

```

* cf) 아래와 같이 /etc/hosts파일을 직접 셋팅 해도 됨
```
52.213.183.141 vm01
54.75.118.15   vm02
54.75.118.154  vm03
```

## 4. git Clone
```
cd ~
git clone -b release-2.28 https://github.com/kubernetes-sigs/kubespray
cd kubespray
```

## 5. inventory파일 생성
```
cat > inventory/inventory.ini <<'EOF'
[all]
vm01 ansible_host=vm01 etcd_member_name=etcd1
vm02 ansible_host=vm02
vm03 ansible_host=vm03

[kube_control_plane]
vm01
vm02

[etcd]
vm01

[kube_node]
vm01
vm02
vm03

[k8s_cluster:children]
kube_control_plane
kube_node
EOF
```

### 6. EC2 설정 생성 (핵심!)
```bash
mkdir -p inventory/group_vars/all

# 최소 필수 설정만 포함
cat > inventory/group_vars/all/all.yml <<'EOF'
# EC2 프라이빗 IP ping 체크 비활성화 (EC2 필수!)
ping_access_ip: false
wait_for_services_timeout: 900
kube_apiserver_request_timeout: "90s"
EOF
```

### 7. 노드 연결 확인 (선택사항)
```bash
# 모든 노드에 연결 가능한지 확인
ansible -i inventory/inventory.ini all -m ping
```

## 8. kubesparyInstall.sh 실행
* pip error시 requirements.txt파일에서 에러가 발생하는 페키지의 "=="부터 줄의 끝까지 제거.
* python3.12버전에서는 --break-system-packages 옵션 필요. 
```
sudo apt remove -y python3-jsonschema # ubuntu24.04에서만 
sudo python -m pip install --break-system-packages -r requirements.txt

ansible-playbook --flush-cache -u ubuntu -b --become --become-user=root \
  -i inventory/inventory.ini -v \
  --private-key ~/.ssh/id_rsa \
  cluster.yml 

```

# 🔍 자동 설치 컴포넌트

Kubespray가 자동으로 설치하는 container runtime 도구들:
- **containerd**: 메인 container runtime
- **runc**: OCI 표준 runtime
- **crictl**: CRI 디버깅 도구
- **nerdctl**: Docker 호환 CLI

# ✅ 설치 확인

## 클러스터 상태 확인
```bash
ssh vm01 'sudo kubectl get nodes'
```

## Container Runtime 확인
```bash
for node in vm01 vm02 vm03; do
  echo "=== $node ==="
  ssh $node 'which containerd && containerd --version'
done
```

## Pod 분산 테스트
```bash
ssh vm01 'sudo kubectl create deployment test-nginx --image=nginx:latest --replicas=6'
sleep 10
ssh vm01 'sudo kubectl get pods -o wide'

# ssh vm01 'sudo kubectl delete deployment test-nginx'
```

# 🚨 주의사항

1. **EC2 필수 설정**: `ping_access_ip: false` 반드시 설정
2. **첫 실행 시간**: 바이너리 다운로드로 인해 20-25분 소요
3. **네트워크 의존성**: 안정적인 인터넷 연결 필요
4. **메모리 요구사항**: 각 노드 최소 2GB RAM 권장



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

## vm destroy
```
terraform destroy --auto-approve
```
