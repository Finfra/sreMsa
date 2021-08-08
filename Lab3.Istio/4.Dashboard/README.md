# Istio를 통한 K8s 클러스터 접근 실습(외부에서 내부로 접근)
* Istio의 DashBoard 기능을 통해 외부에서 접근하는 트레픽에 대한 플로우를 확인합니다.
## Dashboard start
```
kubectl get namespace
kubectl apply -f samples/addons
kubectl rollout status deployment/kiali -n istio-system
istioctl dashboard kiali --address 0.0.0.0

ping vm01
```

## Local Browser에서 open
* hosts 파일 셋팅 되어 있지 않으면 vm01대신 ip사용할 것.
```
open http://vm01:20001/
```

## Graph Menu 테스트
* Namespace: Default
* Display : show[모두 체크]
```
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

curl -s -o /dev/null "http://vm01:$INGRESS_PORT/productpage"

for i in $(seq 1 1000); do curl -s -o /dev/null "http://vm01:$INGRESS_PORT/productpage"; done
```
* Graph확인
```
for i in $(seq 1 1000); do curl -s -o /dev/null "http://vm01:$INGRESS_PORT/xxx"; done
```


## 일반 Deploy로 Istio 실습
### 테스트할 Namespace를 생성함
```
kubectl create namespace prj1
kubectl label namespace prj1 istio-injection=enabled
kubectl get namespaces --show-labels
```

### 테스트할 deployment 생성
```
kubectl create deployment --image=httpd --port=80 h1 -n prj1
```

###  istio injection을 적용함.
```
kubectl get deployments.apps h1  -n prj1 -o yaml>h1.yaml
istioctl kube-inject -f h1.yaml >h1_inj.yaml
kubectl delete -f h1.yaml
kubectl create -f h1_inj.yaml
```

### Service를 생성하여 외부에서 접근이 가능하게 함.
```
kubectl expose deploy h1 --type=NodePort -n prj1
kubectl get svc -n prj1
```

### 외부 접근 테스트
```
export NodePort=$(kubectl get svc h1 -o jsonpath='{.spec.ports[0].nodePort}'  -n prj1)
curl vm01:$NodePort
for i in $(seq 1000);do curl -s -o /dev/null vm01:$NodePort; done
```

### istio Web UI에서 작동 확인
* http://vm01:20001 에 접속 → Graph메뉴 선택 → Namespace를 prj1으로 선택
* Display : show[모두 체크]

### 트레픽 유발 후 istio에서 Traffic 확인
```
curl vm01:$NodePort      # 정상 작동
curl vm01:$NodePort/xxx  # 이상 작동

for i in $(seq 1000);do curl -s -o /dev/null vm01:$NodePort; done
sleep 60  # istio Web UI에서 작동 확인
for i in $(seq 1000);do curl -s -o /dev/null vm01:$NodePort/xxx; done
sleep 60 # istio Web UI에서 작동 확인
for i in $(seq 1000);do curl -s -o /dev/null vm01:$NodePort; done
sleep 60 # istio Web UI에서 작동 확인
```
