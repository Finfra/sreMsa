
## NFS 사용예
### nfs-common 설치(실습용 Console서버)
```
for i in vm01 vm02 vm03;do
  ssh $i sudo apt -y install nfs-common
done

```
### vm01 에서 NFS server작업
```
apt update &&  apt-get install -y nfs-kernel-server
mkdir -m 1777 /share
touch /share/hello.txt
cat <<EOF>  /etc/exports
/share/ *(rw,sync,no_root_squash,subtree_check) # *은 subnet
EOF
exportfs -ra
exportfs
```

### vm02,vm03 NFS Client 작업
```
apt-get update && apt -y install nfs-common
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

### Persistent Volume와 Persistent Volume claim을 통한 NFS를 사용하는 Deploy생성
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

kubectl get po nfsnginx
kubectl exec nfsnginx -- ls /usr/share/nginx/html

```
