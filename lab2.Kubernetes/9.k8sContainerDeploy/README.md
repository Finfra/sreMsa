# helm 기본기
## tree설치
```
apt install tree
```
## 기본 namespace 변경
```
kubectl config set-context --current --namespace=default
```


## 설치 (vm01)
```
wget https://get.helm.sh/helm-v3.6.2-linux-amd64.tar.gz
tar -zxvf helm-v3.6.2-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/
rm -rf linux-amd64/
```
or (apt — Helm 공식 설치 문서의 Buildkite 저장소. 이 방법은 최신 Helm 이 설치된다)
```
HELM_BUILDKITE_APT_KEY_ID="DDF78C3E6EBB2D2CC223C95C62BA89D07698DBC6"
sudo apt-get install curl gpg --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey > "${TMPDIR:-/tmp}/helm.asc"
# 키 지문이 다르면 중단한다
if [ "$(gpg --import --import-options=show-only --with-colons "${TMPDIR:-/tmp}/helm.asc" \
        | awk -F: '$1 == "fpr" {print $10}' | head -n 1)" != "${HELM_BUILDKITE_APT_KEY_ID}" ]; then
    echo "ERROR: Unexpected Helm APT key ID"
else
    sudo rm -f /etc/apt/sources.list.d/helm-stable-debian.list /usr/share/keyrings/helm.gpg
    sudo install -m 0644 -Dt /etc/apt/keyrings/ "${TMPDIR:-/tmp}/helm.asc"
    sudo tee /etc/apt/sources.list.d/helm-stable-debian.sources > /dev/null <<EOF
Types: deb
URIs: https://packages.buildkite.com/helm-linux/helm-debian/any/
Suites: any
Components: main
Signed-By: /etc/apt/keyrings/helm.asc
EOF
    sudo apt-get update
    sudo apt-get install helm
fi
```


## First Helm Chart
* 기본 helm chart생성 (vm01에서 실행.)
```
mkdir helmx
cd helmx/
helm create mychart
helm install --dry-run --debug --generate-name ./mychart
tree

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



## Helm Repository 관련 명령
* 검색
```
helm search hub tomcat
```
* Repository 등록
```
helm repo add bitnami https://charts.bitnami.com/bitnami
```
* Repository 등록 확인
```
helm repo list
```
* Repository에서 Chart 찾기
```
helm search repo bitnami | grep tomcat
```
* Repository 업데이트
```
helm repo update
```
* Repository 삭제
```
helm repo remove bitnami
```


## helm으로 외부 Repository 동작
```
helm search hub tomcat
helm search hub tomcat -o yaml
# helm repo remove  bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install t1 bitnami/tomcat --set persistence.enabled=false,tomcatAllowRemoteManagement=1,tomcatPassword=my-secure-password

sleep 120
kubectl get svc
echo Password: $(kubectl get secret --namespace default t1-tomcat -o jsonpath="{.data.tomcat-password}" | base64 --decode)
# user / my-secure-password      
```

* bitanami 레포지터리 실패시.
```
helm repo add kubesphere https://charts.kubesphere.io/main
helm install t1 kubesphere/tomcat
# helm pull kubesphere/tomcat --untar 다운로드 받아서 values.yml확인해서 실행.

```


* 접속해 브라우저에서 접속해 볼 것. [vm01은 c:\Windows\System32\drivers\etc\hosts 파일에 셋팅필요. ip로 접속해도 무관함.또한 접속 포트는 위 스크립트의 실행 결과 참고할 것]
  - http://vm01:31636/
  - http://vm01:31636/manager

* tomcat 제거
```
helm delete t1
```
