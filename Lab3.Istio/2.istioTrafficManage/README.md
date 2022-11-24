# Istio Traffic 관리 실습
* 사이드카와 함께 배포되는 컨테이너들을 배포하고 외부에서 들어오는 트래픽이 잘 작동하는지 확인하는 예제입니다.
## Deploy the sample application
* 1. Bookinfo sample application
```
cd ~/istio-1.*
cat samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
# rollback : kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
```
  - https://istio.io/latest/docs/examples/bookinfo/
  - bookinfo no istio
  -
  ![bookinfo no istio](https://istio.io/latest/docs/examples/bookinfo/noistio.svg)
  - bookinfo with istio
  -
  ![bookinfo with istio](https://istio.io/latest/docs/examples/bookinfo/withistio.svg)

* 2. service와 pods확인
  - 각 포드가 준비되면 Istio 사이드카가 함께 배포됩니다.
```
kubectl get services
kubectl get pods
```
* 3. 작동 테스트
```
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
```

## 외부 트래픽에 응용 프로그램 열기
* 1. Application을 Istio 게이트웨이와 연결
```
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```
* 2. configuration 문제가 없는지 확인
```
istioctl analyze

kubectl get svc istio-ingressgateway -n istio-system

export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

export GATEWAY_URL=http://vm01:$INGRESS_PORT
echo gateway url : "$GATEWAY_URL"

```

* Verify external access
```
echo external access : "$GATEWAY_URL/productpage"
```

* productpage에 100번 접근하기
  - 실패하지 않았음을 확인하고, 향후 4.Dashboard에서 트레픽을 확인합니다.
```
for i in $(seq 1 100); do curl -s -o /dev/null "$GATEWAY_URL/productpage"; done
```
