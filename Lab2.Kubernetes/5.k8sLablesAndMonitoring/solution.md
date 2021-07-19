# Solution
## 1. 모든 Pods를 출력하시오.
```
kubectl get pods
```

## 2. 아래의 조건을 만족하는 pods를 만드시오.
|pod Name|image Name|
|--------|----------|
|n1      |nginx     |
|u1      |ubuntu    |
|h1      |httpd     |

```
kubectl run n1 --image=nginx
kubectl run u1 --image=ubuntu
kubectl run h1 --image=httpd
```

## 3. 만들어진 pods를 확인하시오.
```
kubectl get pods
```

## 4. ubuntu이미지가 잘 못 만들어진 원인은?

## 5. 아래의 yml파일을 가지고 다시 생성하시오.
```
kubectl delete po/u1
cat <<EOF>u1.yml
apiVersion: v1
kind: Pod
metadata:
  name: u1
  labels:
    server: ubuntu
spec:
  containers:
  - image: ubuntu
    command:
      - "sleep"
      - "604800"
    imagePullPolicy: IfNotPresent
    name: u1
  restartPolicy: Always
EOF
kubectl apply -f u1.yml
```


## 6. pods의 Label이 app=ubuntu인 모든 파드를 출력하시오.
```
kubectl get pods -l server=ubuntu
```

## 7. n1,h1 pods의 label을 server=ubuntu, app=web  이라고 지정하시오.
```
kubectl label po/n1 app=web server=ubuntu
kubectl label po/h1 app=web server=ubuntu
```
## 8. 모든 pods의 label과 함께 출력하시오.
```
kubectl get pods --show-labels
```

## 9. app=web인 Pods만 출력하시오.
```
kubectl get pods -l app=web
```

## 10. Label이 app=web인 모든 Pods를 삭제 하시오.
```
kubectl delete po -l app=web
```

## 11. 모든 파드를 지우시오.
```
kubectl get pods
kubectl delete po/u1
```
* cf)
```
kubectl get pods |awk 'NR>1{print $1}'|xargs -i{} kubectl delete po/{}
```
