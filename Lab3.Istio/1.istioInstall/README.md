# Istio 설치
* Kubernetes의 트래픽 관리와 보안기능을 제공하는 Istio설치를 진행합니다.
* [Getting Started](https://istio.io/latest/docs/setup/getting-started/)
## Istio Download and Setting
```
kubectl config set-context --current --namespace=default
cd
curl -L https://git.io/getLatestIstio | sh -
cd istio-1.*
export PATH=$PWD/bin:$PATH
x=$(cat /etc/bash.bashrc|grep istio|grep bin)
[ ${#x} -eq 0 ]&& echo export PATH=$PWD/bin:$PATH >>/etc/bash.bashrc
istioctl profile list
```

## Install Istio
* demo configuration profile 설치
```
istioctl install --set profile=demo -y
# Time Out fail시는 istioctl install --set profile=minimal  -y
```

* 나중에 애플리케이션을 배포 할 때 Istio가 Envoy 사이드카 프록시를 자동으로 삽입하도록 지시하는 네임 스페이스 레이블을 추가합니다.
```
kubectl label namespace default istio-injection=enabled
kubectl get ns --show-labels
```
