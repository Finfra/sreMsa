---
name: README
description: 로컬 경로의 클러스터 구성 스크립트 — i1 안에서 inventory·hosts·검증을 처리한다
date: 2026.09.12
---

# 이 폴더는 무엇인가

AWS 경로의 [3.aws.InstanceForKubernetes](../../aws/3.aws.InstanceForKubernetes/) 에 대응하는 **로컬판**이다.
노드를 만드는 일은 [1.pc.byVagrant](../1.pc.byVagrant/) 가 이미 끝냈고, 여기서는 **Kubespray 를 돌릴 수 있는 상태로 다듬는다.**

| 경로     | 인스턴스를 만드는 것       | 클러스터를 구성하는 것                  |
| :------- | :------------------------- | :-------------------------------------- |
| AWS      | Terraform (`*.tf`)         | `3.aws.InstanceForKubernetes` 의 절차서 |
| 로컬(PC) | Vagrant (`1.pc.byVagrant`) | **이 폴더**                             |

# ⚠️ 실행 위치 — 전부 i1 **안에서** 돈다

세 스크립트 모두 호스트(Windows)가 아니라 **i1 안에서 `ubuntu` 계정으로** 실행한다.
호스트에서 실행하면 노드에 접근할 수 없어 의미가 없다.

```powershell
# 호스트에서 i1 로 들어간 뒤
cd lab1.Kubespray\pc\1.pc.byVagrant
.\doSsh.ps1 i1
```

repo 는 i1 안에서 `/sreMsa` 로 마운트되어 있으므로 이 폴더의 경로는 아래가 된다.

```
/sreMsa/lab1.Kubespray/pc/3.pc.InstanceForKubernetes
```

# 스크립트

| 파일                                     | 무엇을 하나                                                                              |
| :--------------------------------------- | :--------------------------------------------------------------------------------------- |
| [doSetHosts.sh](doSetHosts.sh)           | `/etc/hosts` 에 `vm01`~`vm03` 이름을 넣는다. Vagrant 가 만든 `hosts.generated` 를 읽는다 |
| [doMakeInventory.sh](doMakeInventory.sh) | Kubespray inventory 를 만든다. 각 노드에 `ip=` 를 넣는 것이 핵심이다                     |
| [doVerify.sh](doVerify.sh)               | 24개 항목으로 환경을 점검한다. `cluster.yml` 전에 한 번 돌린다                           |

## 실행 순서

```bash
BASE=/sreMsa/lab1.Kubespray/pc/3.pc.InstanceForKubernetes

bash $BASE/doSetHosts.sh        # 1) 이름 해석
bash $BASE/doMakeInventory.sh   # 2) inventory 생성
bash $BASE/doVerify.sh          # 3) 점검 — 24/24 면 준비 완료
```

`doSetHosts.sh` 가 읽는 `hosts.generated` 는 Vagrant 가 **`1.pc.byVagrant` 폴더에** 만들고, 그 폴더가 i1 안에서 `/vagrant` 로 보인다. 그래서 스크립트는 이 폴더에 있으면서도 `/vagrant/hosts.generated` 를 참조한다.

# AWS 경로와 다른 점

| 항목      | AWS                         | 로컬                                    |
| :-------- | :-------------------------- | :-------------------------------------- |
| 노드 생성 | `terraform apply`           | `vagrant up` (1.pc.byVagrant)           |
| hosts     | `doSetHosts.sh` (같은 폴더) | `doSetHosts.sh` (이 폴더) — 내용도 같다 |
| inventory | Kubespray 샘플 복사 후 편집 | `doMakeInventory.sh` 가 `ip=` 까지 생성 |

inventory 에 `ip=` 를 넣는 것이 **로컬 경로에서 가장 자주 걸리는 지점**이다. NAT 때문에 노드가 전부 `10.0.2.15` 로 보이므로, 이것을 넣지 않으면 Kubespray 가 세 노드를 한 대로 인식한다. 자세한 근거는 [1.pc.byVagrant/README.md](../1.pc.byVagrant/README.md) 의 "AWS 경로와의 대조" 절에 있다.

# 다음 단계

점검이 통과하면 [1.pc.byVagrant/README.md](../1.pc.byVagrant/README.md) 의 Kubespray 실행 절로 간다.
