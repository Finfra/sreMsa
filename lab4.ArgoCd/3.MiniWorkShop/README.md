# ArgoCd Mini Workshop
* Git Repository생성부터 Docker Container생성과 ArgoCd배포까지 일련의 작업들을 진행해 봅니다.
* http://github.com 과 http://dockerhub.com 계정이 필요합니다.

## 1. GitRepository생성.
* cf) git clone https://github.com/xxxxxx/MyMSA

## 2. Pc나 실습서버에 Clone
* 실습 서버에서 작업시 docker 명령을 통해 docker 작동여부 확인하고 일반 계정에서 작동안하면 "sudo su - " 명령으로 Root로 로그인해서 작업
```
cd
git clone https://github.com/xxxxxx/MyMSA
```

## 3. Docker Image만들기.
### Sample docker build  구하기.
```
cd
git clone https://github.com/nowage/dockers
```

## 4. MyDocker Image만들기.
```
cd
cp -r dockers/nginx2/ MyMSA/mynginx
cd MyMSA/mynginx/
docker build --rm -t xxxxxx/mynginx:0.1 .
docker images |grep myn
```
* MyMSA/mynginx/README.md에 usage 업데이트

## 5. Docker image push
```
docker run -d --name n1 -p 8888:80 nowage/mynginx:0.1
curl localhost:8888
docker rm -f n1

docker login
docker push xxxxxx/mynginx:0.1


git add -A
git config --global user.email "nowage@gmail.com"
git config --global user.name "Namjunggu"
git commit -m 'initial commit'
git push
```

## 6. yaml artifact 만들기.
```
kubectl create deploy  --image=nowage/mynginx:0.1 n1
kubectl expose deploy n1 --type="NodePort" --port 80
kubectl get deploy n1 -o yaml > n1_deply.yaml
kubectl get service n1 -o yaml > n1_xvc.yaml
cp n1*.yaml ~ubuntu/
chown ubuntu ~ubuntu/n1*.yaml
kubectl delete svc n1
kubectl delete deploy n1
```
* console로 yml파일 가져 오기.[실습용 Console서버에서 구현.]
```
cd ~/MyMSA
cd n1
mkdir n1
cd n1
scp vm01:/home/ubuntu/n1*.yaml ./

```

## 7. github로 push
```
git add -A
git commit -m "initial commit"
## git config --global user.name "Steve J. South(NamJungGu) "
## git config --global user.email "nowage@gmail.com"
git commit -m "initial commit"
git push
```

## 8. Namespace생성
* vm01
```
kubectl create namespace n1
```

## 9. argocd UI접근해서
* Create new
* Sync
