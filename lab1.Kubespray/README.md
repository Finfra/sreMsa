# Lab1. 사전 실습 환경 세팅
실습 환경은 두 갈래다. **둘 다 Kubespray 로 설치하며 명령도 거의 같다.**

## AWS 경로 (기본)
| Folder                                             | Contents                                                                 |
| -------------------------------------------------- | ------------------------------------------------------------------------ |
| [1.Install_app_on_aws.md](1.Install_app_on_aws.md) | **① 환경 준비** — AWS 계정·IAM 키·콘솔 서버(i1) 생성과 도구 설치         |
| [2.Install_k8s_on_aws.md](2.Install_k8s_on_aws.md) | **② Kubernetes 설치** — Terraform 으로 노드 생성 + Kubespray             |
| [2.Create_IAM_Key](2.Create_IAM_Key)               | IAM Key생성 (①이 참조)                                                   |
| [1.InstanceForTerraform](1.InstanceForTerraform)   | 실습용 Terraform Instance(i1) 구성 (①이 참조)                            |
| [3.InstanceForKubernetes](3.InstanceForKubernetes) | Terraform으로 K8s용으로 사용할 Instance 생성 + Kubespray 설치 (②가 참조) |

* **①②가 진입점**이고 나머지 셋은 그 안에서 참조하는 상세 절차다.
* ⚠️ **폴더 번호와 진행 순서가 다르다** — 키가 없으면 Terraform 이 아무것도 못 만들므로
  `2.Create_IAM_Key` 를 `1.InstanceForTerraform` 보다 **먼저** 한다. ①이 그 순서로 안내한다.

## 로컬 PC 경로 (AWS 계정이 없을 때)
| Folder                                           | Contents                                                                                                                                                                                |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [1.install_APP_on_PC.md](1.install_APP_on_PC.md) | **① 기본 설치** — 프로그램·Windows 설정·소스 내려받기 (0~1장). `_prgs` 폴더에도 동봉                                                                                                    |
| [2.Install_k8s_on_PC.md](2.Install_k8s_on_PC.md) | **② 단계별 절차서** — VM 만들기부터 Kubespray 까지 (2장~)                                                                                                                               |
| [0.VagrantForLocal](0.VagrantForLocal)           | 로컬(PC) 실습 환경. 구현 두 가지 — [1.vm4](0.VagrantForLocal/1.vm4)(VM 4대·기본) · [2.inVm](0.VagrantForLocal/2.inVm)(VM 1대·중첩). 고르는 기준은 [README](0.VagrantForLocal/README.md) |

* Terraform 이 하던 일(인스턴스 생성)을 Vagrant 가 대신하고, **Kubespray 를 실행하는 부분은 AWS 경로와 동일**하다.
* 노드 이름(`i1`·`vm01`~`vm03`)·계정(`ubuntu`)·inventory 역할 배치가 양쪽 같으므로 lab2~lab5 는 구분 없이 진행된다.
* Windows 호스트에는 VirtualBox·Vagrant 만 있으면 된다. Ansible 은 i1 안에서 돈다.


# cf) Lab1 스크립트에 대해.
* 현재 폴더에 있는 스크립트는 강의용 스크립트로써 terraform/AwsCLI/ansible등을 설치하고, 여러 인스턴스를 한번에 Terraform으로 Provisioning하는 스크립트 입니다.
* 기존 Terraform 사용자는 자신의 본 스크립트를 사용하지 않고 본인의 스크립트를 사용하셔도 무방방합니다.
