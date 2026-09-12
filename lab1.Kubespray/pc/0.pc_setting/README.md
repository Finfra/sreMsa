# 실습 환경 기본 설치 — 프로그램·소스 준비 (Windows)

내 PC 에 Kubernetes 실습 환경을 만들기 위한 **첫 단계**다.
프로그램을 깔고, Windows 설정을 바꾸고, 실습 소스를 받는 데까지를 다룬다.

* **이 문서만 마치면** VM 을 만들 준비가 끝난다. 그 다음은
  [1.pc.byVagrant/README.md](../1.pc.byVagrant/README.md) 의 **2장** 부터 이어서 진행한다.
* 장 번호는 그 문서와 이어진다 — 여기가 0~1장, 거기가 2장부터다.
* 이 문서는 강사 배포 폴더 `_prgs` 안에도 같은 내용으로 들어 있다.

# 0. 준비물

## 하드웨어

* 메모리 **16GB 최소**, 24GB 이상 권장 — VM 이 합계 **9.5GB** 를 쓴다
* CPU **논리 프로세서 8개 이상 권장** — VM 이 합계 7개를 가져간다. 4개뿐이면 느려진다
* 디스크 여유 **60GB 이상**
* CPU 가상화 지원 (요즘 PC 는 모두 지원한다)

메모리가 부족하면 [1.pc.byVagrant/README.md](../1.pc.byVagrant/README.md) 의 "메모리가 부족할 때" 절을 본다.

## 배포 폴더 3개를 `다운로드` 에 복사한다 ★

강사가 배포하는 폴더는 셋이다. **전부 `다운로드`(Downloads) 폴더에 복사**한다.

```
C:\Users\<계정>\Downloads\
├── sreMsa\   ← 실습 소스 (여기서 vagrant up 을 한다)
├── _prgs\    ← 설치 파일
└── _vm\      ← 완성된 VM 백업 (문제가 생겼을 때만 쓴다)
```

| 폴더     | 언제 쓰나                                                                            |
| :------- | :----------------------------------------------------------------------------------- |
| `sreMsa` | **수업 내내.** 실습은 전부 여기서 한다                                               |
| `_prgs`  | **맨 처음 한 번.** 프로그램 설치와 box 등록에 쓴다                                   |
| `_vm`    | **문제가 생겼을 때만.** VM 이 깨지거나 설치가 끝나지 않은 경우 강사 안내에 따라 쓴다 |

> `sreMsa` 폴더가 곧 실습 소스다. **따로 내려받을 것이 없다.**

## 소프트웨어 — 강사가 제공하는 `_prgs` 폴더를 쓴다 ★

**인터넷에서 직접 받지 말 것.** 강사가 배포하는 **`_prgs`** 폴더에 필요한 파일이 모두 들어 있다.

**파일 이름 앞의 번호가 곧 설치 순서다.** 1~4 를 차례로 설치하고, 5 는 설치가 아니라 **등록**한다(아래 "Vagrant box 등록" 절).

| 순서  | `_prgs` 안의 파일                                       |          크기 | 용도                                                      |
| :---: | :------------------------------------------------------ | ------------: | :-------------------------------------------------------- |
| **1** | `1_VSCodeUserSetup-x64-1.137.0.exe`                     |        224 MB | Visual Studio Code — YAML·매니페스트 편집용               |
| **2** | **`2_vc_redist.x64.exe`**                               |         25 MB | **Visual C++ 재배포 — 바로 다음 VirtualBox 의 전제조건**  |
| **3** | `3_VirtualBox-7.2.16-174877-Win.exe`                    |        170 MB | VirtualBox 7.2.16                                         |
| **4** | `4_vagrant_2.4.9_windows_amd64.msi`                     |        236 MB | Vagrant 2.4.9                                             |
| **5** | `5_bento-ubuntu-24.04-202510.26.0-virtualbox-amd64.box` |        621 MB | **Vagrant box** — 설치가 아니라 **등록**한다              |
| 나중  | `docker/` (deb 4개)                                     |         73 MB | **Docker Engine — VM 안의 Ubuntu 에 설치**한다(정본 11장) |
|   —   | `SHA256SUMS.txt`                                        |             — | 무결성 검증용 체크섬                                      |
|       | 합계                                                    | **약 1.4 GB** |                                                           |

수강생 전원이 같은 파일을 동시에 내려받으면 교육장 회선이 막혀 실습을 시작조차 못 한다.
box 하나만 해도 20명이면 **12GB** 가 한꺼번에 흐른다. 그래서 미리 받아 배포한다.

**구글 드라이브에서 바로 실행하지 말고 로컬(`다운로드` 폴더)로 복사한 뒤 쓴다.** 드라이브에서 직접 실행하면
파일을 그때그때 내려받느라 느리고, 회선이 끊기면 설치가 중단된다.

> ⚠️ **`docker/` 는 이 단계에서 설치하지 않는다.** VM 안의 Ubuntu 에 까는 것이며 [1.pc.byVagrant/README.md](../1.pc.byVagrant/README.md) 11장에서 쓴다.
> **내 PC(Windows)에 Docker Desktop 을 설치하지 말 것** — Hyper-V 가 켜져 VirtualBox 가 VM 을 띄우지 못하게 된다.

설치 옵션은 전부 기본값 그대로 둔다.

**설치 전에 파일이 온전히 복사됐는지 확인한다.** 복사 도중 끊기면 설치가 알 수 없는 오류로 실패한다.

```powershell
cd $env:USERPROFILE\Downloads\_prgs
Get-FileHash *.exe,*.msi,*.box -Algorithm SHA256 |
  ForEach-Object { "{0}  {1}" -f $_.Hash.ToLower(), (Split-Path $_.Path -Leaf) }
```

출력된 해시를 `SHA256SUMS.txt` 의 값과 견준다. 다른 것이 있으면 그 파일을 다시 복사받는다.
**PowerShell 에 기본으로 들어 있는 명령이라 따로 설치할 것이 없다.**

설치가 끝나면 곧바로 다음 절로 간다. **재부팅은 "Windows 만의 사전 작업" 에서 한 번에 처리**한다.

> ★ **`2_vc_redist.x64.exe` 를 `3_VirtualBox` 보다 먼저 설치해야 한다.** VirtualBox 는 Visual C++ 재배포 패키지를 요구하는데,
> Windows 를 새로 설치한 PC 에는 이것이 없다. 없는 상태로 VirtualBox 설치를 실행하면 아래 메시지와 함께
> **`msiexec` 오류 1603 으로 1초 만에 끝나 버린다.**
>
> ```
> Oracle VirtualBox 7.2.16 needs the Microsoft Visual C++ 2019
> Redistributable Package being installed first.
> ```
>
> 다른 프로그램을 쓰다 보면 대개 딸려 들어오기 때문에 기존 PC 에서는 잘 드러나지 않는다.
> **갓 설치한 Windows 에서만 나타나는 함정**이라 실기에서 처음 확인했다.

**PowerShell 을 쓴다.** 이 문서의 명령은 모두 PowerShell 기준이며, 별도 터미널을 설치하지 않는다.

설치 후 터미널을 새로 열어 확인한다.

```powershell
VBoxManage --version
vagrant --version
```

**Vagrant 플러그인은 하나도 설치하지 않는다.** 이 실습은 플러그인 없이 동작하도록 만들었다.
예전 자료들이 Windows 에 `vagrant-winnfsd` 를 필수로 안내하는 경우가 있는데,
그것은 공유 폴더를 NFS 로 쓰던 시절의 이야기이고 여기서는 VirtualBox 기본 공유를 쓴다.

```bash
vagrant plugin list
```

```
No plugins installed.
```

이렇게 나오는 것이 정상이다. 이미 설치된 플러그인이 있어도 대개 무해하지만,
`vagrant-triggers` 는 Vagrant 내장 기능과 충돌하므로 있으면 지운다(`vagrant plugin uninstall vagrant-triggers`).

> 이미 같은 버전을 설치해 두었다면 그대로 써도 된다.
> 다만 **Vagrant box 만큼은 반드시 `_prgs` 것을 쓴다**(아래 "Vagrant box 등록" 절).
> 회선을 가장 많이 잡아먹는 것이 box 이기 때문이다.
>
> 인터넷에서 직접 받아야 하는 상황이라면 아래가 원본 주소다.
> VirtualBox https://www.virtualbox.org/wiki/Downloads ·
> Vagrant https://developer.hashicorp.com/vagrant/downloads

## Windows 만의 사전 작업 ★ 여기서 가장 많이 막힌다

VirtualBox 는 Hyper-V 가 켜져 있으면 VM 을 띄우지 못한다.
Docker Desktop·WSL2 를 쓴 적이 있거나, Windows 11 이라면 대개 켜져 있다.

**관리자 권한 PowerShell** 에서 실행한 뒤 재부팅한다.

```powershell
bcdedit /set hypervisorlaunchtype off
shutdown -r -t 0
```

Windows 11 은 Hyper-V 를 켠 적이 없어도 **메모리 무결성(코어 격리)** 이 기본으로 켜져 있어 같은 증상이 난다.
`Windows 보안 → 장치 보안 → 코어 격리 세부 정보` 에서 **메모리 무결성**을 끄고 재부팅한다.

> 되돌리려면 `bcdedit /set hypervisorlaunchtype auto` + 재부팅.
> Docker Desktop·WSL2 를 다시 쓸 때 필요하다.

**재부팅한 뒤 실제로 꺼졌는지 확인한다.** 설정값만 보면 안 된다 — 재부팅 전에도 `Off` 로 보이기 때문이다.

```powershell
(Get-CimInstance Win32_ComputerSystem).HypervisorPresent
```

`False` 가 나와야 VirtualBox 가 VM 을 띄울 수 있다. `True` 면 아직 Hyper-V 가 올라와 있는 것이므로
메모리 무결성까지 껐는지 다시 확인하고 재부팅한다.

**Docker Desktop 을 쓴 적이 있다면 이 절이 특히 중요하다.** 그것이 Hyper-V 를 켜 두기 때문이다.
이 실습은 Hyper-V 를 **끈 상태로 끝까지** 진행한다 — 컨테이너 실습도 VM 안에서 하므로([1.pc.byVagrant/README.md](../1.pc.byVagrant/README.md) 11장) 중간에 다시 켤 일이 없다.

## Vagrant box 등록 ★ 이 절을 건너뛰면 인터넷에서 621MB 를 받는다

`_prgs` 의 `.box` 파일을 Vagrant 에 등록한다. **인터넷을 쓰지 않는다.**

PowerShell 에서 `_prgs` 폴더로 이동한 뒤 실행한다.

```powershell
cd $env:USERPROFILE\Downloads\_prgs
vagrant box add bento/ubuntu-24.04 ./5_bento-ubuntu-24.04-202510.26.0-virtualbox-amd64.box
```

* **주의 : 파일 이름 앞의 `5_` 까지 그대로 적는다.** 번호를 빼면 파일을 찾지 못한다.

**이름을 `bento/ubuntu-24.04` 로 등록해야 한다.** 이름이 다르면 `vagrant up` 이 이 box 를 찾지 못하고
인터넷에서 다시 받으려 한다. 등록됐는지 확인한다.

```powershell
vagrant box list
```

```
bento/ubuntu-24.04 (virtualbox, 0, (amd64))
```

버전이 `0` 으로 보이는 것이 정상이다. 로컬 파일에서 추가하면 버전 정보가 없기 때문이며 실습에 지장이 없다.
[settings.yml](../1.pc.byVagrant/settings.yml) 의 `box.version` 을 비워 둔 것도 이 때문이다.

> 잘못된 이름으로 등록했다면 지우고 다시 넣는다.
> ```powershell
> vagrant box remove <잘못된이름>
> vagrant box add bento/ubuntu-24.04 ./5_bento-ubuntu-24.04-202510.26.0-virtualbox-amd64.box
> ```

# 1. 소스 확인

**따로 내려받지 않는다.** 0장에서 `다운로드` 로 복사한 `sreMsa` 폴더가 곧 실습 소스다.
`git clone` 을 쓰던 절차는 없앴다 — 배포 폴더에 같은 내용이 이미 들어 있고,
교육장 회선으로 20명이 동시에 받으면 그것대로 막히기 때문이다.

PowerShell 에서 폴더가 제대로 복사됐는지만 본다.

```powershell
cd $env:USERPROFILE\Downloads\sreMsa
dir
```

```
lab1.Kubespray  lab2.Kubernetes  lab3.Istio  lab4.ArgoCd  lab5.Zipkin  lab6.Serverless  README.md
```

이 여섯 폴더가 보이면 된다. 하나라도 없으면 복사가 덜 끝난 것이므로 `다운로드` 폴더를 다시 확인한다.

> **Git 을 설치하지 않는 이유** — 소스를 복사해 쓰므로 `git clone` 이 필요 없고,
> 실습 중 호스트에서 쓰는 명령은 PowerShell 과 Windows 기본 `ssh` 로 모두 된다.
> 설치 프로그램이 하나 줄면 교육장에서 막힐 자리도 하나 준다.

# 다음 단계

여기까지 마치면 **프로그램·소스·box 가 모두 준비된 상태**다. VM 만들기부터는 복사한 소스 안의 문서를 따른다.

```powershell
cd $env:USERPROFILE\Downloads\sreMsa\lab1.Kubespray\pc\1.pc.byVagrant
```

→ [1.pc.byVagrant/README.md](../1.pc.byVagrant/README.md) 의 **2. VM 만들기** 로 이어서 진행한다.
