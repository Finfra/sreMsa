

# 1. namespace prj2를 만드시오.
```

kubectl create namespace prj2
```

# 2. 기본 namespace를 prj2로 바꿔서 nginx2라는 deploy를 만드세요.
```
kubectl config set-context --current --namespace=prj2
kubectl get deploy # prj2 ns의 deploy
kubectl get deploy -n default
kubectl get deploy -A
kubectl create deployment nginx2 --image=nginx --port=80
#==  kubectl create deployment nginx2 --image=nginx --port=80 -n prj2
```

# 3. prj2 namesapce의 deploy리스트를 출력하고, namespace default의 deploy리스트 출력해 보세요.
```
kubectl get deploy -n prj2
kubectl get deploy -n default
```
