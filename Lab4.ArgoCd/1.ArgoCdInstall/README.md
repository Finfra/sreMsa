# Argo CD Get Started
* GitOps 툴 중의 하나인 ArgoCd를 설치하고 간단한 테스트를 진행합니다.
* ArgoCd Home : https://argoproj.github.io/argo-cd/
* ArgoCd Get Started :  https://argoproj.github.io/argo-cd/getting_started/

## 1. Install Argo CD
* Kubernetes단에서 설치[vm01에서 실행]
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
* 확인 :  아래 명령을 계속 실행하면서 Available이 모두 1이 되도록 기다립니다.
```
kubectl get all -n argocd
```
* cf) Dex : OpenID Connect 를 사용 하여 다른 앱에 대한 인증을 구동 하는 ID 서비스
  - LDAP servers, SAML providers, or established identity providers like GitHub, Google, and Active Directory

## 2. Download Argo CD CLI [실습용 Console/vm01 서버에서 실행]
```
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

```

## 3. Access The Argo CD API Server 구동
* vm01에서 실행 Panding되면 ctl+c
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## 4. Login Using The CLI
* 비번 얻기
```
Pass=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo $Pass
```

* Argo CD Login
- vm01서에서  argocd-server의 80 포트에 대한 forwarding Port얻음.
```
kubectl get svc argocd-server -n argocd
cat /etc/hosts |grep vm01
argocd login vm01.cluster.local:31168 # 포트번호는 위 kubectl ge Uset svc명령에서 확인 가능, uername: admin
                                      # echo $Pass 쳐보면 나옴
argocd account update-password   # 비번수정
```

- vm01서에서  argocd-server의 443 포트에 대한 forwarding Port얻음.
```
kubectl get svc argocd-server -n argocd
```

- 실습용 Console서버에서도 로그인 가능함.[argocd 설치 필요]
```
argocd login vm01:30360
```

## 5. 앱을 배포 할 클러스터 등록 (Optional)
```
argocd cluster add $(kubectl config get-contexts -o name) --in-cluster
```
  - cf) https://argoproj.github.io/argo-cd/user-guide/commands/argocd_cluster_add/
