# Kubernetes 네트워킹
## 80포트 사용 서비스 생성
```
kubectl get deploy
kubectl create deployment --image=httpd  h1

kubectl expose deployment h1 --type="NodePort" --port 80  --external-ip=63.34.113.155
kubectl get svc
```

## 확인 Network 접근 확인
```
curl $(kubectl get services |grep h1|awk '{print $3}')
```

## 모든 트레픽 거부 Netwok Policy 생성 후 접근 확인
```

cat <<EOF> network-policy-default-deny-ingress.yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
kubectl apply -f network-policy-default-deny-ingress.yaml

curl $(kubectl get services |grep h1|awk '{print $3}') # 실패함.

```

## Netwok Policy 확인
```
kubectl get networkpolicy
```

## Network Policy 삭제
```
kubectl delete networkpolicy default-deny-ingress
kubectl get networkpolicy
curl $(kubectl get services |grep h1|awk '{print $3}') # 성공함.
```

## 해당 서비스 79번 포트만 허용하는 ingress만들기
```
kubectl delete networkpolicy web-ingress

cat <<EOF> web-ingress.yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 172.17.1.0/24
    - namespaceSelector:
        matchLabels:
          app: web
    ports:
    - protocol: TCP
      port: 79
      endPort: 79
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24
    ports:
    - protocol: TCP
      port: 1
      endPort: 65535
EOF
kubectl apply -f web-ingress.yaml
kubectl get networkpolicy web-ingress

curl $(kubectl get services |grep h1|awk '{print $3}') # 실패함
```

## 해당 서비스 80번 포트만 허용하는 ingress만들기
```
kubectl delete networkpolicy web-ingress

cat <<EOF> web-ingress.yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 172.17.1.0/24
    - namespaceSelector:
        matchLabels:
          app: web
    ports:
    - protocol: TCP
      port: 80
      endPort: 80
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24
    ports:
    - protocol: TCP
      port: 1
      endPort: 65535
EOF
kubectl apply -f web-ingress.yaml
kubectl get networkpolicy web-ingress

curl $(kubectl get services |grep h1|awk '{print $3}') # 성공함.

```


## 생성한 deploy, service 삭제
```
kubectl delete networkpolicy web-ingress
kubectl delete networkpolicy default-deny-ingress
kubectl delete svc h1
kubectl delete svc h2
kubectl delete deploy h1
kubectl delete deploy h2
```
