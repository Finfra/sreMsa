# Lab1. 사전 실습 환경 세팅

실습 환경은 두 갈래다. **둘 다 Kubespray 로 설치하며 명령도 거의 같다.**
고른 쪽의 폴더로 들어가면 그 안에 진입점 문서가 있다.

| 폴더                 | 언제 쓰나                                   |
| -------------------- | ------------------------------------------- |
| [pc](pc/README.md)   | 로컬 PC 에서 실습할 때 (AWS 계정이 없을 때) |
| [aws](aws/README.md) | AWS 계정으로 실습할 때                      |

## 로컬 PC 경로 — [pc](pc/README.md)

| 순서  | 문서                                                                             | 무엇을 하나                                             |
| :---: | :------------------------------------------------------------------------------- | :------------------------------------------------------ |
| **①** | [pc/0.pc_setting/README.md](pc/0.pc_setting/README.md)     | 기본 설치 — 프로그램·Windows 설정·소스 내려받기 (0~1장) |
| **②** | [pc/1.pc.byVagrant/README.md](pc/1.pc.byVagrant/README.md) | 단계별 절차서 — VM 만들기부터 Kubespray 까지 (2장~)     |

* ①은 강사 배포 폴더 `_prgs` 안에도 같은 내용으로 동봉된다.
* ①②가 참조하는 상세 폴더는 둘이다 — `1.pc.byVagrant`(VM 생성, 호스트에서) · `3.pc.InstanceForKubernetes`(inventory·점검, i1 안에서).
  AWS 의 `2.aws.Create_IAM_Key` 는 자격증명 발급이라 로컬에 대응물이 없어 **번호 2를 비워 두었다.**
* **수업은 `1.pc.byVagrant` 로 진행한다.** VM 1대 안에 전부 넣는 `cf_inVm` 은 참고용이며, 고르는 기준은 [pc/README.md](pc/README.md) 에 있다.
* Windows 호스트에는 VirtualBox·Vagrant 만 있으면 된다. Ansible 은 i1 안에서 돈다.

## AWS 경로 — [aws](aws/README.md)

| 순서  | 문서                                                                                 | 무엇을 하나                                                |
| :---: | :----------------------------------------------------------------------------------- | :--------------------------------------------------------- |
| **①** | [aws/0.pc_setting/1.Install_app_on_aws.md](aws/0.pc_setting/1.Install_app_on_aws.md) | 환경 준비 — AWS 계정·IAM 키·콘솔 서버(i1) 생성과 도구 설치 |
| **②** | [aws/0.pc_setting/2.Install_k8s_on_aws.md](aws/0.pc_setting/2.Install_k8s_on_aws.md) | Kubernetes 설치 — Terraform 으로 노드 생성 + Kubespray     |

* ①②가 참조하는 상세 절차서 3종(`1.aws.byTerraform`·`2.aws.Create_IAM_Key`·`3.aws.InstanceForKubernetes`)의
  역할과 호출 관계는 [aws/README.md](aws/README.md) 에 있다.
* ⚠️ **폴더 번호와 진행 순서가 다르다** — 키가 없으면 Terraform 이 아무것도 못 만들므로
  `2.aws.Create_IAM_Key` 를 `1.aws.byTerraform` 보다 **먼저** 한다. ①이 그 순서로 안내한다.

## 두 경로의 공통점

* Terraform 이 하던 일(인스턴스 생성)을 Vagrant 가 대신할 뿐, **Kubespray 를 실행하는 부분은 같다.**
* 노드 이름(`i1`·`vm01`~`vm03`)·계정(`ubuntu`)·inventory 역할 배치가 양쪽 같으므로 **lab2~lab5 는 구분 없이 진행된다.**

# cf) Lab1 스크립트에 대해.
* 현재 폴더에 있는 스크립트는 강의용 스크립트로써 terraform/AwsCLI/ansible등을 설치하고, 여러 인스턴스를 한번에 Terraform으로 Provisioning하는 스크립트 입니다.
* 기존 Terraform 사용자는 자신의 본 스크립트를 사용하지 않고 본인의 스크립트를 사용하셔도 무방방합니다.
