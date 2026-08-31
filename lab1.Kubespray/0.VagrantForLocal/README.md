---
name: README
description: 로컬(PC) Kubespray 실습 환경 — 두 가지 구현 중 하나를 고른다
date: 2026.08.31
---

# 두 가지 구현

같은 클러스터를 만드는 방법이 둘이다. **대부분은 [1.vm4](1.vm4/) 를 쓴다.**

```
[ 1.vm4 ]  호스트가 VM 4대를 직접        [ 2.inVm ]  VM 1대 안에 전부

Windows                                   Windows
└ VirtualBox                              └ VirtualBox
  ├ i1                                      └ i1  ← 이 한 대만 배포하면 된다
  ├ vm01                                       ├ VirtualBox + Vagrant
  ├ vm02                                       └ ├ vm01
  └ vm03                                         ├ vm02
                                                 └ vm03
```

**안쪽에서 보는 구조는 둘이 같다.** 노드명·IP·계정·inventory 가 동일하므로 lab2 이후의 실습 명령은 어느 쪽을 쓰든 바뀌지 않는다.

# 어느 쪽을 고를 것인가

| | [1.vm4](1.vm4/) | [2.inVm](2.inVm/) |
| :--- | :--- | :--- |
| 배포 단위 | VM 4대 | **VM 1대** |
| 호스트 메모리 | **16GB** | 24GB 권장 |
| 중첩 가상화(VT-x 전달) | 불필요 | **필수** |
| 속도 | 기준 | 느리다 |
| 검증 상태 | ✅ `cluster.yml` 완주 2회 확인 | 🚧 검증 중 |

**수강생 배포를 VM 하나로 끝내야 하는 상황이 아니라면 [1.vm4](1.vm4/) 가 안전하다.** 16GB PC 에서 실측으로 전 과정을 통과한 경로이며, 수강생용 단계별 절차인 [Install_Kubernetes_only_PC.md](../Install_Kubernetes_only_PC.md) 도 이 폴더를 기준으로 쓰여 있다.

## 2.inVm 을 고려할 때 확인할 것

호스트 CPU 가 게스트에 VT-x 를 넘겨 줄 수 있어야 한다. 확인은 30초면 된다.

```bash
VBoxManage modifyvm <VM이름> --nested-hw-virt on
# 그 게스트 안에서
lscpu | grep -i virtualization    # VT-x 또는 AMD-V 가 보여야 한다
ls -la /dev/kvm                   # 이 장치가 있어야 실제로 동작한다
```

# 공통 사항

## 두 폴더가 나눠 쓰는 것

[2.inVm](2.inVm/) 의 안쪽 노드는 [1.vm4/scripts/common.sh](1.vm4/scripts/common.sh)·[node.sh](1.vm4/scripts/node.sh) 를 **그대로 쓴다.** 복제하지 않으므로 한쪽을 고치면 양쪽에 반영된다.

`.gitignore` 도 이 폴더에 하나만 두어 두 구현의 산출물(`.vagrant/`·`.keys/`·`hosts.generated`)을 함께 걸러 낸다.

## Kubespray 는 venv 가 필요하다

⚠️ 어느 쪽을 쓰든 해당한다. `installOnEc2.sh` 가 설치하는 ansible 은 **core 2.17.x** 인데 kubespray `release-2.28` 은 **2.16.4 ≤ x < 2.17.0** 을 요구해, 그대로 두면 `cluster.yml` 이 첫 태스크에서 거부당한다.

```
TASK [Check 2.16.4 <= Ansible version < 2.17.0]
fatal: "Ansible must be between 2.16.4 and 2.17.0 exclusive - you have 2.17.14"
```

```bash
python3 -m venv ~/ksvenv
source ~/ksvenv/bin/activate
pip install -U pip
pip install -r ~/kubespray/requirements.txt   # ansible 9.13.0 = core 2.16.19
```

[2.inVm](2.inVm/) 은 [doInner.sh](2.inVm/inner/doInner.sh) 가 이 venv 를 자동으로 만든다.

## motd 를 꺼 두었다

Ubuntu 의 동적 motd 8개가 로그인마다 약 30초를 먹고, `pam_motd` 는 **비대화형 ssh 에도** 걸려 ansible 이 노드에 붙을 때마다 그 비용을 낸다. [common.sh](1.vm4/scripts/common.sh) 가 전 노드에서 이를 끈다 — 실측 **30초 → 0.3초**.
