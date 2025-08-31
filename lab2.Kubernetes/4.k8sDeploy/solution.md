# Solution
## 1. Deployment를 출력하시오.
```
kubectl get deploy
```
## 2. httpd이미지를 사용하는 h1 Deploy를 생성하시오 (80번 포트 Open)
```
kubectl create deployment --image=httpd --port=80 h1
```

## 3. h1 deploy의 80번 포트를 Service로 Open하시오.
```
kubectl get services
kubectl expose deployment h1 --type="NodePort" --port 80
```

## 4. h1 deploy의 복제 갯수를 3으로 늘리시오.
```
kubectl scale deployment h1 --replicas=3
kubectl get deployments
kubectl get pods -o wide
kubectl describe deployments/h1
```

## 5. 위에서 생성한 모든 deploy,service를 삭제하시오.
```
kubectl delete svc/h1
kubectl delete deploy/h1
kubectl get pods
```
