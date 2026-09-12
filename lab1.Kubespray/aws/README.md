---
name: README
description: AWS 갈래 이정표 — 어느 문서부터 읽는지만 알린다
date: 2026.09.12
---

# 여기서 시작한다

**[0.pc_setting/README.md](0.pc_setting/README.md) 를 연다.** 내 PC 설정부터 Kubernetes 설치까지 그 문서 하나로 이어진다.

나머지 폴더는 진입점이 필요한 대목에서 불러 쓰는 **상세 절차서**다. 직접 열어서 시작하지 않는다.

| 폴더                                                        | 무엇이 들어 있나                                        |
| :---------------------------------------------------------- | :------------------------------------------------------ |
| [0.pc_setting](0.pc_setting/)                               | **진입점** — 내 PC 설치 · AWS 계정·키 · Kubernetes 설치 |
| [1.aws.byTerraform](1.aws.byTerraform/)                     | 콘솔 서버 `i1` 생성 · Terraform·Ansible·AWS CLI 설치    |
| [2.aws.Create_IAM_Key](2.aws.Create_IAM_Key/)               | IAM 사용자와 액세스 키 발급                             |
| [3.aws.InstanceForKubernetes](3.aws.InstanceForKubernetes/) | K8s 노드 3대 Terraform 생성 + Kubespray 실행            |

* 폴더 번호는 붙은 순서일 뿐 **진행 순서가 아니다.** 진입점을 따라가면 이 차이를 신경 쓸 일이 없다.
* AWS 계정이 없으면 이 갈래 대신 [pc](../pc/README.md) 로 간다.
