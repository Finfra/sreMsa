# 수강 관련 문의 : [한국글로벌널리지](https://www.globalknowledge.co.kr)

# Usage.

```
git config --global core.autocrlf false
git config --global core.eol lf
cd

git clone https://github.com/Finfra/sreMsa
cd sreMsa
```

# [Lab0. Docker](./lab0.Docker/)

* **1일차** — 내 Windows 에서 Docker Desktop 으로 컨테이너를 먼저 다룬다
* VM 이나 Linux 를 거치지 않으므로 첫날 바로 실습에 들어간다

## Lab0-1. [컨테이너 사용 — docker run](./lab0.Docker/1.dockerRun/)

* 이미지 검색·실행·접속·이미지화·정리 · 볼륨 매핑 · Docker Hub push

## Lab0-2. [이미지 제작 — docker build](./lab0.Docker/2.dockerBuild/)

* Dockerfile 문법 · build · 캐시 · GitHub(절차)과 Docker Hub(결과) 분리 배포
* ⚠️ **2일차로 넘어가기 전에 Hyper-V 를 끄고 재부팅한다.** Docker Desktop 과 VirtualBox 는 같은 PC 에서 동시에 켤 수 없다

# [Lab1. 사전 실습 환경 세팅](./lab1.Kubespray/)

* **2일차** — VirtualBox + Vagrant 로 VM 을 만들고 Kubespray 로 클러스터를 올린다

## Lab1-1~3. Terraform으로 EC2 인스턴스 생성

### Lab1-1. 실습용 Terraform Instance 구성

### Lab1-2. IAM Key생성

### Lab1-3. Terraform으로 K8s용으로 사용할 Instance 생성

## Lab1-4~5. Ansible+Terraform Provisiong(Kubespray)

### Lab1-4. Kubepray를 통한 K8s 구성

### Lab1-5. K8s 작동 테스트

# [Lab2. Kubernetes](./lab2.Kubernetes/)

* Kubernetes 기본 기능 실습

## Lab2-1. 개념이해를 위한 쿠버네티스 학습 시뮬레이터 사용 실습

## Lab2-2. 노드 관리 실습

## Lab2-3. Kubernetes Deplyment

## Lab2-4. Kubernetes 각종 레이블 관리와 모니터링

## Lab2-5. Kubernetes 서비스, 로드발렌싱, AutoScaling

## Lab2-6. Kubernetes 네트워킹

## Lab2-7. Kubernetes 스토리지

## Lab2-8. Container Deploy(CI/CD에서 사용할 Java 동작 OS) 실습

# [Lab3. Istio](./lab3.Istio/)

* Istio를 통한 Service Mesh 구현 실습

## Lab3-1. Istio 셋팅 실습

## Lab3-2. Istio Traffic 관리 실습

## Lab3-3. 인증, 권한 부여 및 서비스 통신 암호화를 관리 실습

## Lab3-4. Istio를 통한 K8s 클러스터 접근 실습(외부에서 내부로 접근)

# [Lab4. Argo CD](./lab4.ArgoCd/)

* Argo CD를 통한 GitOps 구현 실습

## Lab4-1. Argo CD install

## Lab4-1. Argo CD를 통한 Canary배포 실습

# [Lab5. zipkin](./lab5.Zipkin/)

* ZipKin을 통한 MSA Monitoring 실습

## Lab5-1. zipkin/jaeger 셋팅 실습

## Lab5-2. Zipkin을 이용한 MSA 환경에서 분산 트렌젝션의 추적

## Lab5-3. Transaction UI(API / Web) 연동 실습

# [Lab6. Serverless](./lab6.Serverless/)

* OpenFaaS로 서버리스(FaaS) 실습

## Lab6-1. Kubernetes 위에 OpenFaaS CE 설치

## Lab6-2. 첫 함수 만들기 — 빌드·배포·호출, 코드 수정 후 재배포

## Lab6-3. 콜드 스타트 — 첫 요청만 느린 이유를 직접 측정

## Lab6-4. 오토스케일 — 요청이 몰릴 때 인스턴스가 늘어나는 구간 관찰



# PC기본 설치 프로그램

**전 과정에 공통으로 쓰는 것**만 여기에 적는다. **강의 처음에 구글 드라이브로 받는 `_prgs`** 폴더에 들어 있다.

| 프로그램    | 파일                              |   크기 | 쓰임                                       |
| :---------- | :-------------------------------- | -----: | :----------------------------------------- |
| **VS Code** | `VSCodeUserSetup-x64-1.137.0.exe` | 224 MB | YAML·매니페스트 편집 — Lab0 부터 Lab6 까지 |

* 설치 옵션은 기본값 그대로 둔다. 이미 깔려 있으면 다시 깔 필요 없다.
* **인터넷에서 직접 받지 말 것.** 수강생이 동시에 내려받으면 교육장 회선이 막힌다.

## 그 밖의 설치 파일은 해당 Lab 이 안내한다

`_prgs` 에는 위 공통 프로그램 외에 Lab 별 설치 파일이 함께 들어 있다. **무엇을 언제 까는지는 각 문서가 정한다.**

| `_prgs` 안             | 언제 쓰나              | 안내 문서                                                                                       |
| :--------------------- | :--------------------- | :---------------------------------------------------------------------------------------------- |
| `DockerDesktop/`       | **1일차** Docker 실습  | [lab0.Docker/README.md](./lab0.Docker/README.md)                                                |
| VirtualBox·Vagrant·box | **2일차** VM·Kubespray | [lab1.Kubespray/pc/0.pc_setting/README.md](./lab1.Kubespray/pc/0.pc_setting/README.md)          |
| `docker/` (deb)        | 참고 — VM 안 Docker    | [lab1.Kubespray/pc/1.pc.byVagrant/README.md](./lab1.Kubespray/pc/1.pc.byVagrant/README.md) 11장 |

* ⚠️ **1일차와 2일차는 Hyper-V 요구가 정반대다.** Docker Desktop 은 켜야 하고 VirtualBox 는 꺼야 하므로, 2일차로 넘어갈 때 끄고 재부팅한다.
* 파일이 온전한지는 `_prgs\SHA256SUMS.txt` 로 확인한다.

```powershell
cd $env:USERPROFILE\Downloads\_prgs
Get-FileHash *.exe,*.msi,*.box -Algorithm SHA256 |
  ForEach-Object { "{0}  {1}" -f $_.Hash.ToLower(), (Split-Path $_.Path -Leaf) }
```




# 수강 년도별 소스 보기

## 202508~202511에 수업들었던 분들은 아래 방식

```
cd
git clone https://github.com/Finfra/sreMsa
cd sreMsa
git checkout 202511
```

## 202504~202508에 수업들었던 분들은 아래 방식

```
cd
git clone https://github.com/Finfra/sreMsa
cd sreMsa
git checkout 202508
```

## 202207~202504에 수업들었던 분들은 아래 방식

```
cd
git clone https://github.com/Finfra/sreMsa
cd sreMsa
git checkout 202504
```

## 202107~202207에 수업들었던 분들은 아래 방식

```
cd
git clone https://github.com/Finfra/sreMsa
cd sreMsa
git checkout 202207
```

## 202107이전에 수업들었던 분들은 아래 방식

```
cd
git clone https://github.com/Finfra/sreMsa
cd sreMsa
git checkout 202107
```
