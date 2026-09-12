# 오토스케일 — 요청이 몰리면 인스턴스가 늘어난다

* 함수에 부하를 걸어 인스턴스가 **1개에서 여러 개로 늘어나는 구간**을 관찰합니다.
* 강의 자료의 "이벤트가 도착하면 인스턴스가 생긴다" 를 눈으로 확인하는 실습입니다.

## 1. OpenFaaS 가 언제 늘리는지 먼저 보기 [vm01에서 실행]

* 규칙을 알고 부하를 걸어야 결과가 납니다. 규칙은 Prometheus 알람으로 들어 있습니다.

```
kubectl get cm -n openfaas prometheus-config -o yaml | grep -A6 "alert: APIHighInvocationRate"
```

* 확인 :
```
- alert: APIHighInvocationRate
  expr: sum(rate(gateway_function_invocation_total{code="200"}[10s])) BY (function_name) > 5
  for: 5s
```

* 읽는 법 : **최근 10초 평균이 초당 5회를 넘은 상태가 5초 이상 이어져야** 알람이 울리고, 그때 게이트웨이가 인스턴스를 늘립니다.
* ⚠️ **그래서 요청을 한 번에 왕창 던지는 방식은 실패합니다.** 300개를 동시에 쏴도 순식간에 처리되어 "지속" 조건을 못 채웁니다. 실제로 그렇게 해 보면 replicas 가 1 그대로입니다. **꾸준히, 일정 시간 이상** 넣어야 합니다.

## 2. 관찰 창 띄우기 [vm01에서 — 새 터미널]

```
watch -n 2 kubectl get deploy -n openfaas-fn nodeinfo
```

* cf) `watch` 가 없으면 `while true; do kubectl get deploy -n openfaas-fn nodeinfo; sleep 2; done`

## 3. 90초 동안 꾸준히 부하 걸기 [vm01에서 실행]

```
export OPENFAAS_URL=http://192.168.56.11:31112
END=$((SECONDS+90))
while [ $SECONDS -lt $END ]; do
  for k in $(seq 1 10); do curl -o /dev/null -s --max-time 5 $OPENFAAS_URL/function/nodeinfo & done
  sleep 0.3
done
wait
```

* 확인 : 관찰 창에서 `READY` 가 단계적으로 올라갑니다.
```
  20초: 1/1
  40초: 1/2      ← 늘리기 시작
  60초: 2/2
  85초: 2/3
```

* cf) 곧바로 3개가 되지 않고 **한 단계씩** 올라갑니다. 알람이 계속 울리는 동안 반복해서 늘리기 때문입니다.

## 4. 알람이 실제로 울렸는지 확인 [vm01에서 실행]

```
PIP=$(kubectl get svc -n openfaas prometheus -o jsonpath="{.spec.clusterIP}")
curl -s http://$PIP:9090/api/v1/alerts | head -c 400; echo
```

* 확인 : `"state":"firing"` 과 초당 요청 수가 보입니다.
```
{"status":"success","data":{"alerts":[{"labels":{"alertname":"APIHighInvocationRate",
"function_name":"nodeinfo.openfaas-fn",...},"state":"firing","value":"3e+01"}]}}
```

* `3e+01` 은 30, 즉 **초당 30회**가 들어왔다는 뜻입니다. 기준인 5회를 넉넉히 넘겼습니다.

## 5. 부하를 멈추면 [vm01에서 실행]

* 부하를 멈추고 몇 분 기다린 뒤 다시 봅니다.

```
kubectl get deploy -n openfaas-fn nodeinfo
```

* 확인 : 시간이 지나면 다시 1로 줄어듭니다. **0 이 되지는 않습니다** — `3.coldStart` 에서 본 대로 CE 의 하한은 1입니다.

## 6. 직접 조절해 보기 [vm01에서 실행]

* 함수마다 최소·최대 개수를 지정할 수 있습니다. 라벨로 줍니다.

* **주의 : 이미 떠 있는 함수에는 라벨이 갱신되지 않습니다.** 먼저 지우고 새로 배포해야 합니다.

```
faas-cli remove nodeinfo
sleep 10

faas-cli store deploy nodeinfo \
  --label com.openfaas.scale.min=2 \
  --label com.openfaas.scale.max=6
```

* 확인 :
```
kubectl get deploy -n openfaas-fn nodeinfo
```
* `min=2` 로 주면 부하가 없어도 2개가 유지됩니다. 실측에서 `2/2` 를 확인했습니다 — **지우지 않고 라벨만 덧붙이면 `1/1` 그대로입니다.** **콜드 스타트를 줄이려고 최소 개수를 올리는 것**이 강의에서 말한 "최소 인스턴스 상시 유지" 입니다.
* ⚠️ 최소 개수를 올리면 **쉬는 동안에도 자원을 쓴다**는 뜻입니다. 강의의 비용 그래프에서 *"안 써도 나가는 비용"* 쪽으로 옮겨 가는 셈이니, 어디까지 올릴지는 트레이드오프입니다.

## 7. 실습 정리 [vm01에서 실행]

```
faas-cli remove nodeinfo
kubectl get pods -n openfaas-fn
```
