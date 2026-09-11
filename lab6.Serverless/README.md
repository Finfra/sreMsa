# Agenda

| Folder            | Contents                                           |
| ----------------- | -------------------------------------------------- |
| 1.openfaasInstall | Kubernetes 위에 OpenFaaS CE 설치, faas-cli 로 접속 |
| 2.firstFunction   | 함수를 직접 만들어 빌드·배포·호출                  |
| 3.coldStart       | 첫 요청만 느린 이유 — 콜드 스타트를 직접 측정      |
| 4.autoScale       | 요청이 몰리면 인스턴스가 늘어나는 구간 관찰        |

# 이 실습이 다루는 것

* 강의 **4교시(서버리스 개념과 활용)** 의 실습 편입니다.
* 서버리스를 말로만 듣고 끝내지 않고, **함수 하나를 띄워 놓고 직접 재 봅니다.**
    - 함수 코드가 얼마나 짧은지
    - 첫 호출이 왜 느린지, 얼마나 느린지
    - 요청이 몰릴 때 인스턴스가 어떻게 늘어나는지

# 실습 환경

| 항목          | 값                                 |
| :------------ | :--------------------------------- |
| 런타임        | OpenFaaS **CE**(Community Edition) |
| 설치 위치     | Kubernetes 클러스터 (vm01~vm03)    |
| 함수 빌드     | i1 (실습용 Console서버)            |
| 이미지 저장소 | 클러스터 안에 띄운 registry        |

* **강의 자료는 AWS Lambda 를 예로 듭니다. 이 실습은 로컬 OpenFaaS 입니다.**
    - 개념(이벤트 → 기동 → 실행 → 회수, 콜드 스타트, 오토스케일)은 같습니다.
    - 다만 용어가 1:1 로 맞지는 않으므로, 각 노트에서 *"Lambda 의 무엇에 해당하는가"* 를 짚습니다.
* **CE 에는 "0 으로 줄이기(scale to zero)" 가 없습니다.** 최소 1개를 유지합니다. 이 차이가 `3.coldStart` 에서 중요하게 다뤄집니다.

# 선행 조건

* lab1 을 마쳐 **3개 노드가 `Ready`** 인 클러스터가 있어야 합니다.
* 그 외 준비물은 `2.firstFunction` 안에서 그때그때 설치합니다(registry·docker·faas-cli).

* **Java 는 필요 없습니다.** 이 실습의 함수는 Node.js(`node20`)로 만듭니다.
    - cf) OpenFaaS 에 `java11`·`java17` 템플릿이 있긴 하나 **둘 다 현재 빌드되지 않습니다.** 이유는 `2.firstFunction` 8절에 적었습니다.
    - Java 설치가 필요한 것은 lab5(Zipkin)이며 절차는 [lab5.Zipkin/0.java](../lab5.Zipkin/0.java/1.JavaBasic.md) 에 있습니다.
