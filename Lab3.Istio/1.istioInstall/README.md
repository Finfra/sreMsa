# Istio 설치
* Kubernetes의 트래픽 관리와 보안기능을 제공하는 Istio설치를 진행합니다.
* [Getting Started](https://istio.io/latest/docs/setup/getting-started/)
##  설치전 셋팅
* 메모리가 부족할 수 있습니다. 인스턴스 중 한개(vm03추천)를 t2.small이 아닌 t2.medium으로 수정합니다. 
1. 인스턴스를 stop합니다.
2. https://ap-northeast-2.console.aws.amazon.com/ec2/home... 페이지에서 stop된 인스턴스를 선택합니다. 
3. 오른쪽 위 "Action"버튼을 클릭 후 "Instance settings → Change instance type"을 클릭해 New instance type에 "t2.medium"을 입력하고 아래 change버튼을 클릭해 주시면 됩니다.

  - Tip1. k8s작업시는 putty창 하나 열어 놓고, "kubectl get events --watch"명령어 결과 보면서 작업하면 좋습니다. 


## Istio Download and Setting
```
kubectl config set-context --current --namespace=default
cd
curl -L https://git.io/getLatestIstio | sh -
cd istio-1.*
export PATH=$PWD/bin:$PATH
x=$(cat /etc/bash.bashrc|grep istio|grep istio)
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
