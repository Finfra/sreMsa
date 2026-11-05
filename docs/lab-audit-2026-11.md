# lab0~lab3 점검 기록 (2026-11)

* 범위 : `lab0.Docker` · `lab1.Kubespray` · `lab2.Kubernetes` · `lab3.Istio`
* 대상 : 제거·deprecated 된 Kubernetes/Istio API, kubectl·istioctl 명령, 사라진 이미지 저장소, 깨진 URL
* 원칙 : 확실한 것만 본문을 고쳤다. 실습 버전 고정 의도가 보이거나 확인이 부족한 것은 아래 **권고**로 남긴다.

## 1. 이번에 고친 것

| 파일                                            | 내용                                                                         | 근거                                                                                   |
|-------------------------------------------------|------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| `lab2.Kubernetes/1.KubernetesBasic/README.md`   | `kubectl exec -it nginx bash` → `kubectl exec -it nginx -- bash`             | kubectl v1.37.2 : `exec [POD] [COMMAND] is not supported anymore`                      |
| `lab2.Kubernetes/1.KubernetesBasic/README.md`   | short-name 표에서 `psp` 제거, `cs`·`ep` 에 deprecated 표시                    | PodSecurityPolicy 는 v1.25 에서 제거, ComponentStatus v1.19 · Endpoints v1.33 deprecated |
| `lab3.Istio/5.RequestRouting/README.md`         | `istioctl profile list` 주석 처리                                            | istio/istio `istioctl/cmd/root.go` : `ProfileCmd` 가 release-1.23 까지만 있음            |
| `lab3.Istio/1.istioInstall`, `5.RequestRouting` | `git.io/getLatestIstio` → `istio.io/downloadIstio`                           | Istio Getting Started 문서의 공식 설치 명령                                             |
| `lab2.Kubernetes/9.k8sContainerDeploy/README.md` | Helm apt 저장소 `baltocdn.com` + `apt-key` → Buildkite 저장소 + keyring      | Helm 공식 설치 문서(helm-www `docs/intro/install.mdx`)                                 |
| `lab3.Istio/3.istioSecurity/concept.md`         | 상단에 "v1alpha1 보안 API 는 현행 Istio 에 적용되지 않음" 경고 추가           | Istio 1.6 Upgrade Notes "Support ended for v1alpha1 security policy"                   |

## 2. 권고 (본문 미수정)

### 2.1 Istio (lab3)

* **`security.istio.io/v1beta1` → `v1`** (`3.istioSecurity/README.md` 의 `PeerAuthentication` 2곳)
  - 현재 Istio master CRD 에서 `v1beta1` 은 아직 served 이며 deprecated 표시도 없다. 지금 당장 깨지지는 않는다.
  - 공식 mTLS Migration 문서는 `v1` 을 쓴다. `v1` 은 Istio 1.22 이상에서만 받아들이므로, 실습이 최신 Istio 를 받는 지금 구조라면 바꿔도 된다.
* **`samples/sleep` → `samples/curl`** (`3.istioSecurity/README.md`)
  - 공식 mTLS Migration 문서는 `samples/curl/curl.yaml` · `-l app=curl` · `-c curl` 로 바뀌었다.
  - `samples/sleep/sleep.yaml` 은 Istio master 에 아직 남아 있어 현재는 동작한다. 바꿀 때는 `app=sleep`·`-c sleep` 도 함께 바꿔야 한다.
* **Istio 제거 명령**
  - `istioctl manifest generate ... | kubectl delete -f -` 는 아직 동작한다(`manifest` 명령 존재).
  - 공식 제거 절차는 `istioctl uninstall --purge` 다. 단순화를 검토한다.
* **`lab3.Istio/2.istioTrafficManage/bookinfo.yaml` 사본**
  - 이미지 `docker.io/istio/examples-bookinfo-*:1.16.2` 는 Docker Hub 에 남아 있다(2026-11 확인).
  - Istio master 의 원본은 `registry.istio.io/release/examples-bookinfo-*:1.20.3` 으로 바뀌었다.
  - 실습 본문은 내려받은 Istio 의 `samples/bookinfo/...` 를 쓰므로 이 사본은 참고용이다. 갱신하거나 삭제를 검토한다.
* **`3.istioSecurity/concept.md`**
  - Citadel·Mixer·node agent 중심의 옛 구조 번역이다. 링크도 `istio.io/docs/...` 옛 경로(`#servicerole`, `policies-and-telemetry` 등)라 현행 페이지에 해당 절이 없을 가능성이 크다.
  - 경고만 달았다. 현행 [Security 개념 문서](https://istio.io/latest/docs/concepts/security/) 기준으로 다시 정리할지 결정이 필요하다.

### 2.2 Kubespray (lab1 · lab2/3.k8sNodeManage)

* **inventory 그룹 이름**
  - `lab2.Kubernetes/3.k8sNodeManage/README.md` 와 `lab1.Kubespray/aws/3.aws.InstanceForKubernetes/singleNodeInstall_for_i1.md` 는 `kube-master`·`kube-node`·`k8s-cluster` 를 쓴다.
  - lab1 본문은 `kube_control_plane`·`kube_node`·`k8s_cluster` 를 쓴다.
  - Kubespray release-2.28 과 master 모두 옛 이름을 새 이름으로 매핑(`dynamic_groups` 역할)하므로 지금은 동작한다. 일관성을 위해 새 이름으로 맞출 것을 권한다.
* **버전 고정**
  - lab1 본문은 `git clone -b release-2.28` 로 고정되어 있다(의도된 고정으로 보아 유지).
  - `singleNodeInstall_for_i1.md` 는 브랜치 지정 없이 master 를 받으면서 `ansible==9.5.1` 을 고정한다. master 의 요구 Ansible 버전과 어긋날 수 있다. `-b release-2.28` 로 맞추는 것을 권한다.

### 2.3 Kubernetes (lab2)

* **`katacoda/docker-http-server`** (`1.KubernetesBasic/README.md`)
  - Docker Hub 에서 pull 가능하다(2026-11 확인). 다만 마지막 갱신이 2016-10 이고 `amd64` 이미지만 있다.
  - Apple Silicon 등 arm64 노드(kind 대체 경로 포함)에서는 실행이 안 될 수 있다. `httpd`·`nginx` 같은 공식 이미지로 바꾸는 것을 권한다.
* **Endpoints 조회** (`k8sResourceLog.sh` 의 `kubectl get endpoints`)
  - v1.33 이후 deprecation 경고가 나온다. 실패는 아니다. `kubectl get endpointslices` 병기를 검토한다.
* **pod 이름 불일치** (`1.KubernetesBasic/README.md` "Pod 접근 : exec")
  - 바로 위에서 `kubectl create deployment ... nginx` 로 만들었으므로 pod 이름은 `nginx-xxxx` 다. `kubectl logs nginx`·`kubectl exec nginx` 는 그대로는 `NotFound` 가 난다.
  - API 변경 문제가 아니라 이번 범위에서는 고치지 않았다. `deploy/nginx` 로 바꾸면 해결된다(`kubectl exec deploy/nginx -- pwd`).
* **ReplicaSet 대상 autoscale** (`1.KubernetesBasic`, `6.k8sServiceLoadBalancingAtoScaling`)
  - `kubectl autoscale rs <이름>` 은 명령으로는 유효하지만 Deployment 가 관리하는 RS 를 HPA 로 직접 잡는 형태다. `kubectl autoscale deployment h1 --max=10` 이 일반적이다.
* **Helm**
  - tarball 경로가 `helm-v3.6.2` 로 고정되어 있다(의도된 고정으로 보아 유지). Helm 공식 문서는 현재 v4 를 예시로 든다.
  - apt 경로는 이번 수정으로 최신 Helm 이 깔린다. 두 경로의 버전이 달라지므로 강의 기준 버전을 정할 것을 권한다.
* **Bitnami 차트** (`9.k8sContainerDeploy/README.md`)
  - `charts.bitnami.com/bitnami` 와 `bitnami/tomcat` 차트의 현재 제공 방식은 이 환경에서 확인하지 못했다(아래 4절).
  - `bitnami/tomcat:latest` 이미지 태그는 Docker Hub 에서 active 다. 차트가 참조하는 버전 태그도 받을 수 있는지는 실습 전 실기 확인이 필요하다.

### 2.4 Docker (lab0)

* `2.dockerBuild/README.md` 의 "`Step 1/4` … 가 흐르면 정상" 은 레거시 빌더의 출력 형식이다. 같은 문서 5장은 BuildKit 출력(`CACHED`)을 설명한다. 실제 화면과 맞춰 문구 정리를 권한다.
* `README.md` 의 `wsl_update_x64.msi` 직접 다운로드 링크는 접근 확인을 하지 못했다. 현행 WSL 은 `wsl --install` / `wsl --update` 로 받는 방식이 일반적이다.

## 3. 검증

* kubectl v1.37.2 (dl.k8s.io stable) · kubeconform v0.8.0
* README 의 heredoc 매니페스트 13개 + `bookinfo.yaml` 을 추출해 검증

```
kubeconform -strict -summary -kubernetes-version master \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' *.yaml
Summary: 27 resources found in 14 files - Valid: 27, Invalid: 0, Errors: 0, Skipped: 0
```

* `-kubernetes-version 1.34.0` 도 같은 결과(27/27 Valid)
* kubectl 클라이언트 측 확인 : `kubectl create deployment ... --replicas=6 --dry-run=client`, `kubectl create deployment --image=httpd --port=80 h1 --dry-run=client` 정상

## 4. 확인하지 못한 것

* 이 점검 환경의 네트워크 정책 때문에 다음 호스트는 접속 확인을 못 했다. 링크가 깨졌다는 뜻이 아니다.
  - `istio.io`, `kubernetes.io`, `github.com`(웹), `git.io`, `charts.bitnami.com`, `charts.kubesphere.io`, `get.helm.sh`, `bootstrap.pypa.io`, `desktop.docker.com`, `wslstorestorage.blob.core.windows.net`, `kubeedge.io`, `subicura.com` 등
* `raw.githubusercontent.com` · Docker Hub API 는 접속되어 소스·이미지 존재를 확인했다.
* 실제 클러스터에 적용(`kubectl apply`)하는 검증은 하지 않았다.
