# Lab1. 사전 실습 환경 세팅
| Folder                                                         | Contents                                                    |
| -------------------------------------------------------------- | ----------------------------------------------------------- |
| [Lab1.InstanceForTerraform](Lab1.InstanceForTerraform)         | 실습용 Terraform Instance 구성                              |
| [Lab2.Create_IAM_Key](Lab2.Create_IAM_Key)                     | IAM Key생성                                                 |
| [Lab3.InstanceForKubernetes](Lab3.InstanceForKubernetes)       | Terraform으로 K8s용으로 사용할 Instance 생성                |
| [Install_Kubernetes_only_PC.md](Install_Kubernetes_only_PC.md) | 클라우드 없이 Vagrant+Virtualbox로 Kubernetes 클러스터 설치 |


# cf) Lab1 스크립트에 대해.
* 현재 폴더에 있는 스크립트는 강의용 스크립트로써 terraform/AwsCLI/ansible등을 설치하고, 여러 인스턴스를 한번에 Terraform으로 Provisioning하는 스크립트 입니다.
* 기존 Terraform 사용자는 자신의 본 스크립트를 사용하지 않고 본인의 스크립트를 사용하셔도 무방방합니다.
