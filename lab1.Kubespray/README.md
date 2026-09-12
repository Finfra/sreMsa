# Lab1. 사전 실습 환경 세팅

실습 환경은 두 갈래다. **둘 다 Kubespray 로 설치하며 명령도 거의 같다.**
고른 쪽의 폴더로 들어가면 그 안에 진입점 문서가 있다.

| 폴더            | 언제 쓰나                                   |
| --------------- | ------------------------------------------- |
| [pc](pc)        | 로컬 PC 에서 실습할 때 (AWS 계정이 없을 때) |
| [aws](aws)      | AWS 계정으로 실습할 때                      |

## 로컬 PC 경로 — [pc](pc)

| 항목                                                      | 내용                                                                                        |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| [pc/1.install_APP_on_PC.md](pc/1.install_APP_on_PC.md)    | **① 기본 설치** — 프로그램·Windows 설정·소스 내려받기 (0~1장). `_prgs` 폴더에도 동봉        |
| [pc/2.Install_k8s_on_PC.md](pc/2.Install_k8s_on_PC.md)    | **② 단계별 절차서** — VM 만들기부터 Kubespray 까지 (2장~)                                   |
| [pc/vm_x_4](pc/vm_x_4)                                    | 구현 A — 호스트가 VM 4대를 직접 만든다. **기본이며 대부분 이쪽을 쓴다**                     |
| [pc/inVm](pc/inVm)                                        | 구현 B — VM 1대 안에 전부 넣는 중첩 방식. 배포를 VM 하나로 끝내야 할 때만                   |

* 구현 A·B 를 고르는 기준은 [pc/README.md](pc/README.md) 에 있다.
* Terraform 이 하던 일(인스턴스 생성)을 Vagrant 가 대신하고, **Kubespray 를 실행하는 부분은 AWS 경로와 동일**하다.
* 노드 이름(`i1`·`vm01`~`vm03`)·계정(`ubuntu`)·inventory 역할 배치가 양쪽 같으므로 lab2~lab5 는 구분 없이 진행된다.
* Windows 호스트에는 VirtualBox·Vagrant 만 있으면 된다. Ansible 은 i1 안에서 돈다.

## AWS 경로 — [aws](aws)

| 항목                                                                                       | 내용                                                                     |
| -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| [aws/1.aws.byTerraform/1.Install_app_on_aws.md](aws/1.aws.byTerraform/1.Install_app_on_aws.md) | **① 환경 준비** — AWS 계정·IAM 키·콘솔 서버(i1) 생성과 도구 설치         |
| [aws/1.aws.byTerraform/2.Install_k8s_on_aws.md](aws/1.aws.byTerraform/2.Install_k8s_on_aws.md) | **② Kubernetes 설치** — Terraform 으로 노드 생성 + Kubespray             |
| [aws/1.aws.byTerraform](aws/1.aws.byTerraform)                                                 | 실습용 Terraform Instance(i1) 구성 (①이 참조)                            |
| [aws/2.aws.Create_IAM_Key](aws/2.aws.Create_IAM_Key)                                           | IAM Key 생성 (①이 참조)                                                  |
| [aws/3.aws.InstanceForKubernetes](aws/3.aws.InstanceForKubernetes)                             | Terraform으로 K8s용으로 사용할 Instance 생성 + Kubespray 설치 (②가 참조) |

* **①②가 진입점**이고 나머지는 그 안에서 참조하는 상세 절차다.
* ⚠️ **폴더 번호와 진행 순서가 다르다** — 키가 없으면 Terraform 이 아무것도 못 만들므로
  `2.aws.Create_IAM_Key` 를 `1.aws.byTerraform` 보다 **먼저** 한다. ①이 그 순서로 안내한다.

# cf) Lab1 스크립트에 대해.
* 현재 폴더에 있는 스크립트는 강의용 스크립트로써 terraform/AwsCLI/ansible등을 설치하고, 여러 인스턴스를 한번에 Terraform으로 Provisioning하는 스크립트 입니다.
* 기존 Terraform 사용자는 자신의 본 스크립트를 사용하지 않고 본인의 스크립트를 사용하셔도 무방방합니다.
