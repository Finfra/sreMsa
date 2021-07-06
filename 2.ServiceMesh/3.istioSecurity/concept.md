[**원문: https://istio.io/docs/concepts/security/**](https://istio.io/docs/concepts/security/)
[**번역자 원문: https://github.com/mrha99/istio-security/edit/master/concept.md)
<br>

Monolithic 애플리케이션을 원자 서비스로 세분화하면 대응력 향상, 확장성 향상, 서비스 재사용 능력 향상 등 다양한 이점을 얻을 수 있다. 그러나 **마이크로 서비스에는 다음과 같은 특정 보안 요구 사항**도 있다.

- man-in-the-middle attack를 방어하기 위해서는 Traffic 암호화가 필요
- 유연한 서비스 접근 제어를 위해서는 상호 TLS(Mutual TLS)와 세분화된 접근 정책(fine-grained access policies)이 필요하다.
- 누가 언제 무엇을 했는지 감사하기 위해서는 감사 도구가 필요하다.

Istio Security는 이러한 모든 문제를 해결하기위한 포괄적 인 보안 솔루션을 제공하려고합니다.

이 페이지는 Istio 보안 기능을 사용하여 서비스를 어디에서 실행하든 보안을 유지하는 방법에 대한 개요를 제공한다. 특히 **Istio 보안은 data, endpoints, communication 및 platform에 대한 내부 및 외부 위협(insider and external threats)을 모두 완화**한다.

![](https://istio.io/docs/concepts/security/overview.svg)
<center><i>Istio Security Overview</i></center>

## High-level architecture

Istio의 보안에는 여러 가지 구성 요소가 포함된다.

- Key 및 인증서 관리를 위한 Citadel
- 클라이언트와 서버 간의 안전한 통신을 구현하기 위한 Sidecar 및 주변 proxies (perimeter proxies)
- Authentication 정책을 배포하고 프록시에 이름 정보를 안전하게 지정하기 위한 Pilot
- Mixer를 통해 Authorization 및 Auditing

![](https://istio.io/docs/concepts/security/architecture.svg)
<center><i>Istio Security Architecture</i></center>

## Istio identity

ID(Identity)는 모든 보안 인프라의 기본 개념입니다. service-to-service communication의 시작에서 양 당사자는 **상호 인증(mutual authentication) 목적으로 신원(identity) 정보와 신임 정보(credentials)를 교환**해야합니다.

클라이언트 측에서는 **서버의 신원(identity)을 보안 명명 정보(secure naming information)와 대조하여 인증 된 서비스 Runner인지** 확인합니다.

 서버 측에서는 서버가 **인증 정책(authorization policies)을 기반으로 클라이언트가 액세스 할 수있는 정보를 결정**하고, 누가 언제 어떤 시간에 액세스했는지, 사용한 서비스를 기반으로 고객에게 요금을 청구하고, 청구서를 지불하지 않은 클라이언트를 서비스를 액세스하지 못하도록 거부 할 수 있습니다.

Istio ID(identity) 모델에서 Istio는 **First-class 서비스 (identity)를 사용하여 서비스의 ID를 결정**합니다. 따라서 사용자, 개별 서비스 또는 서비스 그룹을 나타낼 수있는 뛰어난 유연성과 세분성이 제공됩니다. 이러한 ID를 사용할 수없는 플랫폼에서는 Istio가 서비스 이름과 같은 서비스 인스턴스를 그룹화 할 수있는 다른 ID를 사용할 수 있습니다.

다른 플랫폼의 Istio 서비스 ID :

- Kubernetes : Kubernetes service account
- GKE / GCE : GCP service account를 사용할 수 있습니다.
- GCP : GCP service account
- AWS : AWS IAM user/role account
- On-premises (non-Kubernetes) : user account, custom service account, 서비스 이름, Istio service account 또는 GCP service account. custom service account는 고객의 ID 디렉터리에서 관리하는 ID와 마찬가지로 기존 service account을 참조합니다.

## Istio security vs SPIFFE

SPIFFE<sup id="a1">[1](#f1)</sup> 표준은 이기종 환경 전반에서 서비스에 대한 ID를 bootstrapping하고 발급할 수 있는 프레임워크에 대한 규격을 제공한다.

><b id="f1">
<sup>1</sup></b>["SPIFFE"](https://spiffe.io/spiffe/) : Secure Production Identity Framework for Everyone<br>

![](https://kubeedge.io/en/blog/secure-kubeedge/images/reg.png)
![](https://kubeedge.io/en/blog/secure-kubeedge/images/node1.png)
![](https://kubeedge.io/en/blog/secure-kubeedge/images/node2.png)
![](https://kubeedge.io/en/blog/secure-kubeedge/images/wattest.png)
![](https://kubeedge.io/en/blog/secure-kubeedge/images/sb1.png)
![](https://kubeedge.io/en/blog/secure-kubeedge/images/sb2.png)
![](https://kubeedge.io/en/blog/secure-kubeedge/images/sb3.png)


Istio와 SPIFFE는 동일한 ID 문서를 공유합니다 : SVID (SPIFFE Verifiable Identity Document). 예를 들어 Kubernetes에서 X.509 인증서의 URI 필드는 <span style="color:red">spiffe://<domain\>/ns/\<namespace\>/sa/\<serviceaccount\></span> 형식입니다. 이를 통해 Istio 서비스는 다른 SPIFFE 호환 시스템과의 연결을 설정하고 수락 할 수 있습니다.

SPIFFE의 구현인 Istio security와 SPIRE는 PKI 구현내역에 차이가 있다. Istio는 인증(authentication), 권한 부여(authorization) 및 감사(auditing) 등 보다 포괄적인 보안 솔루션을 제공합니다.



## PKI

Istio PKI는 **Istio Citadel 위에 구축**되어 모든 작업 부하에 강력한 ID를 안전하게 제공합니다. Istio는 X.509 인증서를 사용하여 ID를 [SPIFFE](https://spiffe.io/) 형식으로 전달합니다. 또한 PKI는 규모에 따른 키 및 인증서 순환을 자동화합니다.

Istio는 Kubernetes pods와 on-premises 시스템에서 실행되는 서비스를 지원합니다. 현재 각 시나리오마다 서로 다른 인증서 Key 공급 메커니즘을 사용합니다.

### Kubernetes scenario

1. Citadel은 Kubernetes <span style="color:red">apiserver</span>를 감시하고 기존 및 새로운 서비스 계정 각각에 대해 SPIFFE 인증서와 Key pair를 생성합니다. Citadel은 [Kubernetes의 secrets](https://kubernetes.io/docs/concepts/configuration/secret/)로 인증서와 키 쌍을 저장합니다.
2. Pod를 만들면 Kubernetes는 [Kubernetes secret volume](https://kubernetes.io/docs/concepts/storage/volumes/#secret)을 통해 Service Account에 따라 포드에 인증서 및 키 쌍을 마운트합니다.
3. Citadel은 각 인증서의 수명을 감시하고 Kubernetes secrets를 다시 작성하여 인증서를 자동으로 회전합니다.
4. Pilot은 특정 서비스를 실행할 수 있는 Service Account를 정의하는 [secure naming](https://istio.io/docs/concepts/security/#secure-naming) information을 생성합니다. Pilot은 secure naming information을 sidecar Envoy에게 전달합니다.

## On-premises machines scenario

1. Citadel은 [CSR (Certificate Signing Requests)](https://en.wikipedia.org/wiki/Certificate_signing_request)을 취할 수있는 gRPC 서비스를 만듭니다.
2. 노드 에이전트는 개인 키와 CSR을 생성하고 자격 증명이있는 CSR을 Citadel에 보내 서명합니다.
3. Citadel은 CSR과 함께 전달 된 자격 증명의 유효성을 검사하고 CSR에 서명하여 인증서를 생성합니다.
4. 노드 에이전트는 Citadel에서받은 인증서와 개인 키를 Envoy로 보냅니다.
5. 위의 CSR 프로세스는 인증서 및 키 순환을 위해 주기적으로 반복됩니다.

## Node agent in Kubernetes

Istio는 아래 그림과 같이 Kubernetes의 노드 에이전트를 인증서 및 키 프로비저닝에 사용하는 옵션을 제공합니다. 가까운 장래에 on-premises 시스템에 대한 ID 제공 플로우가 유사 할 것이라는 점을 유의하십시오. 여기서 Kubernetes 시나리오 만 설명합니다.

![](https://istio.io/docs/concepts/security/node_agent.svg)
<center><i>PKI with node agents in Kubernetes</i></center>
<br>


흐름은 다음과 같이 진행됩니다.

1. Citadel은 CSR 요청을 처리하기 위해 gRPC 서비스를 만듭니다.
2. Envoy는 Envoy Secret Discovery Service (SDS) API를 통해 인증서와 키 요청을 보냅니다.
3. 노드 에이전트는 SDS 요청을 수신하면 자격 증명이있는 CSR을 Citadel에 보내 서명하기 전에 개인 키와 CSR을 생성합니다.
4. Citadel은 CSR에 포함 된 자격 증명의 유효성을 검사하고 CSR에 서명하여 인증서를 생성합니다.
5. 노드 에이전트는 Citadel에서받은 인증서와 개인 키를 Envoy SDS API를 통해 Envoy로 보냅니다.
6. 위의 CSR 프로세스는 인증서 및 키 순환을 위해 주기적으로 반복됩니다.

## Best practices

In this section, we provide a few deployment guidelines and discuss a real-world scenario.

이 섹션에서는 몇 가지 배포 지침을 제공하고 실제 시나리오에 대해 설명합니다.

## Deployment guidelines

중형(medium-size) 또는 대형(large-size) 클러스터에서 서로 다른 서비스를 배포하는 서비스 운영자 (a.k.a. [SRE](https://en.wikipedia.org/wiki/Site_Reliability_Engineering))가 여러 명인 경우 각 SRE 팀마다 별도의 [Kubernetes 네임 스페이스](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/)를 만들어 액세스를 격리하는 것이 좋습니다. 예를 들어 <span style="color:red">team1</span>에 대한 <span style="color:red">team1-ns</span> 네임 스페이스와 <span style="color:red">team2</span>에 대한 <span style="color:red">team2-ns</span> 네임 스페이스를 만들 수 있으므로 두 팀이 서로의 서비스에 액세스 할 수 없습니다.

> Citadel이 손상된 경우 클러스터의 모든 관리 키와 인증서가 노출 될 수 있습니다. Citadel을 전용 네임 스페이스 (예 : <span style="color:red">istio-citadel-ns</span>)에서 실행하여 클러스터에 대한 액세스를 관리자에게만 제한하는 것이 좋습니다.

## Example

<span style="color:red">photo-frontend, photo-backend</span> 및 <span style="color:red">datastore</span>의 세 가지 서비스로 구성된 3 계층 응용 프로그램을 생각해 봅시다. Photo SRE 팀은 <span style="color:red">photo-frontend 및 photo-backend</span> 서비스를 관리하고 데이터 저장소 SRE 팀은 <span style="color:red">데이터 저장소</span> 서비스를 관리합니다. <span style="color:red">photo-frontend</span> 서비스는 <span style="color:red">photo-backend</span>에 액세스 할 수 있고 <span style="color:red">photo-backend</span> 서비스는 <span style="color:red">데이터 저장소</span>에 액세스 할 수 있습니다. 그러나 <span style="color:red">photo-frontend</span> 서비스는 <span style="color:red">데이터 저장소</span>에 액세스 할 수 없습니다.


이 시나리오에서 클러스터 관리자는 <span style="color:red">istio-citadel-ns, photo-ns</span> 및 <span style="color:red">datastore-ns</span>의 세 가지 이름 공간을 만듭니다. 관리자는 모든 네임 스페이스에 액세스 할 수 있으며 각 팀은 고유 한 네임 스페이스에만 액세스 할 수 있습니다. photo SRE 팀은 <span style="color:red">photo-ns</span> 네임 스페이스에서 각각 <span style="color:red">photo-frontend</span> 및 <span style="color:red">photo-backend</span>를 실행하는 두 개의 서비스 계정을 만듭니다. 데이터 저장소 SRE 팀은 하나의 서비스 계정을 만들어 <span style="color:red">datastore-ns</span> 네임 스페이스에서 <span style="color:red">데이터 저장소</span> 서비스를 실행합니다.

또한 [**Istio Mixer**](https://istio.io/docs/concepts/policies-and-telemetry/)에서 <span style="color:red">photo-frontend</span>가 데이터 저장소에 액세스 할 수 없도록 서비스 액세스 제어를 적용해야합니다.

이 설정에서 Kubernetes는 서비스 관리에 대한 운영자 권한을 분리 할 수 ​​있습니다. Istio는 모든 네임 스페이스의 인증서와 키를 관리하고 서비스에 대한 다른 액세스 제어 규칙을 적용합니다.

## Authentication

Istio는 두 가지 유형의 인증을 제공합니다.

- **Transport authentication** (**service-to-service** authentication 이라고도 함) : 직접 클라이언트가 연결을 확인합니다. Istio는 전송 인증을위한 전체 스택 솔루션으로서 [**Mutual TLS**](https://en.wikipedia.org/wiki/Mutual_authentication)를 제공합니다. 서비스 코드를 변경하지 않고도이 기능을 쉽게 켤 수 있습니다. 이 솔루션 :
  - 각 서비스에 클러스터 및 클라우드 간의 상호 운용성을 가능하게하는 역할을 나타내는 강력한 신원 정보(Identity)를 제공합니다.
  - 서비스 간 통신 및 최종 사용자 간 통신을 보호합니다.
  - 키 및 인증서 생성, 배포 및 순환을 자동화하는 키 관리 시스템을 제공합니다.
- **End-user authentication**이라고도하는 **Origin authentication** : 최종 사용자 또는 장치로 요청한 원본 클라이언트를 확인합니다. Istio는 오픈 소스 OpenID Connect 공급자 인 [ORY Hydra](https://www.ory.sh/), [Keycloak](https://www.keycloak.org/), [Auth0](https://auth0.com/), [Firebase Auth](https://firebase.google.com/docs/auth/), [Google Auth](https://developers.google.com/identity/protocols/OpenIDConnect) 및 사용자 정의 인증에 대한 JSON Web Token (JWT) 유효성 검사 및 간소화 된 개발자 경험을 통한 요청 수준 인증을 가능하게합니다.

두 경우 모두 Istio는 사용자 지정 Kubernetes API를 통해 <span style="color:red">Istio config store</span>에 인증 정책을 저장합니다. Pilot은 적절한 경우 각 키와 함께 각 프록시에 대해 최신 정보를 유지합니다. 또한 Istio는 허용 모드에서 인증을 지원하여 정책 변경이 어떻게 적용되는지에 대한 이해를 돕습니다.

## Mutual TLS authentication

Istio는 클라이언트 측과 서버 측 [Envoy proxy](https://www.envoyproxy.io/docs/envoy/latest/)를 통해 서비스 간 통신을 터널링합니다. 클라이언트가 Mutual TLS 인증(authentication)을 사용하여 서버를 호출하려면 다음을 수행하십시오.

1. Istio는 클라이언트의 Outbound 트래픽을 클라이언트의 로컬 Sidecar Envoy로 재 라우팅합니다.
2. 클라이언트 측 Envoy는 서버 측 Envoy와 Mutual TLS 핸드 셰이크를 시작합니다. 핸드 셰이크가 진행되는 동안 클라이언트 측 Envoy는 서버 인증서에 표시된 서비스 계정에 대상 서비스를 실행할 수있는 권한이 있는지 확인하기 위해 [Secure naming](https://istio.io/docs/concepts/security/#secure-naming) 검사도 수행합니다.
3. 클라이언트 측 Envoy와 서버 측 Envoy가 상호 TLS 연결을 설정하고 Istio는 클라이언트 측 Envoy에서 서버 측 Envoy로 트래픽을 전달합니다.
4. 인증(authorization) 후 서버 측 Envoy는 로컬 TCP 연결을 통해 트래픽을 서버 서비스로 전달합니다.

## Permissive mode

Istio 상호 TLS에는 허용 모드(permissive mode)가있어 서비스가 일반 텍스트 트래픽과 Mutual TLS 트래픽을 동시에 받아 들일 수 있습니다. 이 기능은 Mutual TLS onboarding 경험을 크게 향상시킵니다.

non-Istio 서버와 통신하는 많은 non-Istio 클라이언트는 상호 TLS가 활성화 된 Istio로 해당 서버를 마이그레이션하려는 운영자에게 문제점을 제시합니다. 일반적으로 운영자는 모든 클라이언트에 대해 Istio 사이드카를 동시에 설치할 수 없거나 일부 클라이언트에서 Istio 사이드카를 설치할 권한이 없습니다. 서버에 Istio 사이드카를 설치 한 후에도 운영자는 기존 통신을 중단하지 않고 상호 TLS를 사용할 수 없습니다.

허용 모드를 사용하면 서버는 일반 텍스트 및 상호 TLS 트래픽을 모두 허용합니다. 이 모드는 onboarding 절차에 큰 유연성을 제공합니다. 서버에 설치된 Istio Sidecar는 기존 일반 텍스트 트래픽을 손상시키지 않고 즉시 상호 TLS 트래픽을 처리합니다. 결과적으로 운영자는 점차 클라이언트의 Istio Sidecar를 설치 및 구성하여 상호 TLS 트래픽을 전송할 수 있습니다. 클라이언트의 구성이 완료되면 운영자는 서버를 상호 TLS 전용 모드로 구성 할 수 있습니다. 자세한 내용은 상호 [TLS 마이그레이션 자습서](https://istio.io/docs/tasks/security/mtls-migration/)를 참조하십시오.

## Secure naming

Secure naming 정보에는 인증서로 인코딩 된 서버 ID의 검색 서비스 또는 DNS에서 참조하는 서비스 이름에 대한 N 대 N 매핑이 포함됩니다. ID <span style="color:red">A</span>에서 서비스 이름 <span style="color:red">B</span> 로의 맵핑은 "<span style="color:red">A</span>가 허용되고 서비스 <span style="color:red">B</span>를 실행할 수있는 권한이 있음"을 의미합니다. Pilot은 Kubernetes <span style="color:red">apiserver</span>를 감시하고 Secure naming 정보를 생성하며 안전하게 Sidecar Envoys에 배포합니다. 다음 예는 인증(authentication)에서 Secure naming이 중요한 이유를 설명합니다.

서비스 <span style="color:red">데이터 저장소</span>를 실행하는 합법적인(legitimate) 서버가 <span style="color:red">인프라 팀</span> ID 만 사용한다고 가정합니다. 악의적인(malicious) 사용자는 <span style="color:red">테스트 팀</span> ID에 대한 인증서와 키를 가지고 있습니다. 악의적인 사용자는 클라이언트에서 보낸 데이터를 검사하기 위해 서비스를 가장하려고합니다. 악의적 인 사용자는 <span style="color:red">테스트 팀</span> ID에 대한 인증서와 키가있는 위조 된 서버를 배포합니다. 악의적 인 사용자가 <span style="color:red">데이터 저장소</span>로 전송 된 트래픽을 성공적으로 hijacked (through DNS spoofing, BGP/route hijacking, ARP spoofing, etc.)하여 위조 된 서버로 리디렉션했다고 가정합니다.

클라이언트가 <span style="color:red">데이터 저장소</span> 서비스를 호출하면 서버 인증서에서 <span style="color:red">테스트 팀</span> ID를 추출하고 <span style="color:red">테스트 팀</span>이 보안 명명 정보로 <span style="color:red">데이터 저장소</span>를 실행할 수 있는지 확인합니다. 클라이언트는 <span style="color:red">테스트 팀</span>이 <span style="color:red">데이터 저장소</span> 서비스를 실행할 수 없으며 인증이 실패 함을 감지합니다.

Secure naming은 HTTPS 트래픽에 대한 일반적인 network hijacking을 방지 할 수 있습니다. 또한 DNS spoofing을 제외한 일반적인 network hijacking에서 TCP 트래픽을 보호 할 수 있습니다. 공격자가 DNS를 가로 채고 목적지의 IP 주소를 변경하면 TCP 트래픽에 대해 작동하지 않습니다. 이는 TCP 트래픽에 호스트 이름 정보가 포함되어 있지 않기 때문에 라우팅을 위해 IP 주소에만 의존 할 수 있기 때문입니다. 그리고이 DNS 도용(hijack)은 클라이언트 쪽 Envoy가 트래픽을 받기 전에도 발생할 수 있습니다.

## Authentication architecture

인증 정책을 사용하여 Istio 메시에서 요청을 수신하는 서비스에 대한 인증 요구 사항을 지정할 수 있습니다. 메쉬 운영자는 <span style="color:red">.yaml</span> 파일을 사용하여 정책을 지정합니다. 정책은 일단 배포되면 Istio 구성 저장소에 저장됩니다. Istio 컨트롤러 인 Pilot은 구성 저장 장치를 감시합니다. 정책이 변경되면 Pilot은 새 정책을 적절한 구성으로 변환하여 Envoy Sidecar Proxy에 필요한 인증 메커니즘을 수행하는 방법을 알려줍니다. Pilot은 공개 키를 가져 와서 JWT 유효성 검사를위한 구성에 첨부 할 수 있습니다. 또는 Pilot은 Istio 시스템이 관리하는 키와 인증서에 대한 경로를 제공하고 이를 상호 TLS 용 Application pod에 설치합니다. 자세한 내용은 PKI 섹션을 참조하십시오. Istio는 대상 엔드 포인트에 구성을 비동기적으로 전송합니다. 프록시가 구성을 수신하면 새 인증 요구 사항이 해당 Pod에서 즉시 적용됩니다.

요청을 보내는 클라이언트 서비스는 필요한 인증 메커니즘을 수행 할 책임이 있습니다. origin authentication (JWT)의 경우, 애플리케이션은 JWT credential을 획득하여 요청에 첨부해야합니다. 상호 TLS(mutual TLS)의 경우 Istio는 대상 규칙(destination rule)을 제공합니다. 운영자는 [destination rule](https://istio.io/docs/concepts/traffic-management/#destination-rules)을 사용하여 클라이언트 프록시가 서버 측에서 예상되는 인증서로 TLS를 사용하여 초기 연결을하도록 지시 할 수 있습니다. Mutual TLS authentication에서 Istio에서 상호 TLS가 작동하는 방법에 대해 자세히 알아볼 수 있습니다.

<center>

![](https://istio.io/docs/concepts/security/authn.svg)
*Authentication Architecture*
</center>

Istio는 두 가지 유형의 인증뿐만 아니라 자격 증명의 다른 클레임을 사용하여 다음 계층에 ID를 출력합니다. 또한 운영자는 전송(transport) 또는 원본 인증(origin authentication)에서 Istio가 '주체(principal)'로 사용할 ID를 지정할 수 있습니다.

### Authentication policies

이 섹션에서는 Istio 인증 정책(Istio authentication policies)의 작동 방식에 대해 자세히 설명합니다. 아키텍처 섹션에서 기억 하듯이 인증 정책(authentication policies)은 서비스가 **받는** 요청에 적용됩니다. 상호 TLS에서 클라이언트 측 인증 규칙(authentication policies)을 지정하려면 <span style="color:red">DestinationRule</span>에 <span style="color:red">TLSSettings</span>를 지정해야합니다. 자세한 내용은 TLS 설정 참조 설명서를 참조하십시오. 다른 Istio 구성과 마찬가지로 <span style="color:red">.yaml</span> 파일에 인증 정책을 지정할 수 있습니다. <span style="color:red">kubectl</span>을 사용하여 정책을 배포합니다.

다음 예제 인증 정책은 검토 서비스에 대한 전송 인증(transport authentication)이 상호 TLS를 사용해야 함을 지정합니다.

```javascript

    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
        name: "reviews"
    spec:
        targets:
        - name: reviews
        peers:
        - mtls: {}

```

### Policy storage scope

Istio는 namespace-scope 또는 mesh-scope storage에 인증 정책(authentication policies)을 저장할 수 있습니다.

- Mesh-scope policy는 kind 필드에 "MeshPolicy"값을, "default"라는 이름으로 지정됩니다. For example:

```javascript

    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "MeshPolicy"
    metadata:
        name: "default"
    spec:
        peers:
        - mtls: {}

```

- Namespace-scope 정책은 <span style="color:red">kind</span> 필드와 지정된 네임 스페이스에 대해 <span style="color:red">"Policy"</span>값으로 지정됩니다. 지정하지 않으면 기본 네임 스페이스가 사용됩니다. 네임 스페이스 <span style="color:red">ns1</span>의 예를 들면 다음과 같습니다.

```javascript

    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "default"
      namespace: "ns1"
    spec:
      peers:
      - mtls: {}

```

namespace-scope storage의 정책은 동일한 네임 스페이스의 서비스에만 영향을 미칩니다. mesh-scope의 정책은 Mesh의 모든 서비스에 영향을 줄 수 있습니다. 충돌과 오용을 방지하기 위해 mesh-scope storage에 하나의 정책 만 정의 할 수 있습니다. 이 정책은 <span style="color:red">default<span>라는 이름을 가져야하며 empty <span style="color:red">targets:</span> 섹션이 있어야합니다. Google의 target selectors 섹션에 대한 자세한 내용을 확인할 수 있습니다.

Kubernetes는 현재 Custom Resource Definitions (CRDs)에 Istio 구성을 구현합니다. 이러한 CRD는 namespace-scope 및 cluster-scope <span style="color:red">CRDs</span>에 해당하며 Kubernetes RBAC를 통해 액세스 보호를 자동으로 상속합니다. Kubernetes CRD 문서에 대한 자세한 내용을 볼 수 있습니다.

### Target selectors

인증 정책(authentication policy)의 대상은 정책이 적용되는 서비스를 지정합니다. 다음 예제는 정책을 적용 할 대상을 지정하는 <span style="color:red">targets :</span> 섹션을 보여줍니다.

- 모든 Port의 <span style="color:red">product-page</span> service.
- Port <span style="color:red">9000</span>의 리뷰 서비스.

```javascript

    targets:
     - name: product-page
     - name: reviews
       ports:
       - number: 9000

```

<span style="color:red">targets</span> : 섹션을 제공하지 않으면 Istio는 정책의 스토리지 범위에있는 모든 서비스에 정책을 일치시킵니다. 따라서 <span style="color:red">targets :</span> 섹션은 정책의 범위를 지정하는 데 도움을 줄 수 있습니다.

- Mesh-wide policy : target selector 섹션이 없는 mesh-scope storage에 정의 된 정책입니다. **Mesh에는** 최대한 **하나**의 mesh-wide 정책이 있을 수 있습니다.
- Namespace-wide policy : 이름이 default이며 target selector 섹션이 없는 namespace-scope storage에 정의 된 정책입니다. **네임스페이스 당** namespace-wide 정책이 최대한 **하나** 있을 수 있습니다.
- Service-specific policy : 비어 있지 않은 target selector 섹션을 사용하여 namespace-scope storage에 정의 된 정책입니다. 네임 스페이스는 **0 개, 1 개 또는 여러 개**의 서비스 별 정책을 가질 수 있습니다.

각 서비스에 대해 Istio는 narrowest matching 정책을 적용합니다. 순서는 **service-specific > namespace-wide > mesh-wide**입니다. 둘 이상의 서비스 특정 정책이 서비스와 일치하는 경우 Istio는 임의로 서비스 중 하나를 선택합니다. 운영자는 정책을 구성 할 때 이러한 충돌을 피해야합니다.

mesh-wide 및 namespace-wide 정책에 고유성을 적용하기 위해 Istio는 Mesh 당 하나의 인증 정책(authentication policy)과 네임 스페이스 당 하나의 인증 정책 만 허용합니다. 또한 Istio는 mesh-wide 및 namespace-wide 정책에서 특정 이름을 <span style="color:red">default</span>으로 지정해야합니다.

### Transport authentication


The following example shows the peers: section enabling transport authentication using mutual TLS.

<span style="color:red">peers:</span> 섹션은 정책에서 전송 인증(transport authentication)을 위해 지원되는 인증(authentication) 방법 및 관련 매개 변수를 정의합니다. 섹션에는 둘 이상의 메소드를 나열 할 수 있으며 인증(authentication)을 통과하기 위해 하나의 메소드 만 충족시켜야합니다. **그러나 Istio 0.7 릴리스부터 현재 지원되는 전송 인증 (transport authentication) 방법은 상호 TLS (Mutual TLS)뿐입니다.** 전송 인증이 필요하지 않은 경우이 절을 완전히 건너 뛰세요.

다음 예는 상호 TLS를 사용하여 전송 인증을 사용하는 <span style="color:red">peers:</span> 섹션을 보여줍니다.

```javascript

    peers:
      - mtls: {}

```

Currently, the mutual TLS setting doesn’t require any parameters. Hence, -mtls: {}, - mtls: or - mtls: null declarations are treated the same. In the future, the mutual TLS setting may carry arguments to provide different mutual TLS implementations.

현재 상호 TLS 설정에는 parameters가 필요하지 않습니다. 따라서 <span style="color:red">-mtls : {}, - mtls :</span> 또는 <span style="color:red">- mtls : null</span> 선언은 동일하게 취급됩니다. 향후에는 상호 TLS 설정은 서로 다른 TLS 구현을 제공하기 위해 arguments를 수행 할 수 있습니다.

### Origin authentication

<span style="color:red">The origins:</span> 섹션은 origin authentication을 위해 지원되는 인증 메소드 및 관련 Parameters를 정의합니다. Istio는 JWT origin authentication 만 지원합니다. 허용 된 JWT 발급자를 지정하고 특정 경로에 대해 JWT authentication을 활성화 또는 비활성화 할 수 있습니다. 요청 경로에 대해 모든 JWT가 비활성화 된 경우 인증이 정의되지 않은 것처럼 전달됩니다. peer authentication과 마찬가지로, 나열된 메소드 중 하나만 충족시켜 인증을 통과해야합니다.

다음 예제 정책은 Google에서 발행 한 JWT를 허용하는 origin authentication 위한 <span style="color:red">originins:</span> section을 지정합니다. 경로 <span style="color:red">/health</span>에 대한 JWT 인증이 비활성화됩니다.

```javascript

    origins:
    - jwt:
        issuer: "https://accounts.google.com"
        jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
        trigger_rules:
        - excluded_paths:
          - exact: /health

```

## Principal binding

주요 바인딩 key-value 쌍은 정책의 주요 인증(principal authentication)을 정의합니다. 기본적으로 Istio는 <span style="color:red">peers:</span> 섹션에 구성된 인증을 사용합니다. <span style="color:red">peers:</span> 섹션에 인증이 구성되어 있지 않으면 Istio는 인증을 설정 해제합니다. 정책 작성자는 이 동작으로 <span style="color:red">USE_ORIGIN</span> 값을 덮어 쓸 수 있습니다. 이 값은 대신 Istio가 주체 인증(principal authentication)으로 원본 인증(origin’s authentication)을 사용하도록 구성합니다. 나중에 조건부 바인딩을 지원합니다 (예 : Peer가 X 일 때 <span style="color:red">USE_PEER</span>, 그렇지 않으면 <span style="color:red">USE_ORIGIN</span>).

다음 예는 값이 <span style="color:red">USE_ORIGIN</span> 인 <span style="color:red">principalBinding</span> Key를 보여줍니다.

```javascript

    principalBinding: USE_ORIGIN

```

### Updating authentication policies

언제든지 인증 정책을 변경할 수 있으며 **Istio는 거의 실시간으로 변경 사항을 엔드 포인트에 적용**합니다. 그러나 Istio는 **모든 엔드 포인트가 동시에 새 정책을 수신하도록 보장 할 수 없습니다**. 다음은 인증 정책을 업데이트 할 때 방해를 피하기 위한 권장 사항입니다.

- To enable or disable mutual TLS : <span style="color:red">mode:</span> key 및 <span style="color:red">PERMISSIVE</span> value와 함께 임시 policy를 사용하십시오. 두 가지 유형의 트래픽 (일반 텍스트 및 TLS)을 허용하도록 수신 서비스를 구성합니다. 따라서 요청이 삭제되지 않습니다. 모든 클라이언트가 상호 TLS의 유무에 관계없이 예상 프로토콜로 전환하면 <span style="color:red">PERMISSIVE</span> 정책을 최종 정책으로 바꿀 수 있습니다. 자세한 내용은 상호 TLS 마이그레이션 자습서를 참조하십시오.

```javascript

    peers:
    - mtls:
        mode: PERMISSIVE

```

- For JWT authentication migration: 정책을 변경하기 전에 요청에 새 JWT가 있어야합니다. 서버 측에서 새 정책으로 완전히 전환하면 이전 JWT가 있을 경우 제거 할 수 있습니다. 이러한 변경 사항을 적용하려면 클라이언트 응용 프로그램을 변경해야합니다.

## Authorization

Role-based Access Control (RBAC)이라고 하는 Istio의 권한 부여 (Istio’s authorization) 기능은 Istio Mesh에서 서비스에 대한 namespace-level, service-level, and method-level 액세스 제어를 제공합니다. 특징 :

- 간단하고 사용하기 쉬운 역할 기반 의미론 (**Role-Based semantics**).
- **Service-to-service** and **end-user-to-service** authorization.
- **Flexibility through custom properties** support, for example conditions, in roles and role-bindings.
- Istio 인증이 <span style="color:red">Envoy</span>에 기본적으로 적용되므로 **High performance**.
- 호환성이 뛰어나고 (**High compatibility**) HTTP, HTTPS 및 HTTP2를 기본적으로 지원하며 일반 TCP 프로토콜도 지원합니다.

### Authorization architecture

<center>

![](https://istio.io/docs/concepts/security/authz.svg)
*Istio Authorization Architecture*
</center>

위 다이어그램은 기본 Istio authorization architecture를 보여줍니다. 운영자는 <span style="color:red">.yaml</span> 파일을 사용하여 Istio 인증 정책을 지정합니다. 일단 배포되면 Istio는 <span style="color:red">Istio Config Store</span>에 정책을 저장합니다.

Pilot은 Istio authorization 정책의 변경을 감시합니다. 변경 사항이있는 경우 updated authorization policy를 fetch합니다. Pilot은 Istio authorization 정책을 서비스 인스턴스와 함께 배치 된 (co-located with the service instances) Envoy proxies에 배포(Distribute)합니다.

각 Envoy proxy는 런타임시 Request 권한 부여 하는 것을 authorization engine에서 실행합니다. 요청이 프록시에 도달하면 authorization engine은 현재 권한 policy에 대해 요청 컨텍스트를 평가하고 권한 결과 인 <span style="color:red">ALLOW</span> 또는 <span style="color:red">DENY</span>를 리턴합니다.

### Enabling authorization

<span style="color:red">ClusterRbacConfig</span> Object를 사용하여 Istio Authorization을 활성화합니다. <span style="color:red">ClusterRbacConfig</span> Object는 고정 된 이름 값 default를 가지는 cluster-scoped 단일 개체(singleton) 입니다. Mesh에서 하나의 <span style="color:red">ClusterRbacConfig</span> 인스턴스 만 사용할 수 있습니다. 다른 Istio 구성 객체와 마찬가지로 <span style="color:red">ClusterRbacConfig</span>는 Kubernetes <span style="color:red">CustomResourceDefinition</span> [(CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) 객체로 정의됩니다.

<span style="color:red">ClusterRbacConfig</span> 객체에서 연산자는 다음과 같은 <span style="color:red">mode</span> 값을 지정할 수 있습니다.

- <span style="color:red">OFF</span> : Istio 인증이 비활성화됩니다.
- <span style="color:red">ON</span> : 메쉬의 모든 서비스에 대해 Istio 권한이 활성화됩니다.
- <span style="color:red">ON_WITH_INCLUSION</span> : Istio 인증은 포함 필드 (<span style="color:red">inclusion</span> field)에 지정된 서비스 및 네임 스페이스에만 사용할 수 있습니다.
- <span style="color:red">ON_WITH_EXCLUSION</span> : Istio 인증은 제외 필드 (<span style="color:red">exclusion/span> field)에 지정된 서비스와 네임 스페이스를 제외하고 메쉬의 모든 서비스에 대해 활성화됩니다.

다음 예에서 기본 네임 스페이스에 대해 Istio authorization이 사용됩니다.

```javascript

    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ClusterRbacConfig
    metadata:
      name: default
    spec:
      mode: 'ON_WITH_INCLUSION'
      inclusion:
        namespaces: ["default"]

```

### Authorization policy

To configure an Istio authorization policy, you specify a ServiceRole and ServiceRoleBinding. Like other Istio configuration objects, they are defined as Kubernetes CustomResourceDefinition (CRD) objects.

Istio authorization policy를 구성하려면 <span style="color:red">ServiceRole</span>과 <span style="color:red">ServiceRoleBinding</span>을 지정하십시오. 다른 Istio 구성 객체와 마찬가지로, 이들은 Kubernetes <span style="color:red">CustomResourceDefinition<span style="color:red"> [(CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) 객체로 정의됩니다.

- <span style="color:red">ServiceRole</span>은 서비스에 액세스하기위한 권한 그룹을 정의합니다.
- <span style="color:red">ServiceRoleBinding</span>은 사용자, 그룹 또는 서비스와 같은 특정 주제에 <span style="color:red">ServiceRole</span>을 부여합니다.

The combination of ServiceRole and ServiceRoleBinding specifies: who is allowed to do what under which conditions. Specifically:

- who refers to the subjects section in ServiceRoleBinding.
- what refers to the permissions section in ServiceRole.
- which conditions refers to the conditions section you can specify with the Istio attributes in either ServiceRole or ServiceRoleBinding.

<span style="color:red">ServiceRole</span>과 <span style="color:red">ServiceRoleBinding</span>의 조합은 **누가(Who)** **어떤 조건(Which Condition)** 에서 **무엇(What)**을 할 수 있는지를 지정합니다. 구체적으로 :

- <span style="color:red">ServiceRoleBinding</span>의 <span style="color:red">subjects</span> 섹션을 참조하는 **사용자(Who)**.
- <span style="color:red">ServiceRole</span>의 <span style="color:red">permissions</span> 섹션을 참조하는 **무엇(What)**
- 어떤 조건은 <span style="color:red">ServiceRole</span> 또는 <span style="color:red">ServiceRoleBinding</span>에서 Istio 속성으로 지정할 수있는 <span style="color:red">conditions</span> 섹션을 참조하는 **어느 조건 (Which Condition)**

#### <span style="color:red">ServiceRole</span>

<span style="color:red">ServiceRole</span> 사양에는 list of <span style="color:red">rules</span>, AKA permissions 이 포함됩니다. 각 규칙에는 다음과 같은 표준 필드가 있습니다.

- <span style="color:red">services</span> : 서비스 이름 목록. 값을 *로 설정하여 지정된 네임 스페이스의 모든 서비스를 포함 할 수 있습니다.
- <span style="color:red">methods</span> : HTTP 메소드 이름 목록, gRPC 요청에 대한 사용 권한의 경우 HTTP 동사는 항상 POST입니다. 값을 *로 설정하여 모든 HTTP 메소드를 포함 할 수 있습니다.
- <span style="color:red">Path</span> : HTTP 경로 또는 gRPC 메소드. gRPC 메소드는 /packageName.serviceName/methodName 형식이어야하며 대소 문자를 구분합니다.

A ServiceRole specification only applies to the namespace specified in the metadata section. A rule requires the services field and the other fields are optional. If you do not specify a field or if you set its value to *, Istio applies the field to all instances.

<span style="color:red">ServiceRole</span> 사양은 <span style="color:red">metadata</span> 섹션에 지정된 네임 스페이스에만 적용됩니다. 규칙에는 <span style="color:red">service</span> 필드가 필요하고 다른 필드는 선택 사항입니다. 필드를 지정하지 않거나 값을 *로 설정하면 Istio는 해당 필드를 모든 인스턴스에 적용합니다.

아래 예제는 간단한 역할을 보여줍니다. <span style="color:red">service-admin</span>은 <span style="color:red">default</span> 네임 스페이스의 모든 서비스에 대한 전체 액세스 권한을가집니다.

```javascript

    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: service-admin
      namespace: default
    spec:
      rules:
      - services: ["*"]

```

Here is another role: products-viewer, which has read, "GET" and "HEAD", access to the service products.default.svc.cluster.local in the default namespace.

여기에는 또 다른 역할이 있습니다. <span style="color:red">"GET"</span> 및 <span style="color:red">"HEAD"</span>를 읽은 <span style="color:red">products-viewer</span>는 <span style="color:red">default</span> 네임 스페이스의 <span style="color:red">products.default.svc.cluster.local</span> 서비스에 액세스합니다.

```javascript

    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: products-viewer
      namespace: default
    spec:
      rules:
      - services: ["products.default.svc.cluster.local"]
        methods: ["GET", "HEAD"]

```

또한 규칙의 모든 필드에 대해 접두어 일치 및 접미사 일치를 지원합니다. 예를 들어, default 네임 스페이스에서 다음 권한으로 tester 역할을 정의 할 수 있습니다.

- 접두사 <span style="color:red">"test-\*"</span> 가 있는 모든 서비스에 대한 전체 액세스 (예 : <span style="color:red">test-bookstore, test-performance, test-api.default.svc.cluster.local</span>).
- <span style="color:red">"\*/reviews"</span> 접미어가 붙은 모든 경로 (예 : <span style="color:red">bookstore.default.svc.cluster.local 서비스의 / books / reviews, / events / booksale / reviews, / reviews</span>)에 대한 읽기 (<span style="color:red">"GET"</span>) 액세스.

```javascript

    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: tester
      namespace: default
    spec:
      rules:
      - services: ["test-*"]
        methods: ["*"]
      - services: ["bookstore.default.svc.cluster.local"]
        paths: ["*/reviews"]
        methods: ["GET"]

```

<span style="color:red">ServiceRole</span>에서 <span style="color:red">namespace + services + paths + methods</span> 의 조합은 **service 또는 services에 액세스하는 방법**을 정의합니다. 경우에 따라 규칙에 대한 추가 조건을 지정해야 할 수도 있습니다. 예를 들어 규칙은 특정 **Version**의 서비스에만 적용되거나 <span style="color:red">"foo"</span>와 같은 특정 **Label**이 있는 서비스에만 적용될 수 있습니다. <span style="color:red">constraints</span>을 사용하여 이러한 조건을 쉽게 지정할 수 있습니다.

예를 들어 다음 <span style="color:red">ServiceRole</span> 정의는 <span style="color:red">request.headers [version]</span>이 이전 <span style="color:red">products-viewer</span> 역할을 확장하는 <span style="color:red">"v1"</span>또는 <span style="color:red">"v2"</span>중 하나라는 제약 조건을 추가합니다. 제약 조건의 지원되는 키 값은 [constraints and properties page](https://istio.io/docs/reference/config/authorization/constraints-and-properties/)에 나열됩니다. 속성이 map 인 경우 (예 : <span style="color:red">request.headers</span>), <span style="color:red">Key</span>는 맵의 항목입니다 (예 : <span style="color:red">request.headers [version]</span>).

```javascript

    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: products-viewer-version
      namespace: default
    spec:
      rules:
      - services: ["products.default.svc.cluster.local"]
        methods: ["GET", "HEAD"]
        constraints:
        - key: request.headers[version]
          values: ["v1", "v2"]

```

### ServiceRoleBinding

<span style="color:red">ServiceRoleBinding</span> 사양에는 다음 두 부분이 포함됩니다.

- <span style="color:red">roleRef</span>는 동일한 네임 스페이스의 <span style="color:red">ServiceRole</span> 리소스를 참조합니다.
- 역할에 할당 된 <span style="color:red">subjects</span> 의 목록.

<span style="color:red">user</span> 또는 <span style="color:red">properties</span> 집합을 사용하여 제목을 명시적으로 지정할 수 있습니다. <span style="color:red">ServiceRoleBinding</span> subject의 특성은 <span style="color:red">ServiceRole</span> 스펙의 제한 조건과 유사합니다. 또한 속성을 사용하면 조건을 사용하여이 역할에 할당 된 일련의 계정을 지정할 수 있습니다. 여기에는 <span style="color:red">Key</span>와 허용되는 값이 포함됩니다. 제약 조건의 지원되는 <span style="color:red">Key</span> 값은 제약 조건 및 속성 페이지에 나열됩니다.

The following example shows a ServiceRoleBinding named test-binding-products, which binds two subjects to the ServiceRole named "product-viewer" and has the following subjects

다음 예제에서는 <span style="color:red">test-binding-products</span>라는 <span style="color:red">ServiceRoleBinding</span>을 보여줍니다. <span style="color:red">ServiceRoleBinding</span>은 두 개의 제목을 <span style="color:red">"product-viewer"</span>라는 ServiceRole에 바인딩하며 다음과 같은 <span style="color:red">subjects</span>가 있습니다

- 서비스 a를 나타내는 서비스 계정, <span style="color:red">"service-account-a"</span>.
- Ingress 서비스 <span style="color:red">"istio-ingress-service-account"</span>를 나타내는 서비스 계정과 JWT <span style="color:red">전자 메일</span> 클레임이 <span style="color:red">"a@foo.com"</span>인 서비스 계정.

```javascript

    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: test-binding-products
      namespace: default
    spec:
      subjects:
      - user: "service-account-a"
      - user: "istio-ingress-service-account"
        properties:
          request.auth.claims[email]: "a@foo.com"
      roleRef:
        kind: ServiceRole
        name: "products-viewer"

```

In case you want to make a service publicly accessible, you can set the subject to user: "*". This value assigns the ServiceRole to all (both authenticated and unauthenticated) users and services, for example:

서비스에 공개적으로 액세스 할 수 있게 하려는 경우 <span style="color:red">subject</span>를 <span style="color:red">user:"*"</span>로 설정할 수 있습니다. 이 값은 <span style="color:red">ServiceRole</span>을 **모든 (인증 된 사용자와 인증되지 않은)** 사용자 및 서비스에 할당합니다. 예를 들면 다음과 같습니다.

```javascript

    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: binding-products-allusers
      namespace: default
    spec:
      subjects:
      - user: "*"
      roleRef:
        kind: ServiceRole
        name: "products-viewer"

```

**인증 된** 사용자와 서비스에만 <span style="color:red">ServiceRole</span>을 할당하려면 대신 <span style="color:red">source.principal:"*"</span>을 사용하십시오. 예를 들면 다음과 같습니다.

```javascript

    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: binding-products-all-authenticated-users
      namespace: default
    spec:
      subjects:
      - properties:
          source.principal: "*"
      roleRef:
        kind: ServiceRole
        name: "products-viewer"

```

### Using Istio authorization on plain TCP protocols

[Service role](https://istio.io/docs/concepts/security/#servicerole) 및 [Service role binding](https://istio.io/docs/concepts/security/#servicerolebinding)의 예는 HTTP 프로토콜을 사용하는 서비스에서 Istio 인증을 사용하는 일반적인 방법을 보여줍니다. 이 예에서는 서비스 역할 및 서비스 역할 바인딩의 모든 필드가 지원됩니다.

Istio 인증은 MongoDB와 같은 일반 TCP 프로토콜을 사용하는 서비스를 지원합니다. 이 경우 HTTP 서비스와 동일한 방식으로 서비스 역할 및 서비스 역할 바인딩을 구성합니다. 차이점은 특정 필드, 제약 조건 및 속성은 HTTP 서비스에만 적용된다는 것입니다. 이 필드에는 다음이 포함됩니다.

- 서비스 역할 구성 객체의 <span style="color:red">paths</span> 및 <span style="color:red">methods</span> 필드
- 서비스 역할 바인딩 구성 객체의 <span style="color:red">group</span> 필드입니다.

지원되는 제한 조건 및 특성은 [constraints and properties page](https://istio.io/docs/reference/config/authorization/constraints-and-properties/)에 나열됩니다.

TCP 서비스에 대해 HTTP 전용 필드를 사용하는 경우 Istio는 서비스 역할 또는 서비스 역할 바인딩 사용자 지정 리소스와 완전히 설정된 정책을 무시합니다.

다음 예는 Istio 메쉬의 <span style="color:red">bookinfo-ratings-v2</span>가 MongoDB 서비스에 액세스 할 수 있도록 허용하는 서비스 역할과 서비스 역할 바인딩을 27017 포트에 MongoDB 서비스가 있다고 가정합니다.

```javascript

    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: mongodb-viewer
      namespace: default
    spec:
      rules:
      - services: ["mongodb.default.svc.cluster.local"]
        constraints:
        - key: "destination.port"
          values: ["27017"]
    ---
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-mongodb-viewer
      namespace: default
    spec:
      subjects:
      - user: "cluster.local/ns/default/sa/bookinfo-ratings-v2"
      roleRef:
        kind: ServiceRole
        name: "mongodb-viewer"

```

### Authorization permissive mode

허가 허용 모드(authorization permissive mode)는 Istio 1.1 릴리스의 실험적 기능입니다. 인터페이스는 향후 릴리스에서 변경 될 수 있습니다.

허가 허용 모드(authorization permissive mode)에서는 프로덕션 환경에서 적용하기 전에 권한 policy를 검증 할 수 있습니다.

전역 권한 부여 구성(global authorization configuration) 및 개별 정책(individual policies)에서 authorization permissive 모드를 사용 가능하게 할 수 있습니다. 전역 권한 부여 구성에서 허용 모드를 설정하면 모든 정책이 자체 설정 모드(their own set mode)와 상관없이 허용 모드로 전환됩니다. 전역 권한 모드를 <span style="color:red">ENFORCED</span> 설정하면 개별 정책에 의해 설정된 적용 모드가 적용됩니다. 모드를 설정하지 않으면, 전역 권한 부여 구성과 개별 정책이 모두 기본적으로 <span style="color:red">ENFORCED</span> 모드로 설정됩니다.

To enable the permissive mode globally, set the value of the enforcement_mode: key in the global Istio RBAC authorization configuration to PERMISSIVE as shown in the following example.

허용 모드를 전역적으로 사용하려면 global Istio RBAC authorization configuration의 <span style="color:red">enforcement_mode:</span> 키 값을 <span style="color:red">PERMISSIVE</span> 설정하십시오 (다음 예 참조).

```javascript

    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ClusterRbacConfig
    metadata:
      name: default
    spec:
      mode: 'ON_WITH_INCLUSION'
      inclusion:
        namespaces: ["default"]
      enforcement_mode: PERMISSIVE

```

특정 정책에 대해 허용 모드를 사용하려면 다음 예와 같이 정책 구성 파일에서 <span style="color:red">mode:</span> 키의 값을 <span style="color:red">PERMISSIVE</span>로 설정하십시오.

```javascript

    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-details-reviews
      namespace: default
    spec:
      subjects:
        - user: "cluster.local/ns/default/sa/bookinfo-productpage"
      roleRef:
        kind: ServiceRole
        name: "details-reviews-viewer"
      mode: PERMISSIVE

```

### Using other authorization mechanisms

Istio 인증 메커니즘 사용을 강력하게 권장하지만 Istio는 Mixer 구성 요소를 통해 자체 인증 및 권한 부여 메커니즘을 연결할 수 있도록 충분히 유연합니다. Mixer에서 플러그인을 사용하고 구성하려면 [policies and telemetry adapters docs](https://istio.io/docs/concepts/policies-and-telemetry/#adapters)를 방문하십시오.
