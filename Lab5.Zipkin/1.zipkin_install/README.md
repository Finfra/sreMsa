# zipkin 셋팅 실습
* Zipkin Server단 설치를 진행합니다.
* Quick Start : https://zipkin.io/pages/quickstart
## 1. Docker로 실행
```
docker run -d -p 9411:9411 --rm --name zipkin openzipkin/zipkin
```

## 2. 접근
* http://vm01:9411
