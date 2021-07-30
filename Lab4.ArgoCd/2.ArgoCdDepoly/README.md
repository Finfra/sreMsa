# Argo CD Deploy
* Github에 Kubernetes 프로비저닝 스크립트를 업로드하고, ArgoCd를 통해 배포하는 것을 연습합니다.
## Git 리포지토리에서 응용 프로그램 만들기 via argocd cli
```
argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default

kubectl get applications.argoproj.io -n  argocd
```
* 실패 이유는? 실패가 아님 동기화가 안된 것임.

## 애플리케이션 동기화 (배포) via argocd cli
* ArgoCd의 Cli 인터페이스로 App을 동기화하고 확인하는 예제 입니다.
* 1. 동기화
```
argocd app sync guestbook
kubectl get applications.argoproj.io -n  argocd
```

* history 보기
```
argocd app --help
argocd app  history  guestbook
argocd app sync guestbook
argocd app  history  guestbook
```

* 브라우저로 guestbook확인 하기위해 NodePort로 변환
```
kubectl patch svc  guestbook-ui  -p '{"spec": {"type": "NodePort"}}'
```
  - http://vm01:포트입력  # 포트 번호는 argocd app sync guestbook명령의 결과의 URL확인

* service 제거후 sync
```
kubectl delete svc/guestbook-ui
argocd app sync guestbook
kubectl get svc
```


## Git 레포지토리에서 응용 프로그램 만들기 via Web UI
* 웹 UI를 통해서도 App을 배포하고 동기화 할 수 있습니다. 본 예제는 Argo CD의 Web UI를 통해 배포 셋을 만드는 예입니다.

* 0. Argo CD Web UI 접근
```
kubectl get svc -n argocd|grep argocd-server
```
  - 브라우저에서 접속후 로그인 [  argocd cli 로그인 할때 정보와 같음. 비번 변경했으면 변경한 비번 사용 ]

* 1. github 사이트에 로그인
* 2. https://github.com/argoproj/argocd-example-apps.git 접속해서 Fork뜨기.
  - 오른쪽 상단 버튼
* 3. Fort뜬 git Repository 주소 복사해 두기.
* 4. Namespace만들기
```
kubectl create namespace prj2
```
* 5. Argo CD Web UI 접속 후 좌측 상단의 "+ NEW APP" 버튼 클릭
  - Application Name : guestbook2
  - Project : default
  - SYNC POLICY : Autmatic
  - PRUNE PROPAGATION POLICY : background
  - Repository URL : https://github.com/xxxx/argocd-example-apps   ← xxx는 본인의 github 계정
  - Path : helm-guestbook
  - Cluster URL : https://kubernetes.default.svc 선택
  - Namespace : prj2
  - Create 버튼 클릭

## Git 소스 변경후 Deploy실습
* 본 예제는 위해서 Argo CD의 Web UI를 통해 만들어진 배포 셋을 통해 배포를 진행하는 예입니다.

* 1. Fork뜬 자신의 UI의 소스 수정(github UI에서 수정 가능하나 가급적 clone떠서 작업할 것)
    https://github.com/깃-아이디/argocd-example-apps/blob/master/helm-guestbook/values.yaml
      replicaCount: 1 ==> replicaCount: 2 로 수정

* 2. 현재의 pods 확인
```
kubectl get po -n prj2
```

* 3. argocd UI에서 Sync 혹은 5분이상 기다리기

* 4. 변경된 pods 수 확인
```
kubectl get po -n prj2
```

* 시간되면, docker image tag 별 update 실습 진행.
