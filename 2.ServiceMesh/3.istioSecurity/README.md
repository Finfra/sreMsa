# Mutual TLS Migration
* https://istio.io/latest/docs/concepts/security/
![security overview](https://istio.io/latest/docs/concepts/security/overview.svg)
* https://github.com/mrha99/istio-security
* Mutual TLS Migration : https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/

# Setup
```
cd ~/istio-*
kubectl create ns foo
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo

kubectl create ns bar
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n bar
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n bar

kubectl create ns legacy
kubectl apply -f samples/httpbin/httpbin.yaml -n legacy
kubectl apply -f samples/sleep/sleep.yaml -n legacy

kubectl get namespaces|grep "foo\|bar\|legacy"
```

## Monitoring
* 한번만 각 노드들에 접근합니다.
```
for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
```

* 1초에 한번씩 각 노드들에 접근합니다. [계속 확인해야 하니까 현재 창은 열어 두고 다른 실습 창을 준비합니다.]
```
while true ;do for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done; sleep 1; done
```


## Lock down to mutual TLS by namespace
```
kubectl apply -n foo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
```
* 한번만 각 노드들에 접근합니다.
```
for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
```
* Istio Dashboard가 있는 경우
  * http://vm01:20001 에 접속 → Graph메뉴 선택 → Namespace를 foo,bar,lagacy 선택
  * Display : show[모두 체크]


## Lock down mutual TLS for the entire mesh
```
kubectl apply -n istio-system -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
```
* 한번만 각 노드들에 접근합니다.
```
for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
```
* Istio Dashboard가 있는 경우
  * http://vm01:20001 에 접속 → Graph메뉴 선택 → Namespace를 foo,bar,lagacy 선택
  * Display : show[모두 체크]


## Clean up the example
* Mesh 전체 인증 정책을 제거
```
kubectl delete peerauthentication -n istio-system default
```

* 테스트한 Namespace를 제거
```
kubectl delete ns foo bar legacy
```
