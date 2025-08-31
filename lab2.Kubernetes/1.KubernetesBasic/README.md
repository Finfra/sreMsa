# Container 리뷰 및 Docker Hub사용 간단 리뷰
## Docker Run 실습
### Info
* Docker명령어 기본 실습.
* 교육생들이 Docker사용법을 잘 알고 있으면 생략할 것.

### 주의
* 일반 유저 입장에서 실행시 아래 명령 필요
```
sudo groupadd docker
sudo usermod -aG docker $(whoami)
sudo chown -R root:docker /var/run/docker.sock
sudo chmod 777 /var/run/docker.sock
```

### 실행 절차
1. Docker 실행 여부 확인
```
docker
```

2. Docker image검색
```
docker search nginx
```

3. Docker Container 실행
```
mkdir -p ~/df/nginx
echo "hi">~/df/nginx/index.html
# docker rm -f n1
docker run -d                        \
--name n1                            \
-p 80:80                             \
-v ~/df/nginx:/usr/share/nginx/html  \
nginx
```

4. Docker Container 테스트
* PC에서 테스트 하고 싶으면
```
docker ps
curl localhost
echo "hello">~/df/nginx/index.html
curl localhost
```

* cf
```
docker exec -it n1 bash
  exit
docker stop n1
```


5. Docker Docker Container 삭제
```
docker rm -f n1
```
6. Docker Image 삭제
```
docker images
docker rmi nginx
docker images
```

## Docker build 간단 실습
### Info
* Docker Image를 만드고 활용하는 방법을 실습합니다.

### 주의
* https://hub.docker.com 계정 필요
* 명령줄에 "."는 현재 폴더를 의미함 생략하면 안됨.

### 실행 절차
1. 실습용 Console서버에 접속합니다.
2. https://hub.docker.com 에 로그인하고 dockerhub계정을 확인합니다.
3. Git Clone
```
cd
git clone https://github.com/Finfra/dockers
cd dockers/ubuntu_basic
cat Dockerfile

4. Docker Image Build 및 Container생성 테스트
```
docker build --rm -t nowage/ubuntu:test .
docker run -it --rm --name u1 nowage/ubuntu:test
  exit

5. Docker image를 Dockerhub로 Push
```
docker login
  id/password 입력
docker push nowage/ubuntu:test
```

6. https://hub.docker.com 사이트에 업로드된 Image확인



# Kubernetes 개념 소개
* [Kim Chungsub의 쿠버네티스 살펴보기 PT](https://subicura.com/remark/kubernetes-intro.html)
* [쿠터네티스 기초 학습 페이지](https://kubernetes.io/ko/docs/tutorials/kubernetes-basics/)

# Ansible+Terraform Provisiong(Kubespray)
* [Kubernetes Install With Kubespray](https://github.com/Finfra/terraform-course/blob/master/Project/README.md)

# Cluster, Node 상태 조회
```
kubectl cluster-info
kubectl get nodes
```

## Kubectl 명령 잘 쓰는 방법
* --help를 적절히 사용
```
kubectl
  # 명령 옵션 찾음.
kebectl get --help
```
* tab키 활용.
  - "kubectl get nodes" 라는 명령을 실행한다고 하면!
    - "kubec<tab> g<tab> no<tab>"
    - "kubec<tab> g<tab> n<tab><tab><밑의 후보를 보고>o<tab>"


##  각종 정보 얻기
```
kubectl version
kubectl get deployments
kubectl get pods
kubectl get services
kubectl get namespaces
```

## Pods 만들기 : run
```
# kubectl run nginx --image=nginx --port=80
kubectl create deployment --image=nginx --port=80 nginx
kubectl get pods
```

## Pod 접근 : exec
```
kubectl get pods
kubectl logs nginx
kubectl exec nginx -- pwd
kubectl exec nginx -- ls
kubectl exec -it nginx bash
  exit
```

## Expose App Publicly
```
kubectl get services
kubectl expose deployment nginx --type="NodePort" --port 80
kubectl get services
kubectl describe services/nginx
curl 172.33.59.3
kubectl delete services/nginx
```


# Node Scale In, out 등
## Replication set 4개로 늘리기
```
kubectl scale deployment nginx --replicas=4
kubectl get deployments
kubectl get pods -o wide
kubectl describe deployments/nginx
```

## Replication set 2개로 줄이기
```
kubectl scale deployment nginx --replicas=2
kubectl get deployments
kubectl get pods -o wide
```

## -o 옵션으로 yaml생성
```
kubectl get deployments/nginx -o yaml > ~/a.yml
kubectl delete deployments/nginx

kubectl get deployments

kubectl create -f ~/a.yml

kubectl get deployments

kubectl delete deployments/nginx
```


## Daemon set 실습
* yaml 파일 생성
```
cat <<EOF> ~/d.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: httpd
spec:
  selector:
    matchLabels:
      app: httpd
  template:
    metadata:
      labels:
        app: httpd
    spec:
      containers:
      - name: httpd
        image: httpd
        ports:
        - containerPort: 80
          hostPort: 6379
EOF
```
* Demonset 생성 실습
```
kubectl create -f d.yaml
curl vm01:6379
curl vm03:6379
```

* DaemonSet 삭제
```
kubectl delete daemonsets/httpd
```

## 각종 레이블 관리
```
kubectl get pods
kubectl run first-deployment --image=katacoda/docker-http-server --port=80
kubectl get pods
kubectl label pod first-deployment app=v1
kubectl get pods -l app=v1
kubectl delete po/first-deployment
```

## AutoScaling
```
kubectl create deployment --image=nginx --port=80 nginx
kubectl expose deployment nginx --type="NodePort" --port 80
kubectl scale deployment nginx --replicas=4

kubectl get rs
kubectl autoscale rs nginx-7848d4b86f --max=10

```

## Kubernetes 네트워킹 Inspection 명령어 예
```
docker inspect <<tab키로 검색>>
kubectl get pod -o wide
kubectl get service --all-namespaces
docker ps -a
docker inspect --format '{{ .State.Pid }}' <<tab키로 검색>>
nsenter -t <<pid입력>> -n ip addr
conntrack -L -d 10.254.0.1
iptables -t nat -L KUBE-SERVICES
```






# 참고 사항
## Kubernetes Command cheat sheet
* https://kubernetes.io/ko/docs/reference/kubectl/cheatsheet/

### Short-names 
| Short name    |Full name                  |
|---------------|---------------------------|
| po            |pods                       |
| rs            |replicasets                |
| svc           |services                   |
| ns            |namespaces                 |
| no            |nodes                      |
| ep            |endpoints                  |
| ds            |daemonsets                 |
| deploy        |deployments                |
| -             | -                         |
| cm            |configmaps                 |
| cs            |componentstatuses          |
| csr           |certificatesigningrequests |
| ev            |events                     |
| hpa           |horizontalpodautoscalers   |
| ing           |ingresses                  |
| limits        |limitranges                |
| pdb           |poddisruptionbudgets       |
| psp           |podsecuritypolicies        |
| pv            |persistentvolumes          |
| pvc           |persistentvolumeclaims     |
| quota         |resourcequotas             |
| rc            |replicationcontrollers     |
| sa            |serviceaccounts            |
