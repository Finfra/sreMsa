* https://istio.io/latest/docs/tasks/traffic-management/request-routing/


# 기존 테스트 결과의 영향을 제거하기 위해 Example 다시 설치
## Uninstall All Example
```
cd ~/istio-*
kubectl delete peerauthentication -n istio-system default

#kubectl delete ns foo bar legacy

kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml

istioctl manifest generate --set profile=default | kubectl delete -f -

kubectl delete ns istio-system

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

```
