# OpenFaaS 설치

* Kubernetes 클러스터 위에 서버리스(FaaS) 플랫폼인 OpenFaaS 를 올립니다.
* OpenFaaS Home : https://www.openfaas.com/
* 문서 : https://docs.openfaas.com/

* **주의 : `arkade install openfaas` 를 쓰지 마십시오.**
    - 인터넷에서 가장 많이 보이는 한 줄 설치지만, 이 명령은 **OpenFaaS Pro** 를 설치합니다(`ghcr.io/openfaasltd/*`).
    - Pro 는 라이선스가 필요하고 gateway 를 3개로 띄우며 **prometheus 가 PersistentVolume 을 요구**해서, 이 실습 환경에서는 `Pending` 상태로 멈춥니다.
    - 아래 절차는 **CE(Community Edition)** 를 helm 으로 설치합니다.

## 1. kubectl 준비 [vm01에서 실행]

* `ubuntu` 계정이 kubectl 을 쓰려면 kubeconfig 가 있어야 합니다. 없으면 `localhost:8080` 으로 붙으려다 거부됩니다.

```
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

* 확인 : 3개 노드가 모두 `Ready` 여야 합니다.
```
kubectl get nodes
```
```
NAME   STATUS   ROLES           AGE   VERSION
vm01   Ready    control-plane   12d   v1.32.13
vm02   Ready    control-plane   12d   v1.32.13
vm03   Ready    <none>          12d   v1.32.13
```

## 2. helm 설치 [vm01에서 실행]

* arkade 는 CLI 도구를 받아오는 데만 씁니다.

```
curl -sLS https://get.arkade.dev | sudo sh
export PATH=$PATH:$HOME/.arkade/bin
arkade get helm
sudo cp $HOME/.arkade/bin/helm /usr/local/bin/
helm version --short
```

* cf) lab2 의 `9.k8sContainerDeploy` 에서 이미 helm 을 설치했다면 이 단계를 건너뛰어도 됩니다.

## 3. OpenFaaS CE 설치 [vm01에서 실행]

```
helm repo add openfaas https://openfaas.github.io/faas-netes/
helm repo update

helm upgrade openfaas --install openfaas/openfaas \
  --namespace openfaas \
  --create-namespace \
  --set functionNamespace=openfaas-fn \
  --set generateBasicAuth=true \
  --set gateway.replicas=1 \
  --set queueWorker.replicas=1
```

* 확인 : 아래 명령을 반복하며 **5개 파드가 모두 `Running`** 이 될 때까지 기다립니다. 2~3분 걸립니다.
```
kubectl get pods -n openfaas
```
```
NAME                            READY   STATUS    RESTARTS   AGE
alertmanager-7746fdfd89-gbjnt   1/1     Running   0          2m
gateway-5f46bbf45d-wplnv        2/2     Running   0          2m
nats-6ddf479847-hkmzs           1/1     Running   0          2m
prometheus-5b77586db6-rqpq8     1/1     Running   0          2m
queue-worker-7dd699f68-zsb92    1/1     Running   0          2m
```

* cf) `gateway` 가 `2/2` 인 것은 게이트웨이와 faas-netes(오퍼레이터)가 한 파드에 함께 있기 때문입니다.
* cf) `alertmanager` 와 `prometheus` 는 장식이 아닙니다. **오토스케일이 이 둘로 동작**합니다(`4.autoScale` 에서 씁니다).

## 4. 게이트웨이 접속 주소 만들기 [vm01에서 실행]

```
kubectl patch svc -n openfaas gateway-external -p '{"spec":{"type":"NodePort"}}'
kubectl get svc -n openfaas gateway-external
```

* **주의 : `127.0.0.1` 로는 붙지 않습니다.** NodePort 는 노드의 실제 IP 에 열리므로 `192.168.56.11` 을 써야 합니다. `127.0.0.1:31112` 로 시도하면 `connection refused` 가 납니다.

```
export OPENFAAS_URL=http://192.168.56.11:31112
echo $OPENFAAS_URL
```

* cf) 이 값은 접속할 때마다 필요하므로 `~/.bashrc` 에 넣어 두면 편합니다.

## 5. faas-cli 설치와 로그인 [vm01에서 실행]

```
arkade get faas-cli
sudo cp $HOME/.arkade/bin/faas-cli /usr/local/bin/

PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode)
echo -n $PASSWORD | faas-cli login --username admin --password-stdin
```

* 확인 :
```
credentials saved for admin http://192.168.56.11:31112
```

* cf) 비밀번호를 다시 보려면 `echo $PASSWORD` 입니다. 웹 UI 는 브라우저에서 `http://192.168.56.11:31112` 로 열 수 있습니다(admin / 위 비밀번호).

## 6. 동작 확인 — 기성 함수 하나 배포 [vm01에서 실행]

* OpenFaaS 는 바로 쓸 수 있는 함수 모음(store)을 제공합니다. 설치가 제대로 됐는지 이것으로 확인합니다.

```
faas-cli store deploy nodeinfo
sleep 30
faas-cli list
```

* 확인 : `Replicas` 가 1 이면 성공입니다.
```
Function                      	Invocations    	Replicas
nodeinfo                      	0              	1
```

* 호출해 봅니다.
```
curl $OPENFAAS_URL/function/nodeinfo
```

## 7. 다음 단계

* `2.firstFunction` — 함수를 직접 만들어 배포합니다.
