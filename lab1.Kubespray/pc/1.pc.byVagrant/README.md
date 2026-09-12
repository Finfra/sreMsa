# 로컬(PC) 실습 환경 — Vagrant + Kubespray

AWS 없이 PC 한 대에서 Kubernetes 클러스터를 만든다.
**AWS 경로와 같은 도구·같은 명령을 쓴다.** Terraform 이 하던 일을 Vagrant 가 대신할 뿐이다.

```
        AWS 경로                          로컬 경로
   ┌──────────────────┐            ┌──────────────────┐
   │ i1 (EC2)         │            │ i1 (VirtualBox)  │
   │  ansible         │            │  ansible         │
   │  kubespray       │            │  kubespray       │  ← 여기서 하는 일은 완전히 같다
   └────────┬─────────┘            └────────┬─────────┘
            │ ssh ubuntu@vm01               │ ssh ubuntu@vm01
   ┌────────▼─────────┐            ┌────────▼─────────┐
   │ vm01 vm02 vm03   │            │ vm01 vm02 vm03   │
   │ (EC2)            │            │ (VirtualBox)     │
   └──────────────────┘            └──────────────────┘
     Terraform 이 생성                Vagrant 가 생성
```

Windows 호스트에는 **VirtualBox 와 Vagrant 만** 있으면 된다.
Ansible 은 호스트가 아니라 i1 안에서 돈다. **Vagrant 플러그인도 쓰지 않는다** — `vagrant plugin list` 가
`No plugins installed` 인 상태로 4대가 동작하는 것을 실기에서 확인했다(2026-08-26).
예전 자료들이 Windows 에 `vagrant-winnfsd` 를 필수로 안내하는 것은 공유 폴더를 NFS 로 쓰던 시절의 이야기이고,
여기서는 VirtualBox 기본 공유를 쓴다. 수강생에게 배포하는 환경일수록 설치 단계와 버전 충돌 지점을 줄이는 편이 낫다.

[Vagrantfile](Vagrantfile) 의 아래 한 줄은 플러그인을 요구하는 것이 아니라,
**이미 설치돼 있는 경우에만** 그 동작을 끄는 가드다.

```ruby
config.vbguest.auto_update = false if Vagrant.has_plugin?("vagrant-vbguest")
```

만들어지는 것은 VM 네 대다.

| VM   | 역할                                                           | IP            |  vCPU |     메모리 |
| :--- | :------------------------------------------------------------- | :------------ | ----: | ---------: |
| i1   | 콘솔 서버. 여기서 Kubespray 를 실행한다 (Kubernetes 노드 아님) | 192.168.56.10 |     1 |     1024MB |
| vm01 | control plane + etcd + **worker**                              | 192.168.56.11 |     2 |     3072MB |
| vm02 | control plane + worker                                         | 192.168.56.12 |     2 |     3072MB |
| vm03 | worker                                                         | 192.168.56.13 |     2 |     2560MB |
|      |                                                                | **합계**      | **7** | **9728MB** |

> 이전 판까지 쓰던 `rayshoo/vansinetes` 는 더 이상 동작하지 않는다.
> 폐쇄된 `apt.kubernetes.io` 저장소에서 Kubernetes 1.20.2 를 받으려 하기 때문이며, 주소를 바꿔도 살아나지 않는다.
> 그 경로는 이 문서로 대체되었다.

# 시작하기 전에 — 기본 설치를 먼저 끝낸다 ★

프로그램 설치·Windows 사전 작업·소스 내려받기는 **[0.pc_setting/README.md](../0.pc_setting/README.md)** 가 다룬다
(0~1장). 강사 배포 폴더 `_prgs` 안에도 같은 문서가 들어 있다.

**그 문서를 마치고 돌아온다.** 아래 상태여야 이어서 진행할 수 있다.

```powershell
cd $env:USERPROFILE\Downloads\sreMsa\lab1.Kubespray\pc\1.pc.byVagrant
vagrant box list      # bento/ubuntu-24.04 가 보여야 한다
```

이 문서는 **2장(VM 만들기)부터** 시작한다.

# 2. VM 만들기

```powershell
vagrant up
```

* 앞에서 box 를 등록해 두었으므로 **이미지 다운로드는 일어나지 않는다.**
  VM 4대를 만들고 프로비저닝하는 데 **20~40분** 을 예상한다(i1 의 도구 설치가 대부분이다).
* `vagrant up` 이 box 를 받으려 한다면 등록이 안 된 것이다. `vagrant box list` 로 이름을 확인한다.
* box 업데이트 확인도 꺼 두었다([settings.yml](settings.yml) 의 `box.check_update`).
  교육장에서 여러 명이 동시에 `vagrant up` 을 할 때 그 조회가 겹치는 것을 막기 위함이다.
* i1 이 가장 먼저 만들어진다. i1 이 ssh 키를 만들어야 vm01~vm03 이 그 키를 받기 때문에 순서가 중요하다.
  `vagrant up` 을 그냥 실행하면 순서는 알아서 지켜진다.
* 중간에 실패하면 그 VM 만 다시 만든다.

```powershell
vagrant destroy -f vm02
vagrant up vm02
```

만들어진 VM 을 확인한다.

```powershell
vagrant status
```

# 3. Windows 의 hosts 파일에 등록

실습 중에 `curl vm01:30080` 처럼 **호스트(내 PC)에서 노드 이름으로** 접근하는 대목이 여러 번 나온다.
그러려면 Windows 도 이름을 알아야 한다.

`vagrant up` 이 만들어 둔 `hosts.generated` 파일의 내용을 그대로 쓴다.

```powershell
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

```powershell
ping -n 1 vm01
```

# 4. 콘솔 서버(i1) 접속

여기서부터는 **AWS 경로와 같다.** 하는 일이 같을 뿐 아니라 명령도 같다.

```powershell
vagrant ssh i1
```

접속하면 **`ubuntu` 계정으로 바로 들어간다.** 이 실습의 명령이 전부 ubuntu 기준이라
프로비저닝이 그렇게 맞춰 두었다. `sudo su - ubuntu` 를 따로 칠 필요가 없다.

> AWS 경로의 [aws/3.aws.InstanceForKubernetes/README.md](../../aws/3.aws.InstanceForKubernetes/README.md) 0단계 `su - ubuntu` 에 해당한다.
> AWS 키 설정(`TF_VAR_AWS_ACCESS_KEY` 등)은 로컬에서 필요 없으므로 건너뛴다.

## 접속이 느리다면 — `doSsh.ps1` 를 쓴다 ★

`vagrant ssh` 는 명령 하나에 **5~10초**가 걸린다. Vagrant CLI 가 Ruby 런타임과
내장 플러그인 수십 개를 매번 새로 로드하는 구조 때문이고, **VM 이나 PC 가 느린 것이 아니다.**
실기(Windows 10 · i7-6700T · 16GB)에서 측정한 값이다.

| 명령                       |       소요 |
| :------------------------- | ---------: |
| `vagrant ssh i1 -c true`   |      6.8초 |
| `vagrant status`           |      9.0초 |
| `vagrant --help`           |     11.3초 |
| **`ssh -F ssh-config i1`** | **0.12초** |
| `VBoxManage showvminfo`    |     0.08초 |

같은 폴더의 **`doSsh.ps1`** 은 접속 정보를 한 번만 뽑아 두고 그 다음부터 `ssh` 를 직접 쓴다.
자주 드나드는 실습에서는 이쪽이 훨씬 편하다.

```powershell
.\doSsh.ps1              # i1 에 접속
.\doSsh.ps1 vm01         # vm01 에 접속
.\doSsh.ps1 i1 hostname  # 명령 하나만 실행하고 빠져나옴
```

여기서 쓰는 `ssh` 는 **Windows 10 에 기본으로 들어 있는 것**이다(`System32\OpenSSH`).
별도 설치가 필요 없어 이 실습은 Git for Windows 를 쓰지 않는다.

> 처음 실행할 때 스크립트 실행이 막히면 그 창에서만 한 번 허용한다.
> ```powershell
> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
> ```
> (`Process` 범위라 창을 닫으면 원래대로 돌아간다. 시스템 설정을 바꾸지 않는다.)

`vagrant` 를 부르는 것은 `ssh-config` 를 만드는 최초 1회뿐이다.
VM 을 다시 만들었다면 `del .vagrant\ssh-config` 후 다시 실행한다.

# 5. 환경 점검 ★ Kubespray 전에 반드시

Kubespray 는 20분 넘게 돈다. 20분 뒤에 실패하는 것보다, 1분 만에 원인을 아는 편이 낫다.

```bash
bash /sreMsa/lab1.Kubespray/pc/2.pc.InstanceForKubernetes/doVerify.sh
```

여덟 항목을 점검한다. 특히 아래 둘이 핵심이다.

* `[5] 노드가 인식하는 자기 IP` — VirtualBox 고유의 함정을 사전에 잡는다
* `[7] Ansible 연결` — **i1 에서 vm01~vm03 으로 Ansible 이 실제로 붙는지 확인한다**

전부 `[ OK ]` 가 나와야 다음으로 간다.
`ssh` 나 `ansible ping` 이 실패하면 호스트(내 PC)의 PowerShell 로 돌아가 키를 다시 심는다.

```powershell
vagrant provision vm01 vm02 vm03
```

# 6. hosts 확인 · known_hosts 정리

```bash
bash /sreMsa/lab1.Kubespray/pc/2.pc.InstanceForKubernetes/doSetHosts.sh
```

> AWS 경로 3단계의 `bash doSetHosts.sh` 와 같은 자리다.
> AWS 는 이 스크립트가 인스턴스 IP 를 알아내야 했지만, 로컬은 IP 가 고정이라 확인만 한다.

# 7. Kubespray 내려받기

**여기서부터 9단계까지는 AWS 경로와 사실상 같다.** 다른 것은 9.1 의 ansible 설치 방식 하나뿐이다.

```bash
cd ~
git clone -b release-2.28 https://github.com/kubernetes-sigs/kubespray
cd kubespray
```

# 8. inventory 만들기

로컬에서는 **한 가지가 AWS 와 다르다.** 노드마다 `ip=` 를 명시해야 한다.

NAT 주소가 **모든 VM 에서 `10.0.2.15` 로 겹치기** 때문이다. 왜 그런지와 인터페이스 구성은
아래 참고 자료의 **"AWS 경로와의 대조 → inventory 에 `ip=` 를 반드시 넣는다"** 절에 있다.

스크립트가 알아서 넣어 준다.

```bash
bash /sreMsa/lab1.Kubespray/pc/2.pc.InstanceForKubernetes/doMakeInventory.sh
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

## 9.1 ansible 버전 맞추기 ★ 이 단계를 건너뛰면 설치가 시작되지 않는다

4장에서 i1 에 깔린 ansible 은 **core 2.17.x** 인데, Kubespray `release-2.28` 은 **2.16.4 이상 2.17.0 미만**만 받는다.
그대로 실행하면 아래처럼 **첫 태스크에서 거부당한다.**

```
TASK [Check 2.16.4 <= Ansible version < 2.17.0]
fatal: "Ansible must be between 2.16.4 and 2.17.0 exclusive - you have 2.17.14"
```

Kubespray 가 요구하는 버전은 방금 받은 `requirements.txt` 에 적혀 있다.
시스템 파이썬을 건드리지 않도록 **전용 가상환경(venv)** 을 만들어 그 안에만 설치한다.

```bash
cd ~/kubespray
python3 -m venv ~/ksvenv
source ~/ksvenv/bin/activate
pip install -U pip
pip install -r requirements.txt      # ansible 9.13.0 = core 2.16.19
ansible --version                    # core 2.16.19 로 바뀌었는지 확인
```

> AWS 경로에서 `pip install -r requirements.txt` 를 하던 자리와 같다.
> AWS 는 시스템에 바로 깔았지만, 여기서는 venv 를 쓴다 — 되돌리려면 `rm -rf ~/ksvenv` 하나면 된다.

⚠️ **venv 는 터미널마다 켜 줘야 한다.** i1 에 다시 접속했거나 창을 새로 열었다면
`cluster.yml` 을 돌리기 전에 `source ~/ksvenv/bin/activate` 를 한 번 더 실행한다.
프롬프트 앞에 `(ksvenv)` 가 보이면 켜진 것이다.

## 9.2 설치

```bash
ansible -i inventory/inventory.ini all -m ping     # 연결 확인

ansible-playbook --flush-cache -u ubuntu -b --become --become-user=root \
  -i inventory/inventory.ini -v \
  --private-key ~/.ssh/id_rsa \
  cluster.yml
```

* **15~20분** 걸린다. 16GB·8코어 PC 에서 `cluster.yml` 만 **15분 20초**, `vagrant up` 부터 세면 **24분 15초** 였다(2026-08-30·08-31 두 차례 실측).
  PC 가 느리면 더 걸릴 수 있으나, 45분을 넘기면 정상 진행이 아니라고 보고 아래 "자주 막히는 곳" 을 확인한다.
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

# 11. Docker 설치 (VM 안) ★ lab2 준비

lab2 의 `docker build`·`docker run` 실습은 **콘솔 서버 i1 안에서** 한다.
`_prgs/docker/` 의 deb 로 **오프라인 설치**하므로 인터넷을 쓰지 않는다.

> ⚠️ **내 PC(Windows)에 Docker Desktop 을 설치하지 말 것.**
> Hyper-V 가 켜져 VirtualBox 가 VM 을 띄우지 못하게 된다. 이 실습의 컨테이너는 전부 VM 안에서 돈다.

먼저 내 PC 에서 deb 를 소스 폴더로 옮긴다(탐색기로 복사해도 된다). 소스 폴더는 VM 안에서 `/sreMsa` 로 보인다.

```powershell
Copy-Item -Recurse $env:USERPROFILE\Downloads\_prgs\docker `
          $env:USERPROFILE\Downloads\sreMsa\
```

i1 에 접속해 설치한다.

```powershell
cd $env:USERPROFILE\Downloads\sreMsa\lab1.Kubespray\pc\1.pc.byVagrant
.\doSsh.ps1 i1
```

접속되면 **여기부터는 i1 안**이다.

```bash
sudo dpkg -i /sreMsa/docker/*.deb
sudo usermod -aG docker $USER
newgrp docker
docker version
```

`dpkg` 가 의존성 오류를 내면 아래 한 줄로 정리된다(이 경우에만 인터넷을 쓴다).

```bash
sudo apt-get -f install -y
```

* 확인 : `docker version` 이 Client·Server 양쪽을 보여주면 된다. Server 가 안 나오면 `sudo systemctl status docker` 로 데몬을 확인한다.

# 12. 정리

## 잠시 멈추기 (다음에 이어서)

```powershell
vagrant halt          # 전부 정지
vagrant up            # 다시 시작
```

VM 을 다시 켠 뒤 Kubernetes 가 올라오는 데 1~2분 걸린다.

## 완전히 지우기

```powershell
vagrant destroy -f
```

## 설치 파일을 지워도 되나

실습이 끝난 뒤에는 `_prgs` 를 지워도 된다. 다만 VM 을 다시 만들 일이 있으면 box 는 남겨 두는 편이 낫다.

* 등록된 box 는 `C:\Users\<계정>\.vagrant.d\boxes\` 로 복사되므로, **등록을 마쳤다면 `_prgs` 의 `.box` 파일 자체는 지워도** 실습에 지장이 없다.

# 자주 막히는 곳

| 증상                                                                | 원인·해결                                                                                                                                                                      |
| :------------------------------------------------------------------ | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vagrant up` 이 VM 을 못 띄운다                                     | Hyper-V·메모리 무결성이 켜져 있다. [0.pc_setting/README.md](../0.pc_setting/README.md) 의 "Windows 만의 사전 작업" 을 다시 확인한다. `HypervisorPresent` 가 `False` 인지 볼 것 |
| `Timed out while waiting for the machine to boot`                   | **VM 이 죽은 것이 아닐 수 있다.** 아래 "부팅이 오래 걸릴 때" 참조                                                                                                              |
| `vagrant up` 이 box 를 내려받으려 한다                              | box 등록을 건너뛰었거나 이름이 다르다. `vagrant box list` 로 `bento/ubuntu-24.04` 인지 확인한다                                                                                |
| i1 에서 `ssh vm01` 이 암호를 묻는다                                 | 호스트에서 `vagrant provision vm01`                                                                                                                                            |
| `/vagrant` 가 비어 있다                                             | 공유 폴더가 마운트되지 않았다. `vagrant reload` 후 재시도                                                                                                                      |
| `ansible ping` 이 실패한다                                          | i1 에서 `bash /sreMsa/lab1.Kubespray/pc/2.pc.InstanceForKubernetes/doVerify.sh` — 어느 단계에서 끊기는지 나온다                                                                |
| 노드가 전부 10.0.2.15 로 보인다                                     | inventory 에 `ip=` 가 빠졌다. `bash /sreMsa/lab1.Kubespray/pc/2.pc.InstanceForKubernetes/doMakeInventory.sh`                                                                   |
| Windows 에서 `curl vm01:...` 이 안 된다                             | 3장의 hosts 파일 등록을 빠뜨렸다                                                                                                                                               |
| `Ansible must be between 2.16.4 and 2.17.0` 로 즉시 멈춘다          | venv 를 켜지 않았다. 9.1 참조 — `source ~/ksvenv/bin/activate` 후 다시 실행                                                                                                    |
| cluster.yml 이 중간에 멈춘다                                        | fact 캐시를 지우고 재실행 (9장 참조)                                                                                                                                           |
| 메모리가 모자라 PC 가 멈춘다                                        | 아래 참고 자료의 "자원 → 메모리가 부족할 때"                                                                                                                                   |
| **VirtualBox 설치가 1초 만에 실패한다**                             | `2_vc_redist.x64.exe` 를 `3_VirtualBox` 보다 먼저 설치하지 않았다. `msiexec` 오류 1603 이 그 증상이다                                                                          |
| **Docker Desktop 을 깔았더니 `vagrant up` 이 안 된다**              | Hyper-V 가 켜졌다. **이 실습에 Docker Desktop 은 필요 없다** — 컨테이너는 VM 안에서 돈다. 관리자 PowerShell 에서 `bcdedit /set hypervisorlaunchtype off` 후 재부팅             |
| **Docker Desktop 이 `Virtualization support not detected` 로 뜬다** | Hyper-V 를 껐기 때문이며 **정상이다.** Docker Desktop 은 이 실습에서 쓰지 않는다 — 컨테이너 실습은 11장처럼 VM(i1) 안의 Docker 로 한다                                         |
| **VM 이 깨졌거나 설치가 끝나지 않았다**                             | 배포 폴더의 `_vm` 안에 완성본이 있다. **강사 안내를 받고 진행한다** — 그 안의 `README.md` 에 절차가 있다                                                                       |

## 부팅이 오래 걸릴 때

`Timed out while waiting for the machine to boot` 가 나와도 **VM 이 실패한 것이 아닐 수 있다.**
디스크가 느리면 부팅에 5~10분이 걸리기도 하는데, Vagrant 가 먼저 기다리기를 포기한 것뿐이다.

먼저 VM 이 살아 있는지 본다.

```powershell
vagrant status
```

`running` 이면 부팅 중일 가능성이 크다. 콘솔 화면을 찍어 확인한다.

```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm sreMsa-vm02 screenshotpng vm02.png
```

아래처럼 나오면 **정상적으로 부팅하는 중**이고 시간만 더 필요한 것이다.

```
Job systemd-networkd.service/start running (7min 3s / 7min 31s)
INFO: task (networkd):532 blocked for more than 245 seconds
```

이 실습은 [settings.yml](settings.yml) 에서 대기 시간을 **900초**로 늘려 두었으므로
대개는 걸리지 않는다. 그래도 걸린다면 다시 시도한다.

```powershell
vagrant halt vm02 -f
vagrant up vm02
```

디스크 응답이 실제로 느린지는 이렇게 잰다. SSD 라면 보통 0.001초 이하이고,
**0.05초를 넘으면 느린 상태**다(대용량 파일을 쓴 직후 캐시가 소진되면 이렇게 된다).

```powershell
Get-Counter "\PhysicalDisk(_Total)\Avg. Disk sec/Transfer"
```

# 더 볼 것

* 이 문서 아래쪽 **참고 자료** — 구성 상세, AWS·Terraform 과의 대조표, 자원 산정, 노드 추가 실습
* [aws/3.aws.InstanceForKubernetes/README.md](../../aws/3.aws.InstanceForKubernetes/README.md) — AWS 경로. 그 문서의 4~8장(git clone·inventory·Kubespray 실행)이 이 문서 7~10장과 같은 내용이다
* [0.pc_setting/README.md](../0.pc_setting/README.md) — 0~1장. 프로그램 설치·Windows 설정·소스 내려받기

# ─────────── 여기부터는 참고 자료 ───────────

아래는 실습 중에 순서대로 읽는 내용이 아니라, **이 폴더가 어떻게 구성돼 있고 왜 그런지**를
알아야 할 때 보는 절이다.

# 파일

| 파일                                                                   | 실행 위치 | 하는 일                                                 |
| :--------------------------------------------------------------------- | :-------- | :------------------------------------------------------ |
| [settings.yml](settings.yml)                                           | —         | 노드 수·자원·IP 대역. **고칠 파일은 이것 하나뿐이다**   |
| [Vagrantfile](Vagrantfile)                                             | 호스트    | settings.yml 을 읽어 i1·vm01~vm0N 을 만든다             |
| [scripts/common.sh](scripts/common.sh)                                 | 전 노드   | /etc/hosts, ubuntu 계정, swap off, 방화벽 off           |
| [scripts/i1.sh](scripts/i1.sh)                                         | i1        | ssh 키 생성 + `installOnEc2.sh` 실행                    |
| [scripts/node.sh](scripts/node.sh)                                     | vm0N      | i1 공개키 등록                                          |
| [doSetHosts.sh](../2.pc.InstanceForKubernetes/doSetHosts.sh)           | i1        | AWS 동명 스크립트의 로컬판. hosts 확인·known_hosts 정리 |
| [doMakeInventory.sh](../2.pc.InstanceForKubernetes/doMakeInventory.sh) | i1        | kubespray inventory 생성 (`ip=` 자동 기입)              |
| [doVerify.sh](../2.pc.InstanceForKubernetes/doVerify.sh)               | i1        | **Ansible 이 i1→vm0N 으로 실제 동작하는지 점검**        |

`hosts.generated`·`.keys/`·`.vagrant/` 는 `vagrant up` 이 만드는 산출물이라 git 에 넣지 않는다.

# AWS 경로와의 대조

## 같은 것

| 항목                | 값                                                                                           |
| :------------------ | :------------------------------------------------------------------------------------------- |
| 노드 이름           | `i1`, `vm01`, `vm02`, `vm03`                                                                 |
| 계정                | `ubuntu` (sudo 무암호)                                                                       |
| i1 → 노드 접속      | i1 의 `~/.ssh/id_rsa` 키 기반 무암호 ssh                                                     |
| i1 의 도구          | [installOnEc2.sh](../../aws/1.aws.byTerraform/installOnEc2.sh) **동일 파일을 그대로 실행**   |
| Kubespray           | `release-2.28` (Kubernetes 1.32.13)                                                          |
| inventory 역할 배치 | `kube_control_plane` = vm01·vm02 / `etcd` = vm01 / `kube_node` = **전 노드**                 |
| 설치 명령           | `ansible-playbook ... cluster.yml` — 문장까지 동일                                           |
| ansible 버전 맞추기 | 양쪽 다 `requirements.txt` 를 깔아야 한다. 로컬은 venv 로 한다 ([상위 README](../README.md)) |

`kube_node` 에 vm01 이 들어 있다. **vm01 은 control plane 이자 etcd 이자 워커 노드다.**
그래서 vm01 에는 다른 노드보다 메모리를 더 준다(settings.yml 의 `overrides`).

## 다른 것 — 두 가지뿐

### 1. inventory 에 `ip=` 를 반드시 넣는다 ★

VirtualBox VM 은 네트워크 인터페이스가 두 개다.

| 인터페이스 | 용도                              | 주소                             |
| :--------- | :-------------------------------- | :------------------------------- |
| eth0       | NAT (인터넷 나가는 길)            | **모든 VM 이 10.0.2.15 로 같다** |
| eth1       | host-only (VM 끼리·호스트와 통신) | 192.168.56.11, .12, .13 …        |

`ip=` 를 주지 않으면 Kubespray 가 첫 번째 인터페이스인 eth0 의 주소를 노드 주소로 잡는다.
그러면 **모든 노드가 10.0.2.15 라는 같은 주소를 갖게 되어 클러스터가 성립하지 않는다.**
AWS 인스턴스는 인터페이스가 하나뿐이라 이 문제가 없었다.

[doMakeInventory.sh](../2.pc.InstanceForKubernetes/doMakeInventory.sh) 가 이것을 자동으로 넣는다. 손으로 쓸 때는 아래처럼 된다.

```ini
[all]
vm01 ansible_host=192.168.56.11 ip=192.168.56.11 etcd_member_name=etcd1
vm02 ansible_host=192.168.56.12 ip=192.168.56.12
vm03 ansible_host=192.168.56.13 ip=192.168.56.13
```

[doVerify.sh](../2.pc.InstanceForKubernetes/doVerify.sh) 의 `[5]` 항목이 이 함정을 사전에 잡는다.

### 2. hosts 파일을 얻는 방법

AWS 는 IP 가 생성 시점에 정해지므로 `doSetHosts.sh` 가 `aws ec2 describe-instances` 로 알아냈다.
로컬은 settings.yml 에 IP 가 고정돼 있어 Vagrant 가 부팅할 때 이미 넣어 둔다.
로컬판 `doSetHosts.sh` 는 그것을 **확인**하고 known_hosts 를 정리하는 역할만 한다.

## Terraform 과의 대응

| Terraform                                 | Vagrant                         | 비고                                                                                    |
| :---------------------------------------- | :------------------------------ | :-------------------------------------------------------------------------------------- |
| `var.instance_count`                      | `nodes.count`                   | 노드 수                                                                                 |
| `var.instance_type` (t3.small)            | `nodes.cpu` / `nodes.memory`    | 로컬은 노드별로 다르게 줄 수 있다                                                       |
| `tags.Name = format("vm0%d", i+1)`        | `format("vm%02d", i)`           | 1~9 는 완전히 같다. 10 이상은 Terraform 이 `vm010` 이 되는데 강의는 3~4대라 닿지 않는다 |
| `aws_key_pair` (i1 의 공개키 등록)        | `scripts/node.sh`               | 같은 목적 — i1 키를 노드에 심는다                                                       |
| `provisioner "remote-exec"` → `script.sh` | `scripts/common.sh`             | 로컬 쪽이 하는 일이 더 많다 (hosts·계정·swap·방화벽)                                    |
| `aws_security_group` (전체 허용)          | host-only 네트워크 + ufw 비활성 | 로컬은 외부에 열리지 않는다                                                             |
| `root_block_device` 100GB                 | box 기본 디스크                 | bento/ubuntu-24.04 기본값으로 충분하다                                                  |

# 자원

기본값 합계는 **7 vCPU · 9.5GB** 다.

| VM       |  vCPU |     메모리 | 역할                                |
| :------- | ----: | ---------: | :---------------------------------- |
| i1       |     1 |     1024MB | Ansible 실행 (Kubernetes 노드 아님) |
| vm01     |     2 |     3072MB | control plane + etcd + worker       |
| vm02     |     2 |     3072MB | control plane + worker              |
| vm03     |     2 |     2560MB | worker                              |
| **합계** | **7** | **9728MB** |                                     |

* 호스트 **16GB** — 가능하되 브라우저·IDE 를 닫는 편이 좋다
* 호스트 **24GB 이상** — 권장. 노드 추가 실습(vm04, +2560MB)까지 여유롭다
* **CPU 도 함께 본다** — 논리 프로세서가 8개인 PC 라면 게스트가 7개를 가져가고 호스트에 1개가 남는다.
  코어가 4개뿐이라면 노드를 1 vCPU 로 낮추는 편이 낫다

## i1 이 1GB 인 이유, 그리고 swap

i1 은 Kubernetes 노드가 아니라 Ansible 만 돌리므로 1 vCPU · 1GB 로 충분하다.
다만 Kubespray 가 노드마다 fork 를 띄우는 구간에서는 1GB 가 빠듯할 수 있어,
[scripts/common.sh](scripts/common.sh) 가 **i1 에만 swap 파일 2GB 를 만들어 준다.**

Kubernetes 노드는 kubelet 이 swap 을 거부하므로 반대로 반드시 꺼야 한다.
같은 스크립트가 호스트명을 보고 갈라 처리한다.

| 대상      | swap         | 이유                                       |
| :-------- | :----------- | :----------------------------------------- |
| i1        | **2GB 생성** | kubelet 이 없다. 작은 메모리의 완충이 된다 |
| vm01~vm0N | **끔**       | kubelet 이 swap 이 켜져 있으면 뜨지 않는다 |

i1 에서 메모리 부족이 실제로 보이면 settings.yml 의 `i1.memory` 를 2048 로 되돌린다.

## 메모리가 부족할 때

control plane 을 vm01 한 대로 줄이면 vm02 를 워커 자원으로 낮출 수 있다.
settings.yml 의 `overrides` 에서 vm02 항목을 지우고, inventory 의 `[kube_control_plane]` 에서 vm02 를 뺀다.
합계가 9.5GB → 9GB 가 되고, 무엇보다 control plane 이 하나라 부팅이 빨라진다.
다만 AWS 경로의 inventory 와 달라지므로 **강의 중에는 기본값을 권한다.**

# 노드 추가 실습 (3.k8sNodeManage)

AWS 경로와 절차가 같다. 다른 것은 첫 줄뿐이다.

| 단계          | AWS                                                    | 로컬                                                                                              |
| :------------ | :----------------------------------------------------- | :------------------------------------------------------------------------------------------------ |
| VM 추가       | `vars.tf` 의 `instance_count` 를 4 → `terraform apply` | `settings.yml` 의 `nodes.count` 를 4 → `vagrant up vm04`                                          |
| hosts         | `bash doSetHosts.sh`                                   | `bash /sreMsa/lab1.Kubespray/pc/2.pc.InstanceForKubernetes/doSetHosts.sh`                         |
| inventory     | vm04 추가                                              | `bash /sreMsa/lab1.Kubespray/pc/2.pc.InstanceForKubernetes/doMakeInventory.sh` (또는 손으로 추가) |
| 클러스터 반영 | `ansible-playbook ... cluster.yml`                     | **동일**                                                                                          |
| 확인          | `kubectl get nodes`                                    | **동일**                                                                                          |

`nodes.count` 를 바꾼 뒤에는 **기존 VM 을 지우지 않는다.** `vagrant up vm04` 만 실행하면 된다.
새로 만든 vm04 의 /etc/hosts 에는 4대가 모두 들어가지만 기존 3대에는 vm04 가 없으므로,
`vagrant provision` 을 한 번 돌려 전 노드의 hosts 를 맞춘다.

```powershell
# 호스트에서
vagrant up vm04
vagrant provision          # 전 노드 /etc/hosts 갱신
```

# 교육장 회선 보호

수강생이 동시에 실습하면 같은 파일을 여러 명이 한꺼번에 내려받아 회선이 막힌다.
box 하나가 621MB 이므로 20명이면 12GB 가 한꺼번에 흐른다. 두 가지로 막는다.

| 수단                                        | 무엇을 막는가                                                            |
| :------------------------------------------ | :----------------------------------------------------------------------- |
| 강사 제공 `_prgs` 폴더                      | box·설치 파일 다운로드 자체. `vagrant box add` 로 로컬 파일에서 등록한다 |
| `settings.yml` 의 `box.check_update: false` | `vagrant up` 마다 Vagrant Cloud 에 새 버전을 물어보는 조회               |

`check_update` 는 파일을 받는 것은 아니지만 `vagrant up` 마다 외부 요청이 나가므로,
여러 명이 동시에 시작하는 순간 그 요청이 겹친다. 강사가 새 box 를 받아 볼 때만 `true` 로 바꾼다.

수강생 안내는 [0.pc_setting/README.md](../0.pc_setting/README.md) 에 들어 있다 — 배포 폴더 구성·설치 순서·box 등록이 그곳에 있다.

