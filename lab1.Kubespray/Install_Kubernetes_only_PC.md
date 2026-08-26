# 클라우드 없이 PC 에서 Kubernetes 설치 (Vagrant + Kubespray)

AWS 계정 없이 내 PC 한 대에 Kubernetes 클러스터를 만든다.
**AWS 경로와 같은 도구, 같은 명령을 쓴다.** Terraform 이 하던 일을 Vagrant 가 대신할 뿐이고,
Kubespray 를 실행하는 부분은 [3.InstanceForKubernetes/README.md](3.InstanceForKubernetes/README.md) 와 동일하다.

만들어지는 것은 VM 네 대다.

| VM   | 역할                                                           | IP            | vCPU | 메모리 |
| :--- | :------------------------------------------------------------- | :------------ | ---: | -----: |
| i1   | 콘솔 서버. 여기서 Kubespray 를 실행한다 (Kubernetes 노드 아님) | 192.168.56.10 | 1 | 1024MB |
| vm01 | control plane + etcd + **worker**                              | 192.168.56.11 | 2 | 3072MB |
| vm02 | control plane + worker                                         | 192.168.56.12 | 2 | 3072MB |
| vm03 | worker                                                         | 192.168.56.13 | 2 | 2560MB |
| | | **합계** | **7** | **9728MB** |

> 이전 판까지 쓰던 `rayshoo/vansinetes` 는 더 이상 동작하지 않는다.
> 폐쇄된 `apt.kubernetes.io` 저장소에서 Kubernetes 1.20.2 를 받으려 하기 때문이며, 주소를 바꿔도 살아나지 않는다.
> 그 경로는 이 문서로 대체되었다.

# 0. 준비물

## 하드웨어

* 메모리 **16GB 최소**, 24GB 이상 권장 — VM 이 합계 **9.5GB** 를 쓴다
* CPU **논리 프로세서 8개 이상 권장** — VM 이 합계 7개를 가져간다. 4개뿐이면 느려진다
* 디스크 여유 **60GB 이상**
* CPU 가상화 지원 (요즘 PC 는 모두 지원한다)

메모리가 부족하면 [0.VagrantForLocal/README.md](0.VagrantForLocal/README.md) 의 "메모리가 부족할 때" 절을 본다.

## 소프트웨어 (Windows 기준)

1. **VirtualBox** — https://www.virtualbox.org/wiki/Downloads
2. **Vagrant** — https://developer.hashicorp.com/vagrant/downloads
3. **Git for Windows** — https://git-scm.com/download/win
   Git Bash 를 쓴다. PowerShell·cmd 로도 되지만 이 문서의 명령은 Git Bash 기준이다.

설치 후 터미널을 새로 열어 확인한다.

```bash
vagrant --version
VBoxManage --version
```

## Windows 만의 사전 작업 ★ 여기서 가장 많이 막힌다

VirtualBox 는 Hyper-V 가 켜져 있으면 VM 을 띄우지 못한다.
Docker Desktop·WSL2 를 쓴 적이 있거나, Windows 11 이라면 대개 켜져 있다.

**관리자 권한 PowerShell** 에서 실행한 뒤 재부팅한다.

```powershell
bcdedit /set hypervisorlaunchtype off
shutdown -r -t 0
```

Windows 11 은 Hyper-V 를 켠 적이 없어도 **메모리 무결성(코어 격리)** 이 기본으로 켜져 있어 같은 증상이 난다.
`Windows 보안 → 장치 보안 → 코어 격리 세부 정보` 에서 **메모리 무결성**을 끄고 재부팅한다.

> 되돌리려면 `bcdedit /set hypervisorlaunchtype auto` + 재부팅.
> Docker Desktop·WSL2 를 다시 쓸 때 필요하다.

## Git 줄바꿈 설정

Windows 의 Git 은 기본으로 줄바꿈을 CRLF 로 바꾼다. 셸 스크립트가 그대로 깨진다.
**소스를 내려받기 전에** 설정한다.

```bash
git config --global core.autocrlf false
```

# 1. 소스 내려받기

```bash
cd ~
git clone https://github.com/Finfra/sreMsa
cd sreMsa/lab1.Kubespray/0.VagrantForLocal
```

# 2. VM 만들기

```bash
vagrant up
```

* 처음 실행하면 Ubuntu 이미지를 받느라 오래 걸린다. **20~40분** 을 예상한다.
* i1 이 가장 먼저 만들어진다. i1 이 ssh 키를 만들어야 vm01~vm03 이 그 키를 받기 때문에 순서가 중요하다.
  `vagrant up` 을 그냥 실행하면 순서는 알아서 지켜진다.
* 중간에 실패하면 그 VM 만 다시 만든다.

```bash
vagrant destroy -f vm02 && vagrant up vm02
```

만들어진 VM 을 확인한다.

```bash
vagrant status
```

# 3. Windows 의 hosts 파일에 등록

실습 중에 `curl vm01:30080` 처럼 **호스트(내 PC)에서 노드 이름으로** 접근하는 대목이 여러 번 나온다.
그러려면 Windows 도 이름을 알아야 한다.

`vagrant up` 이 만들어 둔 `hosts.generated` 파일의 내용을 그대로 쓴다.

```bash
cat hosts.generated
```

```
192.168.56.10 i1
192.168.56.11 vm01
192.168.56.12 vm02
192.168.56.13 vm03
```

**메모장을 관리자 권한으로 실행**한 뒤 아래 파일을 열어 위 내용을 맨 아래에 붙여 넣고 저장한다.

```
C:\Windows\System32\drivers\etc\hosts
```

확인한다.

```bash
ping -n 1 vm01
```

# 4. 콘솔 서버(i1) 접속

여기서부터는 **AWS 경로와 같다.** 하는 일이 같을 뿐 아니라 명령도 같다.

```bash
vagrant ssh i1
sudo su - ubuntu
```

> AWS 경로의 [3.InstanceForKubernetes/README.md](3.InstanceForKubernetes/README.md) 0단계 `su - ubuntu` 에 해당한다.
> AWS 키 설정(`TF_VAR_AWS_ACCESS_KEY` 등)은 로컬에서 필요 없으므로 건너뛴다.

# 5. 환경 점검 ★ Kubespray 전에 반드시

Kubespray 는 20분 넘게 돈다. 20분 뒤에 실패하는 것보다, 1분 만에 원인을 아는 편이 낫다.

```bash
bash /vagrant/doVerify.sh
```

여덟 항목을 점검한다. 특히 아래 둘이 핵심이다.

* `[5] 노드가 인식하는 자기 IP` — VirtualBox 고유의 함정을 사전에 잡는다
* `[7] Ansible 연결` — **i1 에서 vm01~vm03 으로 Ansible 이 실제로 붙는지 확인한다**

전부 `[ OK ]` 가 나와야 다음으로 간다.
`ssh` 나 `ansible ping` 이 실패하면 호스트(내 PC)의 Git Bash 로 돌아가 키를 다시 심는다.

```bash
vagrant provision vm01 vm02 vm03
```

# 6. hosts 확인 · known_hosts 정리

```bash
bash /vagrant/doSetHosts.sh
```

> AWS 경로 3단계의 `bash doSetHosts.sh` 와 같은 자리다.
> AWS 는 이 스크립트가 인스턴스 IP 를 알아내야 했지만, 로컬은 IP 가 고정이라 확인만 한다.

# 7. Kubespray 내려받기

**여기서부터 9단계까지는 AWS 경로와 글자 하나까지 같다.**

```bash
cd ~
git clone -b release-2.28 https://github.com/kubernetes-sigs/kubespray
cd kubespray
```

# 8. inventory 만들기

로컬에서는 **한 가지가 AWS 와 다르다.** 노드마다 `ip=` 를 명시해야 한다.

VirtualBox VM 은 네트워크 카드가 두 장이고, 그중 첫 번째(NAT)의 주소가 **모든 VM 에서 10.0.2.15 로 같다.**
`ip=` 를 주지 않으면 Kubespray 가 그 주소를 노드 주소로 잡아 클러스터가 성립하지 않는다.
AWS 인스턴스는 카드가 한 장뿐이라 이 문제가 없었다.

스크립트가 알아서 넣어 준다.

```bash
bash /vagrant/doMakeInventory.sh
```

손으로 쓰려면 아래와 같다. AWS 경로 5·6단계에 `ip=` 만 더한 것이다.

```bash
cat > inventory/inventory.ini <<'EOF'
[all]
vm01 ansible_host=192.168.56.11 ip=192.168.56.11 etcd_member_name=etcd1
vm02 ansible_host=192.168.56.12 ip=192.168.56.12
vm03 ansible_host=192.168.56.13 ip=192.168.56.13

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

mkdir -p inventory/group_vars/all
cat > inventory/group_vars/all/all.yml <<'EOF'
ping_access_ip: false
wait_for_services_timeout: 900
kube_apiserver_request_timeout: "90s"
EOF
```

`[kube_node]` 에 **vm01 이 들어 있다.** vm01 은 control plane 이면서 워커 노드다. AWS 경로와 같은 배치다.

# 9. 설치 실행

```bash
ansible -i inventory/inventory.ini all -m ping     # 연결 확인

ansible-playbook --flush-cache -u ubuntu -b --become --become-user=root \
  -i inventory/inventory.ini -v \
  --private-key ~/.ssh/id_rsa \
  cluster.yml
```

* **30~45분** 걸린다 *(검증 필요 — 실기 측정 전)*. AWS 에서 20~25분 걸리는 작업이고, 로컬 디스크가 더 느리다.
* 두 번째 설치라면 먼저 캐시를 지운다 (AWS 경로 3.1 절과 동일).

```bash
sudo rm -rf /tmp/ansible_facts* /tmp/kubespray* ~/.ansible/tmp/*
```

# 10. 설치 확인

```bash
ssh vm01 'sudo kubectl get nodes'
```

```
NAME   STATUS   ROLES           AGE   VERSION
vm01   Ready    control-plane   5m    v1.32.13
vm02   Ready    control-plane   4m    v1.32.13
vm03   Ready    <none>          4m    v1.32.13
```

Pod 가 노드에 흩어지는지 본다.

```bash
ssh vm01 'sudo kubectl create deployment test-nginx --image=nginx:latest --replicas=6'
sleep 10
ssh vm01 'sudo kubectl get pods -o wide'
ssh vm01 'sudo kubectl delete deployment test-nginx'
```

이후 실습은 `ssh vm01` 로 들어가서 진행한다.

```bash
ssh vm01
sudo -i
kubectl get nodes
```

# 11. 정리

## 잠시 멈추기 (다음에 이어서)

```bash
vagrant halt          # 전부 정지
vagrant up            # 다시 시작
```

VM 을 다시 켠 뒤 Kubernetes 가 올라오는 데 1~2분 걸린다.

## 완전히 지우기

```bash
vagrant destroy -f
```

# 자주 막히는 곳

| 증상 | 원인·해결 |
| :--- | :--- |
| `vagrant up` 이 VM 을 못 띄운다 | Hyper-V·메모리 무결성이 켜져 있다. 0장의 사전 작업을 다시 확인한다 |
| 스크립트가 `\r` 오류를 낸다 | `core.autocrlf` 를 끄지 않고 clone 했다. `git config --global core.autocrlf false` 후 다시 clone |
| i1 에서 `ssh vm01` 이 암호를 묻는다 | 호스트에서 `vagrant provision vm01` |
| `ansible ping` 이 실패한다 | i1 에서 `bash /vagrant/doVerify.sh` — 어느 단계에서 끊기는지 나온다 |
| 노드가 전부 10.0.2.15 로 보인다 | inventory 에 `ip=` 가 빠졌다. `bash /vagrant/doMakeInventory.sh` |
| Windows 에서 `curl vm01:...` 이 안 된다 | 3장의 hosts 파일 등록을 빠뜨렸다 |
| cluster.yml 이 중간에 멈춘다 | fact 캐시를 지우고 재실행 (9장 참조) |
| 메모리가 모자라 PC 가 멈춘다 | [0.VagrantForLocal/README.md](0.VagrantForLocal/README.md) 의 "메모리가 부족할 때" |

# 더 볼 것

* [0.VagrantForLocal/README.md](0.VagrantForLocal/README.md) — 구성 상세, AWS·Terraform 과의 대조표, 노드 추가 실습
* [3.InstanceForKubernetes/README.md](3.InstanceForKubernetes/README.md) — AWS 경로. 7~10장이 이 문서와 같은 내용이다
