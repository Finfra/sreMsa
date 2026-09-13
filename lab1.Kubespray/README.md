# Lab1. 사전 실습 환경 세팅 (2일차)

**2일차에 Kubernetes 클러스터를 만드는 단원**이다. 1일차 Docker 실습은 [lab0.Docker](../lab0.Docker/README.md) 가 다룬다.

실습 환경은 두 갈래다. **둘 다 Kubespray 로 설치하며 명령도 거의 같다.**
고른 쪽의 폴더로 들어가면 그 안에 진입점 문서가 있다.

| 폴더                 | 언제 쓰나                                        |
| -------------------- | ------------------------------------------------ |
| [pc](pc/README.md)   | 로컬 PC 에서 실습할 때 — **이번 수업은 이 방식** |
| [aws](aws/README.md) | AWS 계정으로 실습할 때                           |

> ⚠️ **1일차에 Docker Desktop 을 설치했다면 Hyper-V 를 먼저 꺼야 한다.** 켜져 있으면 VirtualBox 가 VM 을 띄우지 못한다 —
> 절차는 [lab0.Docker](../lab0.Docker/README.md) 의 **"2일차 전에 반드시"** 절에 있다.

## 로컬 PC 경로 — [pc](pc/README.md)

| 순서  | 문서                                                       | 무엇을 하나                                             |
| :---: | :--------------------------------------------------------- | :------------------------------------------------------ |
| **①** | [pc/0.pc_setting/README.md](pc/0.pc_setting/README.md)     | 기본 설치 — 프로그램·Windows 설정·소스 내려받기 (0~1장) |
| **②** | [pc/1.pc.byVagrant/README.md](pc/1.pc.byVagrant/README.md) | 단계별 절차서 — VM 만들기부터 Kubespray 까지 (2장~)     |

* ①은 구글 드라이브로 받는 `_prgs\Day2\` 안에도 같은 내용으로 동봉된다.
* ①②가 참조하는 상세 폴더는 둘이다 — `1.pc.byVagrant`(VM 생성, 호스트에서) · `2.pc.InstanceForKubernetes`(inventory·점검, i1 안에서).
  AWS 의 `2.aws.Create_IAM_Key`(자격증명 발급)에 해당하는 것이 로컬에는 없으므로 폴더가 둘뿐이다.
* **수업은 `1.pc.byVagrant` 로 진행한다.** VM 1대 안에 전부 넣는 `cf_inVm` 은 참고용이며, 고르는 기준은 [pc/README.md](pc/README.md) 에 있다.
* Windows 호스트에는 VirtualBox·Vagrant 만 있으면 된다. Ansible 은 i1 안에서 돈다.

## AWS 경로 — [aws](aws/README.md)

진입점은 문서 하나다 — **[aws/0.pc_setting/README.md](aws/0.pc_setting/README.md)**.
내 PC 에 설치할 것부터 AWS 계정·키, 콘솔 서버 `i1`, Kubernetes 설치까지 한 문서로 이어진다.

* 그 문서가 참조하는 상세 절차서 3종(`1.aws.byTerraform`·`2.aws.Create_IAM_Key`·`3.aws.InstanceForKubernetes`)의
  역할과 호출 관계는 [aws/README.md](aws/README.md) 에 있다.
* ⚠️ **폴더 번호와 진행 순서가 다르다** — 키가 없으면 Terraform 이 아무것도 못 만들므로
  `2.aws.Create_IAM_Key` 를 `1.aws.byTerraform` 보다 **먼저** 한다. 진입점이 그 순서로 안내한다.
* ⚠️ **`_prgs` 구성이 로컬 PC 방식과 다르다** — VirtualBox·Vagrant·box(약 1.1 GB)가 빠지고 **PuTTY** 가 들어간다.
  로컬 PC 방식의 `_prgs` 를 그대로 쓰지 않는다.

## 두 경로의 공통점

* Terraform 이 하던 일(인스턴스 생성)을 Vagrant 가 대신할 뿐, **Kubespray 를 실행하는 부분은 같다.**
* 노드 이름(`i1`·`vm01`~`vm03`)·계정(`ubuntu`)·inventory 역할 배치가 양쪽 같으므로 **lab2~lab5 는 구분 없이 진행된다.**

# cf) Lab1 스크립트에 대해

* 이 폴더의 스크립트는 **강의용**이다. Terraform·AWS CLI·Ansible 을 설치하고 여러 인스턴스를 한 번에 프로비저닝한다.
* Terraform 을 이미 쓰고 있다면 **본인 스크립트를 써도 무방하다.** 결과만 같으면 된다.
