# Install
1. Install Virtualbox
2. Install Vagrant
3. Download vagrant script
* By git
git clone https://github.com/rayshoo/vansinetes
* Download
https://codeload.github.com/rayshoo/vansinetes/zip/refs/heads/master

4. Install Vagrant Plugin
```
vagrant plugin install vagrant-env
```

5. .env 파일 수정
* vansinetes/.env 
    - "MIRROR_CHANGE=no"를 "MIRROR_CHANGE=yes"로 바꿔줍니다. 
    - DEFAULT_NETWORK_IP=xx.xxx.xxx.xxx 를 Virtualbox의 파일 메뉴의 "호스트 네트워크 관리자(Host Network Manger)"의 에서 확인하여 Host-Only IP를 바꿔줍니다.

6. vagrant up
```
cd vansinetes
vagrant up  
```

7. Connect 
```
vagrant status 
vagrant ssh m1
```


8. kubernetes Check
```
kubectl cluster-info
kubectl get nodes
```

9. 사용
    - → 열심히 실습합니다!

* 설치 중 실패시 다시 시작하는 방법
```
# Linux or Mac
vagrant destroy --force && vagrant up

# Windows 
vagrant destroy --force
vagrant up
```

* 사용 후 지우기. 
```
vagrant destroy -f
```







