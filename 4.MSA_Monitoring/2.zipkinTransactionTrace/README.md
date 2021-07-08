# Zipkin을 이용한 MSA 환경에서 분산 트렌젝션의 추적
## Spring Boot 실습
```
mkdir ~/df
chmod 777 ~/df
docker run -it --name m1 --rm -v  ~/df:/home/developer/df -p 8080:8080 openkbs/jdk-mvn-py3
#docker exec -it m1 bash
  cd df
  git clone https://github.com/spring-guides/gs-spring-boot
    # http://vm01:8080/actuator/health
```

## Spring Boot 기반 App에서 Zipkin으로 정보 전달 (fail)
```
mkdir ~/df
docker run -it --name m1 --rm -v  ~/df:/home/developer/df -p 8080:8080 openkbs/jdk-mvn-py3
#docker exec -it m1 bash
cd df
git clone https://github.com/openzipkin/brave-example
cd brave-example/webmvc4-boot
vi ./src/main/java/brave/example/TracingAutoConfiguration.java
    # zipkin 주소 수정
mvn clean spring-boot:run
```
