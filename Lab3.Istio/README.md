# Agenda
| Folder | Contents             |
|-|-|
| 1.istioInstall          | Istio 셋팅 실습 |
| 2.istioTrafficManage    | Istio Traffic 관리 실습 |
| 3.istioSecurity         | 인증, 권한 부여 및 서비스 통신 암호화를 관리 실습 |
| 4.Dashboard             | Istio를 통한 K8s 클러스터 접근 실습(외부에서 내부로 접근) |
| 5.RequestRouting       | Istio를 통한 동적 라우팅 요청 (ex) v1에만 라우팅 / v2에만 라우팅 각각 설정|
| 6.WeightedRouting       | Istio를 통한 가중치 기반 라우팅(ex) v1 : 30% / v2 :70% 라우팅|
| 7.CircutBreaker         | Istio를 통한 서킷브레이커 사용 (장애, 지연시간증가, 비정상 트래픽을 제한) |



# 실습 후 정리 작업

## Resource제거
```
cd ~/istio-*
kubectl delete -f h1_inj.yaml
kubectl delete svc/h1 -n prj1
kubectl delete namespace prj1
```

## istio 삭제
```

kubectl delete -f samples/addons
istioctl manifest generate --set profile=demo | kubectl delete --ignore-not-found=true -f -
kubectl delete namespace istio-system
kubectl label namespace default istio-injection-

kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml

```
