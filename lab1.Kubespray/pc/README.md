---
name: README
description: 로컬 PC 갈래 이정표 — 어느 문서부터 읽는지만 알린다
date: 2026.09.12
---

# 여기서 시작한다

**[0.pc_setting/README.md](0.pc_setting/README.md) 를 연다.** 프로그램 설치부터 소스 준비까지 그 문서가 다루고, 이어서 [1.pc.byVagrant/README.md](1.pc.byVagrant/README.md) 가 VM 만들기부터 Kubernetes 설치까지 이어 간다.

나머지 폴더는 진입점이 필요한 대목에서 불러 쓰는 **상세 절차서**다. 직접 열어서 시작하지 않는다.

| 폴더                                                      | 무엇이 들어 있나                                                   |
| :-------------------------------------------------------- | :----------------------------------------------------------------- |
| [0.pc_setting](0.pc_setting/)                             | **진입점** — 프로그램 설치 · Windows 설정 · 소스 준비              |
| [1.pc.byVagrant](1.pc.byVagrant/)                         | VM 4대 생성·프로비저닝 + 2~12장 절차. **호스트(Windows)에서** 실행 |
| [2.pc.InstanceForKubernetes](2.pc.InstanceForKubernetes/) | inventory·hosts·점검. **i1 안에서** 실행                           |
| [cf_inVm](cf_inVm/)                                       | 참고 — VM 1대 안에 전부 넣는 중첩 방식                             |

* AWS 갈래의 `2.aws.Create_IAM_Key` 에 해당하는 것이 없다. 자격증명이 필요 없는 로컬 환경이다.
* 수업은 **`1.pc.byVagrant`** 로 진행한다. `cf_inVm` 은 VM 하나로 배포해야 할 때를 위한 참고 구현이며, 고르는 기준은 [cf_inVm/README.md](cf_inVm/README.md) 에 있다.
* AWS 계정으로 실습하려면 이 갈래 대신 [aws](../aws/README.md) 로 간다.
