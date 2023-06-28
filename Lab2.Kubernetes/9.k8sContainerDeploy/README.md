# helm 기본기
## 설치 (vm01)
```
wget https://get.helm.sh/helm-v3.6.2-linux-amd64.tar.gz
tar -zxvf helm-v3.6.2-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/
rm -rf linux-amd64/
```
or
```
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```


## First Helm Chart
* 기본 helm chart생성 (vm01에서 실행.)
```
mkdir helmx
cd helmx/
helm create mychart
helm install --dry-run --debug --generate-name ./mychart

helm install example ./mychart --set service.type=NodePort

export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services example-mychart)
export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
curl http://$NODE_IP:$NODE_PORT
kubectl get pods
```

* helm chart 수정 후 적용
```
cat ./mychart/values.yaml |sed 's/replicaCount: 1/replicaCount: 2/g' >/tmp/values.yaml
cp /tmp/values.yaml ./mychart/
helm lint ./mychart/
helm install example2 ./mychart --set service.type=NodePort
sleep 10
export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services example2-mychart)
export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
curl http://$NODE_IP:$NODE_PORT
kubectl get pods
```


* packaging
```
helm package ./mychart
```

* packaging된 파일 배포
```
helm install example3 mychart-0.1.0.tgz --set service.type=NodePort
sleep 10
export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services example3-mychart)
export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
curl http://$NODE_IP:$NODE_PORT
```

* 설정 제거
```
helm uninstall example
helm uninstall example2
helm uninstall example3
kubectl get pods
```





## Helm 레포지토리 등록 명령
* 등록
```
helm repo add bitnami https://charts.bitnami.com/bitnami
```
* 조회
```
helm repo list
```
* Chart 찾기
```
helm search repo bitnami | grep tomcat
```
* 업데이트
```
helm repo update
```
* 삭제
```
helm repo remove bitnami
```




## helm으로 Tomcat 동작 repository 생성
```
helm search hub tomcat
helm search hub tomcat -o yaml
# helm repo remove  bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install t1 bitnami/tomcat --set persistence.enabled=false,tomcatAllowRemoteManagement=1
sleep 120
kubectl get svc
echo Password: $(kubectl get secret --namespace default t1-tomcat -o jsonpath="{.data.tomcat-password}" | base64 --decode)
```
* 접속해 브라우저에서 접속해 볼 것. [vm01은 c:\Windows\System32\drivers\etc\hosts 파일에 셋팅필요. ip로 접속해도 무관함.또한 접속 포트는 위 스크립트의 실행 결과 참고할 것]
  - http://vm01:31636/
  - http://vm01:31636/manager

* tomcat 제거
```
helm delete t1
```
