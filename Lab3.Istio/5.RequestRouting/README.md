* https://istio.io/latest/docs/tasks/traffic-management/request-routing/


# 기존 테스트 결과의 영향을 제거하기 위해 다시 설치
## Uninstall All Example
```
cd ~/istio-*
kubectl delete peerauthentication -n istio-system default

kubectl delete ns foo bar legacy
kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml

istioctl manifest generate --set profile=default | kubectl delete -f -

```

## Install istio system and istio Example
```
cd
curl -L https://git.io/getLatestIstio | sh -
cd ~/istio-*
export PATH=$PWD/bin:$PATH
x=$(cat /etc/bash.bashrc|grep istio|grep bin)
[ ${#x} -eq 0 ]&& echo export PATH=$PWD/bin:$PATH >>/etc/bash.bashrc
istioctl profile list

istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled

kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
istioctl analyze


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
