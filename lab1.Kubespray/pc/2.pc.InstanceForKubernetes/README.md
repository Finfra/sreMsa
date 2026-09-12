---
name: README
description: 로컬 경로의 클러스터 구성 스크립트 — i1 안에서 inventory·hosts·검증을 처리한다
date: 2026.09.12
---

# 여기서 하는 일

VM 은 [1.pc.byVagrant](../1.pc.byVagrant/) 에서 이미 만들었다. 이 폴더에서는 **Kubespray 를 돌릴 수 있는 상태로 맞춘다.**

| 순서  | 하는 일                                |
| :---: | :------------------------------------- |
| **1** | 노드 이름을 `/etc/hosts` 에 넣는다     |
| **2** | Kubespray inventory 를 만든다          |
| **3** | 24개 항목으로 준비가 끝났는지 점검한다 |

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
/sreMsa/lab1.Kubespray/pc/2.pc.InstanceForKubernetes
```

# 스크립트

| 파일                                     | 무엇을 하나                                                                              |
| :--------------------------------------- | :--------------------------------------------------------------------------------------- |
| [doSetHosts.sh](doSetHosts.sh)           | `/etc/hosts` 에 `vm01`~`vm03` 이름을 넣는다. Vagrant 가 만든 `hosts.generated` 를 읽는다 |
| [doMakeInventory.sh](doMakeInventory.sh) | Kubespray inventory 를 만든다. 각 노드에 `ip=` 를 넣는 것이 핵심이다                     |
| [doVerify.sh](doVerify.sh)               | 24개 항목으로 환경을 점검한다. `cluster.yml` 전에 한 번 돌린다                           |

## 실행 순서

```bash
BASE=/sreMsa/lab1.Kubespray/pc/2.pc.InstanceForKubernetes

bash $BASE/doSetHosts.sh        # 1) 이름 해석
bash $BASE/doMakeInventory.sh   # 2) inventory 생성
bash $BASE/doVerify.sh          # 3) 점검
```

* 확인 : 마지막 점검에서 **실패가 0** 이면 준비가 끝난 것이다.

```
==============================================
 통과 24 · 실패 0
==============================================
 모두 통과. Kubespray 를 진행해도 된다.
```

실패가 있으면 그 항목이 `[FAIL]` 로 표시되고 이유가 함께 나온다. 그 줄을 보고 해당 단계를 다시 실행한다.
`ansible ping` 에서 막히면 [1.pc.byVagrant/README.md](../1.pc.byVagrant/README.md) 의 "자주 막히는 곳" 을 본다.

# ⚠️ 가장 자주 걸리는 곳 — inventory 의 `ip=`

VirtualBox VM 은 네트워크 카드가 두 장이고, 그중 첫 번째(NAT)의 주소가 **모든 VM 에서 `10.0.2.15` 로 같다.**
`ip=` 를 주지 않으면 Kubespray 가 세 노드를 한 대로 인식해 클러스터가 만들어지지 않는다.

`doMakeInventory.sh` 가 이것을 자동으로 넣어 주므로 **그 스크립트를 쓰면 걸릴 일이 없다.**
손으로 inventory 를 고쳤다면 각 줄에 `ip=` 가 있는지 확인한다.

# 다음 단계

점검이 통과하면 [1.pc.byVagrant/README.md](../1.pc.byVagrant/README.md) 의 Kubespray 실행 절로 간다.
