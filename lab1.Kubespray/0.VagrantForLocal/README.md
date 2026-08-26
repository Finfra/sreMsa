# 0. 로컬(PC) 실습 환경 — Vagrant + Kubespray

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
Ansible 은 호스트가 아니라 i1 안에서 돈다. Vagrant 플러그인도 쓰지 않는다.

수강생용 단계별 절차는 [Install_Kubernetes_only_PC.md](../Install_Kubernetes_only_PC.md) 에 있다.
이 문서는 이 폴더의 구성과 AWS 경로와의 차이를 설명한다.

# 파일

| 파일 | 실행 위치 | 하는 일 |
| :--- | :--- | :--- |
| [settings.yml](settings.yml) | — | 노드 수·자원·IP 대역. **고칠 파일은 이것 하나뿐이다** |
| [Vagrantfile](Vagrantfile) | 호스트 | settings.yml 을 읽어 i1·vm01~vm0N 을 만든다 |
| [scripts/common.sh](scripts/common.sh) | 전 노드 | /etc/hosts, ubuntu 계정, swap off, 방화벽 off |
| [scripts/i1.sh](scripts/i1.sh) | i1 | ssh 키 생성 + `installOnEc2.sh` 실행 |
| [scripts/node.sh](scripts/node.sh) | vm0N | i1 공개키 등록 |
| [doSetHosts.sh](doSetHosts.sh) | i1 | AWS 동명 스크립트의 로컬판. hosts 확인·known_hosts 정리 |
| [doMakeInventory.sh](doMakeInventory.sh) | i1 | kubespray inventory 생성 (`ip=` 자동 기입) |
| [doVerify.sh](doVerify.sh) | i1 | **Ansible 이 i1→vm0N 으로 실제 동작하는지 점검** |

`hosts.generated`·`.keys/`·`.vagrant/` 는 `vagrant up` 이 만드는 산출물이라 git 에 넣지 않는다.

# AWS 경로와의 대조

## 같은 것

| 항목 | 값 |
| :--- | :--- |
| 노드 이름 | `i1`, `vm01`, `vm02`, `vm03` |
| 계정 | `ubuntu` (sudo 무암호) |
| i1 → 노드 접속 | i1 의 `~/.ssh/id_rsa` 키 기반 무암호 ssh |
| i1 의 도구 | [installOnEc2.sh](../1.InstanceForTerraform/installOnEc2.sh) **동일 파일을 그대로 실행** |
| Kubespray | `release-2.28` (Kubernetes 1.32.13) |
| inventory 역할 배치 | `kube_control_plane` = vm01·vm02 / `etcd` = vm01 / `kube_node` = **전 노드** |
| 설치 명령 | `ansible-playbook ... cluster.yml` — 문장까지 동일 |

`kube_node` 에 vm01 이 들어 있다. **vm01 은 control plane 이자 etcd 이자 워커 노드다.**
그래서 vm01 에는 다른 노드보다 메모리를 더 준다(settings.yml 의 `overrides`).

## 다른 것 — 두 가지뿐

### 1. inventory 에 `ip=` 를 반드시 넣는다 ★

VirtualBox VM 은 네트워크 인터페이스가 두 개다.

| 인터페이스 | 용도 | 주소 |
| :--- | :--- | :--- |
| eth0 | NAT (인터넷 나가는 길) | **모든 VM 이 10.0.2.15 로 같다** |
| eth1 | host-only (VM 끼리·호스트와 통신) | 192.168.56.11, .12, .13 … |

`ip=` 를 주지 않으면 Kubespray 가 첫 번째 인터페이스인 eth0 의 주소를 노드 주소로 잡는다.
그러면 **모든 노드가 10.0.2.15 라는 같은 주소를 갖게 되어 클러스터가 성립하지 않는다.**
AWS 인스턴스는 인터페이스가 하나뿐이라 이 문제가 없었다.

[doMakeInventory.sh](doMakeInventory.sh) 가 이것을 자동으로 넣는다. 손으로 쓸 때는 아래처럼 된다.

```ini
[all]
vm01 ansible_host=192.168.56.11 ip=192.168.56.11 etcd_member_name=etcd1
vm02 ansible_host=192.168.56.12 ip=192.168.56.12
vm03 ansible_host=192.168.56.13 ip=192.168.56.13
```

[doVerify.sh](doVerify.sh) 의 `[5]` 항목이 이 함정을 사전에 잡는다.

### 2. hosts 파일을 얻는 방법

AWS 는 IP 가 생성 시점에 정해지므로 `doSetHosts.sh` 가 `aws ec2 describe-instances` 로 알아냈다.
로컬은 settings.yml 에 IP 가 고정돼 있어 Vagrant 가 부팅할 때 이미 넣어 둔다.
로컬판 `doSetHosts.sh` 는 그것을 **확인**하고 known_hosts 를 정리하는 역할만 한다.

## Terraform 과의 대응

| Terraform | Vagrant | 비고 |
| :--- | :--- | :--- |
| `var.instance_count` | `nodes.count` | 노드 수 |
| `var.instance_type` (t3.small) | `nodes.cpu` / `nodes.memory` | 로컬은 노드별로 다르게 줄 수 있다 |
| `tags.Name = format("vm0%d", i+1)` | `format("vm%02d", i)` | 1~9 는 완전히 같다. 10 이상은 Terraform 이 `vm010` 이 되는데 강의는 3~4대라 닿지 않는다 |
| `aws_key_pair` (i1 의 공개키 등록) | `scripts/node.sh` | 같은 목적 — i1 키를 노드에 심는다 |
| `provisioner "remote-exec"` → `script.sh` | `scripts/common.sh` | 로컬 쪽이 하는 일이 더 많다 (hosts·계정·swap·방화벽) |
| `aws_security_group` (전체 허용) | host-only 네트워크 + ufw 비활성 | 로컬은 외부에 열리지 않는다 |
| `root_block_device` 100GB | box 기본 디스크 | bento/ubuntu-24.04 기본값으로 충분하다 |

# 자원

기본값 합계는 **7 vCPU · 9.5GB** 다.

| VM | vCPU | 메모리 | 역할 |
| :--- | ---: | ---: | :--- |
| i1 | 1 | 1024MB | Ansible 실행 (Kubernetes 노드 아님) |
| vm01 | 2 | 3072MB | control plane + etcd + worker |
| vm02 | 2 | 3072MB | control plane + worker |
| vm03 | 2 | 2560MB | worker |
| **합계** | **7** | **9728MB** | |

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

| 대상 | swap | 이유 |
| :--- | :--- | :--- |
| i1 | **2GB 생성** | kubelet 이 없다. 작은 메모리의 완충이 된다 |
| vm01~vm0N | **끔** | kubelet 이 swap 이 켜져 있으면 뜨지 않는다 |

i1 에서 메모리 부족이 실제로 보이면 settings.yml 의 `i1.memory` 를 2048 로 되돌린다.

## 메모리가 부족할 때

control plane 을 vm01 한 대로 줄이면 vm02 를 워커 자원으로 낮출 수 있다.
settings.yml 의 `overrides` 에서 vm02 항목을 지우고, inventory 의 `[kube_control_plane]` 에서 vm02 를 뺀다.
합계가 9.5GB → 9GB 가 되고, 무엇보다 control plane 이 하나라 부팅이 빨라진다.
다만 AWS 경로의 inventory 와 달라지므로 **강의 중에는 기본값을 권한다.**

# 노드 추가 실습 (3.k8sNodeManage)

AWS 경로와 절차가 같다. 다른 것은 첫 줄뿐이다.

| 단계 | AWS | 로컬 |
| :--- | :--- | :--- |
| VM 추가 | `vars.tf` 의 `instance_count` 를 4 → `terraform apply` | `settings.yml` 의 `nodes.count` 를 4 → `vagrant up vm04` |
| hosts | `bash doSetHosts.sh` | `bash /vagrant/doSetHosts.sh` |
| inventory | vm04 추가 | `bash /vagrant/doMakeInventory.sh` (또는 손으로 추가) |
| 클러스터 반영 | `ansible-playbook ... cluster.yml` | **동일** |
| 확인 | `kubectl get nodes` | **동일** |

`nodes.count` 를 바꾼 뒤에는 **기존 VM 을 지우지 않는다.** `vagrant up vm04` 만 실행하면 된다.
새로 만든 vm04 의 /etc/hosts 에는 4대가 모두 들어가지만 기존 3대에는 vm04 가 없으므로,
`vagrant provision` 을 한 번 돌려 전 노드의 hosts 를 맞춘다.

```bash
# 호스트에서
vagrant up vm04
vagrant provision          # 전 노드 /etc/hosts 갱신
```

# 문제가 생기면

| 증상 | 확인 |
| :--- | :--- |
| i1 에서 `ssh vm01` 이 암호를 묻는다 | 호스트에서 `vagrant provision vm01` — i1 키를 다시 심는다 |
| `ansible ping` 이 실패한다 | i1 에서 `bash /vagrant/doVerify.sh` — 어느 단계에서 끊기는지 나온다 |
| 노드가 전부 10.0.2.15 로 보인다 | inventory 에 `ip=` 가 빠졌다. `doMakeInventory.sh` 로 다시 만든다 |
| `/vagrant` 가 비어 있다 | 공유 폴더 미마운트. `vagrant reload` 후 재시도 |
| cluster.yml 이 중간에 멈춘다 | i1 에서 `rm -rf /tmp/ansible_facts* ~/.ansible/tmp/*` 후 재실행 (AWS README 3.1 절과 동일) |
