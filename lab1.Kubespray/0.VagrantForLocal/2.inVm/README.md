---
name: README
description: 중첩(nested) 방식 실습 환경 — VM 한 대 안에 클러스터 전체를 넣는다
date: 2026.08.30
---

# 무엇이 다른가

이웃 폴더([1.vm4](../1.vm4/))는 호스트가 VM 을 **4대** 만든다. 이 폴더는 **1대**만 만들고 나머지를 그 안에서 만든다.

```
[ 1.vm4 ]                          [ 2.inVm ]

Windows                            Windows
└ VirtualBox                       └ VirtualBox
  ├ i1                               └ i1  ← 이 한 대만 배포하면 된다
  ├ vm01                                ├ VirtualBox + Vagrant
  ├ vm02                                └ ├ vm01
  └ vm03                                  ├ vm02
                                          └ vm03
```

**안쪽에서 보는 구조는 이웃 폴더(1.vm4)와 완전히 같다.** 노드명·IP·계정·inventory 가 동일하므로 lab2 이후의 실습 명령을 한 글자도 바꾸지 않고 쓸 수 있다.

# 전제 — 호스트가 중첩 가상화를 지원해야 한다

이것이 성립하지 않으면 이 폴더는 쓸 수 없다. 확인은 30초면 된다.

```bash
# 아무 VM 이나 하나 골라 켠 뒤
VBoxManage modifyvm <VM이름> --nested-hw-virt on
# 그 게스트 안에서
lscpu | grep -i virtualization    # VT-x 또는 AMD-V 가 보여야 한다
ls -la /dev/kvm                   # 이 장치가 있어야 실제로 동작한다
```

jpc1(Intel i7-6700T · Skylake)에서 둘 다 확인했다. 지원하지 않는 호스트라면 이웃 폴더(1.vm4)를 쓴다.

# 자원 요구 — 이쪽이 더 빡빡하다

이웃 폴더(1.vm4)는 호스트가 4대에 나눠 주지만, 여기서는 **VM 한 대에 전부 몰아줘야** 한다.

| | 이웃 폴더(1.vm4) | 이 폴더 |
| :--- | ---: | ---: |
| vm01 · vm02 · vm03 | 8,704MB | 8,704MB |
| i1 | 1,024MB | — (바깥 VM 이 겸함) |
| 바깥 게스트 OS + VirtualBox | — | 2,048MB |
| **VM 에 줘야 할 총량** | **9,728MB** | **10,752MB** |
| 권장 호스트 메모리 | 16GB | **20GB 이상** |

16GB 호스트에서도 돌기는 하나 여유가 거의 없다. 그런 경우 [settings.yml](settings.yml) 의 `outer.memory` 와 `inner` 노드 메모리를 함께 낮춘다.

디스크는 바깥 VM 하나에 안쪽 3대가 전부 들어가므로 **60GB 이상**이 필요하다. box 기본 디스크는 64GB 지만 LVM 이 31GB 만 잡고 있어, 프로비저닝이 전량으로 넓힌다(`outer.expand_lvm`).

# 절차

## 1. 바깥 VM 만들기 — Windows 에서

```bash
cd lab1.Kubespray/0.VagrantForLocal/2.inVm
vagrant up
```

VirtualBox·Vagrant 설치가 포함되어 이웃 폴더(1.vm4)보다 오래 걸린다.

## 2. 안쪽 노드 만들기 — 바깥 VM 안에서

```bash
vagrant ssh                    # ubuntu 계정으로 들어간다
bash /sreMsa/lab1.Kubespray/0.VagrantForLocal/2.inVm/inner/doInner.sh
```

이 스크립트가 키 배치 · box 확보 · `vagrant up` · Kubespray 준비를 한 번에 한다.

## 3. Kubernetes 올리기 — 바깥 VM 안에서

```bash
source ~/ksvenv/bin/activate
cd ~/kubespray
bash /sreMsa/lab1.Kubespray/0.VagrantForLocal/1.vm4/doMakeInventory.sh
ansible-playbook --flush-cache -u ubuntu -b --become --become-user=root \
  -i inventory/inventory.ini --private-key ~/.ssh/id_rsa cluster.yml
```

## 4. 확인

```bash
ssh vm01 "sudo -i kubectl get no"
```

# 반드시 알아야 할 것 두 가지

## `venv` 없이는 `cluster.yml` 이 첫 태스크에서 죽는다

```
TASK [Check 2.16.4 <= Ansible version < 2.17.0]
fatal: "Ansible must be between 2.16.4 and 2.17.0 exclusive - you have 2.17.14"
```

`installOnEc2.sh` 가 깔아 주는 ansible 은 **core 2.17.x** 인데 kubespray `release-2.28` 은 **2.16.x** 를 요구한다. `requirements.txt` 가 `ansible==9.13.0` 을 고정하므로 전용 venv 로 맞춘다 — `doInner.sh` 가 자동으로 만든다.

이것은 이웃 폴더(1.vm4) 방식에도 똑같이 해당한다(2026-08-30 실측).

## Ubuntu 24.04 리포에는 `vagrant` 가 없다

`apt-cache policy vagrant` 가 `Candidate: (none)` 을 답한다. 그래서 `outer.sh` 가 HashiCorp apt 저장소를 등록한 뒤 설치한다. 폐쇄망이라면 [settings.yml](settings.yml) 의 `tools.vagrant_from` 을 `deb_url` 로 바꾸고 `vagrant_deb_url` 에 사내 미러 주소를 넣는다.

# 파일

| 파일 | 실행 위치 | 하는 일 |
| :--- | :--- | :--- |
| [settings.yml](settings.yml) | — | 바깥·안쪽 자원. **고칠 파일은 이것 하나뿐이다** |
| [Vagrantfile](Vagrantfile) | Windows | 바깥 VM 한 대를 만든다 (`--nested-hw-virt on`) |
| [scripts/outer.sh](scripts/outer.sh) | 바깥 VM | LVM 확장 · VirtualBox · Vagrant · 계정 · Kubespray 도구 |
| [inner/doInner.sh](inner/doInner.sh) | 바깥 VM | 안쪽 노드 생성 진입점 |
| [inner/Vagrantfile](inner/Vagrantfile) | 바깥 VM | vm01~vm0N 정의 |

안쪽 노드의 프로비저닝은 이웃 폴더(1.vm4)의 [scripts/common.sh](../1.vm4/scripts/common.sh)·[scripts/node.sh](../1.vm4/scripts/node.sh) 를 **그대로 쓴다.** 복제하지 않으므로 이웃 폴더(1.vm4)를 고치면 이쪽에도 반영된다.

# 어느 쪽을 쓸 것인가

| | 이웃 폴더(1.vm4) | 이 폴더 |
| :--- | :--- | :--- |
| 배포 단위 | VM 4대 | **VM 1대** |
| 호스트 메모리 | 16GB | 20GB 권장 |
| 중첩 가상화 | 불필요 | **필수** |
| 성능 | 기준 | 느리다 |
| 검증 상태 | `cluster.yml` 완주 확인 | 🚧 검증 중 |

수강생 배포를 VM 하나로 끝내야 하는 상황이 아니라면 이웃 폴더(1.vm4)가 안전하다.
