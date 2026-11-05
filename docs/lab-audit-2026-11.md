# 실습 점검 기록 — 2026-11

## lab4 ~ lab6 (ArgoCD · Zipkin · Serverless)

### 점검 범위와 방법

* 대상 : `lab4.ArgoCd`·`lab5.Zipkin`·`lab6.Serverless` 아래 모든 문서
    - 세 랩 모두 **별도 매니페스트·스크립트 파일이 없고**, 명령과 YAML 이 README 코드블록 안에 들어 있음
* 확인 항목
    - 제거·deprecated 된 Kubernetes API(apiVersion)·Istio API·kubectl 플래그
    - 사라진 이미지 저장소·이미지 태그
    - 깨진 URL
* 확인 방법
    - 문서 안 Kubernetes YAML 은 추출해 kubeconform 으로 검증
    - 외부 저장소 내용은 `raw.githubusercontent.com` 으로, 이미지는 레지스트리 manifest API 로 존재 여부 확인
    - 점검 환경의 네트워크 정책으로 일부 도메인은 접속 자체를 확인하지 못함(아래 «확인하지 못한 것»)

### 결과 요약

* Kubernetes API : 문제 없음
    - 문서 안 YAML 은 `lab6.Serverless/2.firstFunction` 의 registry `Deployment`(`apps/v1`)·`Service`(`v1`) 2건뿐이며 모두 현행 GA
    - Istio 리소스는 lab4~6 에 없음
* kubectl 플래그 : 문제 없음
    - `--sort-by`·`--wait=false`·`-w`·`-o jsonpath` 등 모두 현행
    - `argocd cluster add --in-cluster` 도 현행 CLI 문서에 남아 있음
* 이번에 고친 것(확실한 것만)

| 파일                                    | 내용                                                                                          |
| :-------------------------------------- | :-------------------------------------------------------------------------------------------- |
| `lab4.ArgoCd/1.ArgoCdInstall/README.md` | Argo CD 문서 링크 3곳 → `argo-cd.readthedocs.io/en/stable/` (Argo CD 저장소 README 가 안내하는 공식 문서 위치) |
| `lab4.ArgoCd/3.MiniWorkShop/README.md`  | `http://dockerhub.com` → `https://hub.docker.com`, `http://github.com` → `https://github.com`  |
| `lab5.Zipkin/04.zipkinStorage/README.md` | `org.springframework.boot.loader.PropertiesLauncher` → `org.springframework.boot.loader.launch.PropertiesLauncher` (zipkin-aws module README 의 현행 기동 예와 동일) |
| `lab5.Zipkin/0.java/2.MavenBuild.md`    | Maven 3.8.1 내려받기 주소를 국내 미러 → Maven Central(`repo.maven.apache.org`). 버전 3.8.1 은 그대로 |

### 권고 (버전 고정 의도가 있거나 실측이 필요해 손대지 않은 것)

1. **`lab5.Zipkin/04.zipkinStorage` — 문서에 비밀번호·실제 도메인 엔드포인트가 들어 있음**
    - OpenSearch 마스터 비밀번호와 특정 도메인 엔드포인트가 평문으로 커밋되어 있음(83·91·120행 부근)
    - 공개 저장소이므로 자리표시자(`<도메인 엔드포인트>`·`<마스터 비밀번호>`)로 바꾸고, 해당 계정 비밀번호는 이미 노출된 것으로 보고 교체 권고
2. **`lab5.Zipkin/04.zipkinStorage` — AWS 모듈 적재 방식이 upstream 과 다름**
    - 문서는 `aws-java-sdk.zip`(AWS SDK for Java 1.x 묶음)을 받아 `-Dloader.path` 에 넣음
    - zipkin-aws module README 는 `quickstart.sh` 로 `io.zipkin.aws:zipkin-module-aws:LATEST:module` 을 받아 그 jar 를 `loader.path` 에 넣는 방식을 안내함
    - 또 문서는 `latest` 를 받으면서 `loader.path` 에는 `aws-java-sdk-1.12.42` 를 박아 두어, 받은 버전과 경로가 어긋날 수 있음
    - AWS SDK for Java 1.x 는 지원 종료 일정이 공지된 상태 — 실습 전 AWS 공지 재확인 필요
    - 절차 전체를 module jar 방식으로 다시 쓰고 실측할 것을 권고
3. **`lab5.Zipkin/04.zipkinStorage` — 구 Elasticsearch Service CLI**
    - `aws es describe-elasticsearch-domain` 은 Amazon OpenSearch Service 이전 이름의 API
    - 현행 명령은 `aws opensearch describe-domain --domain-name <이름>` 이며 응답의 `.DomainStatus.Endpoint` 경로는 같음
    - 문서 제목·본문의 "Amazon Elasticsearch Service"·"Kibana" 표기도 현행 콘솔(OpenSearch Dashboards)과 다름
4. **`lab5.Zipkin/2.zipkinTransactionTrace` — Java 11 설치가 남아 있음**
    - `0.java/1.JavaBasic.md` 는 "17 하나로 통일했다" 고 적었지만 이 문서는 아직 `openjdk-11-jre-headless` 를 설치함
    - 예제 `brave-example/webmvc4-boot` 는 Spring Boot 1.5.22 기반 — JDK 17 에서 빌드·실행되는지 실측 후 17 로 맞출 것을 권고
5. **`lab5.Zipkin/0.java/2.MavenBuild.md` — 수동 설치 예의 `JAVA_HOME` 이 Java 8**
    - `JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/` 로 되어 있어 17 기준 문서와 어긋남
6. **`lab6.Serverless` — `node20` 템플릿**
    - Node.js 20 은 2026-04 에 지원 종료(EOL)
    - `openfaas/templates` 에 `node22`·`node24` 템플릿이 있음
    - 소요 시간 등 실측값이 `node20` 기준이므로 바꾸지 않음 — 다음 회차 전 `node22` 이상으로 실측 후 교체 권고
7. **`lab6.Serverless/2.firstFunction` 9절·`lab6.Serverless/README.md` — Java 템플릿 설명이 현행과 다름**
    - 문서는 `java11`·`java17` 템플릿이 `openjdk:*-slim` 베이스 이미지 때문에 빌드되지 않는다고 적음
    - 현재 `openfaas/templates` 의 두 템플릿 Dockerfile 은 `eclipse-temurin:{11,17}-jdk-noble`·`-jre-noble` 을 씀
    - 지금도 빌드가 실패하는지는 확인하지 못함 — 재실측 후 문장 갱신 권고
8. **`lab4.ArgoCd/1.ArgoCdInstall` — 버전 미고정**
    - 서버는 `manifests/install.yaml` 의 `stable`, CLI 는 `releases/latest` 를 받음
    - 회차마다 설치 버전이 달라지고 서버·CLI 버전이 어긋날 수 있음 — 실습 회차별로 같은 태그(`vX.Y.Z`)로 고정할 것을 권고
9. **`lab6.Serverless/2.firstFunction` — `registry:2`**
    - 이미지·태그는 현재 존재함(확인). 상위 메이저(3.x)가 나와 있으나 실습 동작에 영향이 확인되지 않아 그대로 둠

### 확인하지 못한 것

* 점검 환경 네트워크 정책으로 아래 도메인은 응답을 받지 못함 — 링크가 살아 있는지 사람이 한 번 열어 볼 것
    - `argoproj.github.io`, `argo-cd.readthedocs.io`
    - `zipkin.io`(quickstart 페이지·`quickstart.sh`)
    - `sdk-for-java.amazonwebservices.com`
    - `get.arkade.dev`, `cli.openfaas.com`, `openfaas.github.io`, `www.openfaas.com`, `docs.openfaas.com`
    - `mirror.navercorp.com`(교체 전 주소), `dockerhub.com`(교체 전 주소)
* `kubectl --dry-run=client` 는 점검 환경에 kubectl 이 없어 돌리지 못함(kubeconform 으로 대체)

### 존재를 확인한 것

* GitHub 저장소·경로 : `argoproj/argocd-example-apps`(master, `helm-guestbook/values.yaml`), `nowage/dockers`(`nginx2/Dockerfile`), `Finfra/terraform_quickstart`, `openzipkin/brave-example`(`webmvc4-boot`), `openzipkin/zipkin-aws`(`module/README.md`)
* 내려받기 : Argo CD `install.yaml`(stable)·`argocd-linux-amd64`(latest), `bitbucket.org/jgnam/gradle_base`·`webapp_maven_deploy`, Maven Central 의 `apache-maven-3.8.1-bin.zip`
* 이미지 : `ghcr.io/openzipkin/zipkin-slim:latest`, `registry:2`
* OpenFaaS : 차트 values 의 `functionNamespace`·`generateBasicAuth`·`gateway.replicas`·`queueWorker.replicas` 키 존재, 템플릿 `node20` 존재
