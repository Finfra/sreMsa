* https://istio.io/latest/docs/tasks/traffic-management/request-routing/














#  Just test : 재설치 부분에서 실패 TT
## delete Sample
```
kubectl delete peerauthentication -n istio-system default

kubectl delete ns foo bar legacy
kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml
```




## install Sample
```
cd ~/istio-*
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled

kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
istioctl analyze


istioctl analyze # ?!?


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
