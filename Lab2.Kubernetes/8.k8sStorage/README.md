## NFS 사용예
### nfs-common 설치(실습용 Console서버)
* vm04가 있을 경우 vm04추가
```
for i in vm01 vm02 vm03;do
  ssh ubuntu@$i sudo apt -y install nfs-common
done
```

### vm01 에서 NFS server작업
```
apt update &&  apt-get install -y nfs-kernel-server
```
```
mkdir -m 1777 /share
touch /share/hello.txt
cat <<EOF>  /etc/exports
/share/ *(rw,sync,no_root_squash,subtree_check) # *은 subnet
EOF
exportfs -ra
exportfs
```

### vm01, vm02,vm03 NFS Client 작업
* 안해도 상관 없음...단지 각 노드에서 접근이 가능함을 보여주는 예
```
mount  vm01:/share  /mnt
```

### 단순 pods에서 NFS 사용하기
* 주의 : 각 노드에서 "sudo apt -y install nfs-common" 명령 필수

```
kubectl delete po/nfsnginx
cat <<EOF> nfspod.yml
apiVersion: v1
kind: Pod
metadata:
  name: nfsnginx
spec:
  containers:
  - name: nfsnginx
    image: nginx
    volumeMounts:
    - name: nfsvol
      mountPath: "/usr/share/nginx/html"
  volumes:
  - name : nfsvol
    nfs:
      path: /share
      server: vm01
EOF

kubectl apply -f nfspod.yml


kubectl get pods nfsnginx
kubectl describe po/nfsnginx
```

## 확인
```
echo "hi"> /share/index.html
sleep 10
kubectl  exec -it nfsnginx -- curl 127.0.0.1
```


### Persistent Volume와 Persistent Volume claim을 통한 NFS를 사용하는 Pod생성
* 주의 : 각 노드에서 "sudo apt -y install nfs-common" 명령 필수
```
kubectl delete po/nfsnginx
kubectl delete pvc/pvc
kubectl delete pv/pv

cat <<EOF> create-pv.yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: vm01
    path: /share
EOF
kubectl create -f create-pv.yml

cat <<EOF> claim-pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 20Gi
  volumeName: pv      
EOF
kubectl create -f claim-pvc.yml

kubectl get pv,pvc


cat <<EOF> nfspod.yml
apiVersion: v1
kind: Pod
metadata:
  name: nfsnginx
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: pvc-volume
      mountPath: /usr/share/nginx/html
  volumes:
    - name: pvc-volume
      persistentVolumeClaim:
        claimName: pvc
EOF
kubectl create -f nfspod.yml
sleep 10

kubectl get po nfsnginx
kubectl exec -it  nfsnginx -- curl 127.0.0.1/index.html
sleep 10

echo "<h1>hello</h1>" >/share/index.html
kubectl exec -it  nfsnginx -- curl 127.0.0.1/index.html

```


# deploy예제 yaml
```
cat > nfsDeploy.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfsnginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nfsnginx
  template:
    metadata:
      labels:
        app: nfsnginx
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: pvc-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: pvc-volume
        persistentVolumeClaim:
          claimName: pvc

EOF
kubectl create -f nfsDeploy.yaml
kubectl expose deploy/nfsnginx --type="NodePort" --port=80
kubectl scale deploy nfsnginx --replicas=2
kubectl get svc
export NODE_PORT=$(kubectl get services/nfsnginx -o go-template='{{(index .spec.ports 0).nodePort}}')
curl vm01:$NODE_PORT
kubectl get po
echo "<h1>hi</h1>" > /share/index.html
curl vm01:$NODE_PORT
curl vm01:$NODE_PORT
curl vm01:$NODE_PORT
# 계속 같은 것이 나오는지 확인
```
