# Lab1. 사전 실습 환경 세팅
실습 환경은 두 갈래다. **둘 다 Kubespray 로 설치하며 명령도 거의 같다.**

## AWS 경로 (기본)
| Folder                                                         | Contents                                                    |
| -------------------------------------------------------------- | ----------------------------------------------------------- |
| [1.InstanceForTerraform](1.InstanceForTerraform)         | 실습용 Terraform Instance(i1) 구성                          |
| [2.Create_IAM_Key](2.Create_IAM_Key)                     | IAM Key생성                                                 |
| [3.InstanceForKubernetes](3.InstanceForKubernetes)       | Terraform으로 K8s용으로 사용할 Instance 생성 + Kubespray 설치 |

## 로컬 PC 경로 (AWS 계정이 없을 때)
| Folder                                                         | Contents                                                    |
| -------------------------------------------------------------- | ----------------------------------------------------------- |
| [Install_Kubernetes_only_PC.md](Install_Kubernetes_only_PC.md) | **수강생용 단계별 절차서** — Vagrant + Kubespray            |
| [0.VagrantForLocal](0.VagrantForLocal)                   | Vagrant 스크립트·점검 도구. 구성 상세와 AWS 대조표는 [README](0.VagrantForLocal/README.md) |

* Terraform 이 하던 일(인스턴스 생성)을 Vagrant 가 대신하고, **Kubespray 를 실행하는 부분은 AWS 경로와 동일**하다.
* 노드 이름(`i1`·`vm01`~`vm03`)·계정(`ubuntu`)·inventory 역할 배치가 양쪽 같으므로 lab2~lab5 는 구분 없이 진행된다.
* Windows 호스트에는 VirtualBox·Vagrant 만 있으면 된다. Ansible 은 i1 안에서 돈다.


# cf) Lab1 스크립트에 대해.
* 현재 폴더에 있는 스크립트는 강의용 스크립트로써 terraform/AwsCLI/ansible등을 설치하고, 여러 인스턴스를 한번에 Terraform으로 Provisioning하는 스크립트 입니다.
* 기존 Terraform 사용자는 자신의 본 스크립트를 사용하지 않고 본인의 스크립트를 사용하셔도 무방방합니다.
