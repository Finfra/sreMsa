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
* kubectl get deployment h1 -o yaml > h1.yaml


## 5. replicasets을 확인하시오.
```
kubectl get rs
```

## 6. replicasets의 최대 확장 갯수를 10으로 지정하시오.
```
kubectl autoscale rs h1-5f56cfdc48 --max=10
```
* kubectl get rs h1-5f56cfdc48 -o yaml >h1rs.yaml


## 7. replicasets의 최대 확장 갯수를 확인하시오.
```
kubectl describe horizontalpodautoscalers.autoscaling h1-5f56cfdc48
```
* kubectl get horizontalpodautoscalers.autoscaling h1-5f56cfdc48 -o yaml > h1rsMax.yaml
