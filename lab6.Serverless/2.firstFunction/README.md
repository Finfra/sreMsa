# 첫 함수 만들기 — 코드는 얼마나 짧은가

* 함수를 **직접 만들어 빌드·배포·호출**하고, 코드를 고쳐 다시 올리는 순환까지 경험합니다.
* 강의 자료가 말한 *"애플리케이션만 남는다"* 를 코드 줄 수로 확인하는 실습입니다.

* **먼저 이해할 것 — 함수도 결국 컨테이너 이미지입니다.**
    - `faas-cli up` 한 번은 사실 **세 가지**를 합니다: `build`(이미지 생성) → `push`(저장소에 올리기) → `deploy`(클러스터에 배포).
    - 그래서 **이미지를 둘 저장소(registry)가 필요합니다.** 1~2단계에서 그것부터 만듭니다.
    - AWS Lambda 는 이 과정을 플랫폼이 대신 해 줍니다. 직접 해 보면 *"플랫폼이 무엇을 대신해 주고 있었는지"* 가 보입니다.

## 1. 이미지 저장소 만들기 [vm01에서 실행]

* 교육장 회선을 쓰지 않도록 **클러스터 안에** 저장소를 하나 띄웁니다.

```
kubectl create ns registry

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: registry
spec:
  replicas: 1
  selector:
    matchLabels: {app: registry}
  template:
    metadata:
      labels: {app: registry}
    spec:
      containers:
      - name: registry
        image: registry:2
        ports:
        - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: registry
spec:
  type: NodePort
  selector: {app: registry}
  ports:
  - port: 5000
    targetPort: 5000
    nodePort: 30500
EOF
```

* 확인 :
```
kubectl get pods -n registry
```
```
NAME                        READY   STATUS    RESTARTS   AGE
registry-846d97b78b-m57f2   1/1     Running   0          40s
```

## 2. 노드가 이 저장소를 믿게 하기 [vm01에서 실행 — i1 에서 각 노드로]

* 우리 저장소는 https 가 아니라 http 라서, 그냥 두면 노드가 이미지를 받기를 거부합니다.
* **주의 : 이 작업은 `i1` 에서 실행합니다.** 노드 3대에 접속할 키가 i1 에만 있습니다.

```
REG=192.168.56.11:30500

cat > /tmp/hosts.toml <<TOML
server = "http://$REG"

[host."http://$REG"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
TOML

for N in vm01 vm02 vm03; do
  scp /tmp/hosts.toml $N:/tmp/hosts.toml
  ssh $N "sudo mkdir -p '/etc/containerd/certs.d/$REG' && sudo cp /tmp/hosts.toml '/etc/containerd/certs.d/$REG/hosts.toml'"
done
```

* cf) containerd 를 재시작하지 않아도 됩니다. 설정 파일을 **요청할 때마다 읽는** 방식(`config_path`)이기 때문입니다.

## 3. 빌드 환경 준비 [i1에서 실행]

* 이미지를 만들려면 docker 가 필요합니다.

```
sudo apt-get install -y docker.io
sudo usermod -aG docker ubuntu
sudo systemctl enable --now docker

echo '{"insecure-registries": ["192.168.56.11:30500"]}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

* 확인 : 아래에 우리 저장소 주소가 보여야 합니다.
```
sudo docker info | grep -A2 "Insecure Registries"
```

* **주의 : 로그아웃 후 다시 접속해야 `sudo` 없이 `docker` 를 쓸 수 있습니다.** 그 전까지는 `sudo docker` 로 실행하십시오.

## 4. 함수 만들기 [i1에서 실행]

```
faas-cli login --username admin --password-stdin   # 비밀번호는 1.openfaasInstall 참고
export OPENFAAS_URL=http://192.168.56.11:31112

mkdir -p ~/fnlab && cd ~/fnlab
faas-cli template pull
faas-cli new hi --lang node20
```

* 만들어진 것을 봅니다.
```
cat hi/handler.js
```
```javascript
'use strict'

module.exports = async (event, context) => {
  const result = {
    'body': JSON.stringify(event.body),
    'content-type': event.headers["content-type"]
  }

  return context
    .status(200)
    .succeed(result)
}
```

* ★ **12줄입니다.** 서버 설정도, 포트 바인딩도, 프레임워크 초기화도 없습니다. 강의에서 말한 *"애플리케이션만 남는다"* 가 이것입니다.

## 5. 저장소 주소 지정 [i1에서 실행]

* 만들어진 `stack.yaml` 의 이미지 이름을 **우리 저장소 주소로** 바꿉니다.

```
cat stack.yaml
```

* `image:` 와 `gateway:` 두 줄을 아래처럼 고칩니다.
```yaml
version: 1.0
provider:
  name: openfaas
  gateway: http://192.168.56.11:31112
functions:
  hi:
    lang: node20
    handler: ./hi
    image: 192.168.56.11:30500/hi:latest
```

* **주의 : 이미지 이름 앞에 저장소 주소가 붙어야 합니다.** `hi:latest` 로 두면 Docker Hub 로 올리려다 실패합니다.

## 6. 빌드·배포·호출 [i1에서 실행]

```
faas-cli up -f stack.yaml
```

* 확인 : 세 단계가 차례로 보이고 마지막에 URL 이 나옵니다.
```
[0] < Pushing hi [192.168.56.11:30500/hi:latest] done.
Deploying: hi.
Deployed. 202 Accepted.
URL: http://192.168.56.11:31112/function/hi
```

* 불러 봅니다.
```
curl $OPENFAAS_URL/function/hi
```
```
{"body":"{}","content-type":"text/plain"}
```

* 저장소에 이미지가 올라갔는지도 확인할 수 있습니다.
```
curl http://192.168.56.11:30500/v2/_catalog
```
```
{"repositories":["hi"]}
```

## 7. 코드를 고쳐 다시 올리기 [i1에서 실행]

* 함수는 고쳐서 다시 올리는 것이 빠릅니다. 직접 해 봅니다.

```
cat > hi/handler.js <<'EOF'
'use strict'

module.exports = async (event, context) => {
  const name = event.body && event.body.name ? event.body.name : 'world'
  return context
    .status(200)
    .succeed({ message: `Hello, ${name}!`, at: new Date().toISOString() })
}
EOF

faas-cli up -f stack.yaml
```

* 확인 : 이름을 넣어 불러 봅니다.
```
curl -H "Content-Type: application/json" -d '{"name":"sreMsa"}' $OPENFAAS_URL/function/hi
```
```
{"message":"Hello, sreMsa!","at":"2026-09-11T15:39:25.856Z"}
```

* ★ **이 핸들러는 8줄입니다.** 고치고 → 올리고 → 확인하는 순환이 이 실습의 핵심입니다.

## 8. 참고 — 다른 언어 템플릿

```
faas-cli template store list
```

* `node20`·`java11`·`java17`·`php8`·`python3-http` 등이 있습니다.
* ⚠️ **`java17` 템플릿은 현재 빌드되지 않습니다.** 템플릿이 쓰는 베이스 이미지(`openjdk:17-jdk-slim`)가 Docker Hub 에서 사라졌기 때문입니다(openjdk 공식 이미지 deprecated). 이 실습에서 `node20` 을 쓰는 이유입니다.
    - cf) 이런 일은 드물지 않습니다. **외부 이미지·저장소에 의존하면 어느 날 조용히 죽습니다.** 운영에서 이미지를 자체 저장소에 미러링하는 이유이기도 합니다.

## 9. 다음 단계

* `3.coldStart` — 첫 호출이 왜 느린지 직접 재 봅니다.
