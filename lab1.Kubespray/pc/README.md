---
name: README
description: 로컬(PC) Kubespray 실습 환경 — 두 가지 구현 중 하나를 고른다
date: 2026.08.31
---

# 두 가지 구현

같은 클러스터를 만드는 방법이 둘이다. **대부분은 [1.pc.byVagrant](1.pc.byVagrant/) 를 쓴다.**

```
[ 1.pc.byVagrant ]  호스트가 VM 4대를 직접        [ cf_inVm ]  VM 1대 안에 전부

Windows                                   Windows
└ VirtualBox                              └ VirtualBox
  ├ i1                                      └ i1  ← 이 한 대만 배포하면 된다
  ├ vm01                                       ├ VirtualBox + Vagrant
  ├ vm02                                       └ ├ vm01
  └ vm03                                         ├ vm02
                                                 └ vm03
```

**안쪽에서 보는 구조는 둘이 같다.** 노드명·IP·계정·inventory 가 동일하므로 lab2 이후의 실습 명령은 어느 쪽을 쓰든 바뀌지 않는다.

# 폴더 구성

AWS 경로와 같은 번호 체계다. 진입점 문서 둘이 이 폴더 직하에 있고, 번호 폴더가 그 상세를 담는다.

| 폴더·파일                                                                            | 무엇인가                                                                      |
| :----------------------------------------------------------------------------------- | :---------------------------------------------------------------------------- |
| [0.pc_setting/README.md](0.pc_setting/README.md)                                     | **① 기본 설치** — 프로그램·Windows 설정·소스 내려받기                         |
| [1.pc.byVagrant/README.md](1.pc.byVagrant/README.md)                                 | **② 단계별 절차서** — VM 만들기부터 Kubespray 까지                            |
| [1.pc.byVagrant](1.pc.byVagrant/)                                                    | VM 4대 생성·프로비저닝. **호스트(Windows)에서** 실행                          |
| [2.pc.InstanceForKubernetes](2.pc.InstanceForKubernetes/)                            | inventory·hosts·점검. **i1 안에서** 실행                                      |
| [0.pc_setting/cf_install_DockerDesktop.md](0.pc_setting/cf_install_DockerDesktop.md) | 참고 — Windows 에 WSL2·Docker Desktop 이 필요할 때. **실습과 동시 사용 불가** |
| [cf_inVm](cf_inVm/)                                                                  | 참고용 — VM 1대 안에 전부 넣는 중첩 방식                                      |

* **AWS 경로의 `2.aws.Create_IAM_Key` 에 해당하는 것이 없다.** 자격증명이 필요 없는 로컬 환경이라 폴더가 둘뿐이다.
* 번호는 AWS 경로와 **역할이 대응**하도록 붙였다 — `1.*` 이 인스턴스를 만들고 `3.*` 이 클러스터를 구성한다.

# 어느 쪽을 고를 것인가

|                        | [1.pc.byVagrant](1.pc.byVagrant/) | [0.pc_setting/cf_install_DockerDesktop.md](0.pc_setting/cf_install_DockerDesktop.md) | 참고 — Windows 에 WSL2·Docker Desktop 이 필요할 때. **실습과 동시 사용 불가** |
| [cf_inVm](cf_inVm/) |
| :--------------------- | :-------------------------------- | :------------------ |
| 배포 단위              | VM 4대                            | **VM 1대**          |
| 호스트 메모리          | **16GB**                          | 24GB 권장           |
| 중첩 가상화(VT-x 전달) | 불필요                            | **필수**            |
| 속도                   | 기준                              | 느리다              |
| 검증 상태              | 검증 완료                         | 검증 완료           |

**수강생 배포를 VM 하나로 끝내야 하는 상황이 아니라면 [1.pc.byVagrant](1.pc.byVagrant/) 가 안전하다.** 16GB PC 에서 실측으로 전 과정을 통과한 경로이며, 수강생용 단계별 절차인 [1.pc.byVagrant/README.md](1.pc.byVagrant/README.md) 도 이 폴더를 기준으로 쓰여 있다.

## cf_inVm 을 고려할 때 확인할 것

호스트 CPU 가 게스트에 VT-x 를 넘겨 줄 수 있어야 한다. 확인은 30초면 된다.

호스트(Windows)에서 아무 VM 이나 하나 골라 중첩을 켠다.

```powershell
VBoxManage modifyvm <VM이름> --nested-hw-virt on
```

그 VM 을 켜고 **게스트 안에서** 확인한다.

```bash
lscpu | grep -i virtualization    # VT-x 또는 AMD-V 가 보여야 한다
ls -la /dev/kvm                   # 이 장치가 있어야 실제로 동작한다
```

# 공통 사항

## 두 폴더가 나눠 쓰는 것

[cf_inVm](cf_inVm/) 의 안쪽 노드는 [1.pc.byVagrant/scripts/common.sh](1.pc.byVagrant/scripts/common.sh)·[node.sh](1.pc.byVagrant/scripts/node.sh) 를 **그대로 쓴다.** 복제하지 않으므로 한쪽을 고치면 양쪽에 반영된다.

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

[cf_inVm](cf_inVm/) 은 [doInner.sh](cf_inVm/inner/doInner.sh) 가 이 venv 를 자동으로 만든다.
[1.pc.byVagrant](1.pc.byVagrant/) 는 수강생이 직접 만든다 — 절차는 [1.pc.byVagrant/README.md](1.pc.byVagrant/README.md) 9.1 절에 있다.

⚠️ venv 는 **터미널마다** 켜야 한다. i1 에 다시 접속했다면 `cluster.yml` 전에 `source ~/ksvenv/bin/activate` 를 한 번 더 실행한다.

## motd 를 꺼 두었다

Ubuntu 의 동적 motd 8개가 로그인마다 약 30초를 먹고, `pam_motd` 는 **비대화형 ssh 에도** 걸려 ansible 이 노드에 붙을 때마다 그 비용을 낸다. [common.sh](1.pc.byVagrant/scripts/common.sh) 가 전 노드에서 이를 끈다 — 실측 **30초 → 0.3초**.
