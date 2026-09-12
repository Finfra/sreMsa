#!/bin/bash
# cluster-watchdog.sh — cluster.yml 이 멈추면 되살린다.
#
# 왜 필요한가 (2026-09-01 실측):
#   이 호스트는 NVMe 결함으로 디스크 I/O 가 간헐적으로 완전히 멈춘다.
#   오늘만 3회 — cluster.yml 중단(08:38, fatal 0건인데 로그가 그냥 끊김) ·
#   바깥 VM 부팅 51분 hang · 호스트 8차 크래시.
#   게스트가 D 상태(uninterruptible sleep)에 빠지면 ansible 도 로그도
#   함께 멈춘다. 게스트 안에서 감시하면 감시자도 같이 멈추므로
#   반드시 호스트에서 봐야 한다.
#
# cluster.yml 은 멱등이라 재실행하면 끝난 태스크를 건너뛴다.
# download_keep_remote_cache 로 받은 이미지도 유지되므로 재개가 빠르다.

BASE="/c/Users/nowage/work/sreMsa/lab1.Kubespray/pc/inVm"
VB="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
VM="sreMsa-inVm"
WLOG="/c/Users/nowage/watchdog.log"
STATE="/c/Users/nowage/watchdog.state"

INTERVAL=120          # 확인 주기 2분
STALL_LIMIT=1500      # 25분 정체 → 복구 (가장 느린 태스크 884s 의 1.7배)
SSH_FAIL_LIMIT=3      # 연속 3회(6분) SSH 실패 → 복구
MAX_RECOVER=8         # 복구 시도 상한 — 무한 루프 방지

log() { echo "$(date '+%m-%d %H:%M:%S') $*" >> "$WLOG"; }

sshi() {  # $* = 원격 명령
  local P; P=$(cd "$BASE" && vagrant ssh-config i1 2>/dev/null | awk '/[[:space:]]Port /{print $2}')
  [ -z "$P" ] && return 1
  ssh -n -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=20 -o LogLevel=ERROR \
      -i "$BASE/.vagrant/machines/i1/virtualbox/private_key" -p "$P" vagrant@127.0.0.1 "$*" 2>/dev/null
}

start_cluster() {
  log "cluster.yml 기동"
  sshi 'sudo -u ubuntu -H bash -lc "cd ~/kubespray && nohup env ANSIBLE_HOST_KEY_CHECKING=False ~/ksvenv/bin/ansible-playbook -i inventory/inventory.ini --private-key ~/.ssh/id_rsa -b cluster.yml >> ~/cluster2.log 2>&1 &"'
}

recover() {
  local n=$1
  log "=== 복구 $n/$MAX_RECOVER 시작 ==="
  "$VB" controlvm "$VM" acpipowerbutton >/dev/null 2>&1
  local i
  for i in 1 2 3 4 5 6; do
    [ "$("$VB" showvminfo "$VM" --machinereadable 2>/dev/null | grep -o 'VMState="[a-z]*"')" = 'VMState="poweroff"' ] && break
    sleep 10
  done
  "$VB" controlvm "$VM" poweroff >/dev/null 2>&1
  sleep 8
  log "  바깥 VM 재기동"
  (cd "$BASE" && vagrant up --no-provision >/dev/null 2>&1)
  for i in $(seq 1 12); do
    sshi 'echo ok' >/dev/null 2>&1 && break
    sleep 15
  done
  if ! sshi 'echo ok' >/dev/null 2>&1; then log "  ❌ 바깥 VM SSH 복구 실패"; return 1; fi
  log "  안쪽 3대 기동"
  sshi 'sudo -u ubuntu -H bash -lc "cd ~/inner && vagrant up >/dev/null 2>&1"'
  sleep 20
  start_cluster
  log "=== 복구 $n 완료 ==="
}

log "########## watchdog 시작 (interval=${INTERVAL}s stall=${STALL_LIMIT}s) ##########"
echo "running" > "$STATE"
recover_count=0
ssh_fail=0

while :; do
  sleep "$INTERVAL"

  # 사람이 멈추라고 하면 종료
  [ "$(cat "$STATE" 2>/dev/null)" = "stop" ] && { log "STATE=stop — 종료"; exit 0; }

  # 완주 확인
  #
  # ⚠️ PLAY RECAP 유무로 판정하면 안 된다 — ansible 은 실패해도 RECAP 을 낸다.
  #    2026-09-05 에 vm03 unreachable=1 로 실패한 결과를 완주로 오판해
  #    watchdog 이 스스로 종료했다.
  #    재시도 루프가 exit code 0 일 때만 남기는 "##### 성공" 마커를 본다.
  if sshi 'sudo grep -c "##### 성공" /home/ubuntu/cluster2.log 2>/dev/null' | grep -qE '^[1-9]'; then
    log "✅ 완주 확인 (성공 마커) — watchdog 종료"
    sshi 'sudo grep -A6 "PLAY RECAP" /home/ubuntu/cluster2.log | tail -6' >> "$WLOG" 2>&1
    echo "done" > "$STATE"
    exit 0
  fi

  # 로그 정체 확인
  #
  # ⚠️ 2026-09-01 오작동 교훈 — 여기서 두 가지를 틀렸다.
  #   ① /home/ubuntu 는 drwxr-x--- 라 vagrant 사용자로 stat 할 수 없다.
  #      ~ubuntu 표기로 접근하다 Permission denied 로 실패했다.
  #   ② 실패를 `|| echo 0` 으로 흡수해 "1970년 파일" 로 둔갑시켰다.
  #      그 결과 정체가 1,788,266,885초(유닉스 타임스탬프 그 자체)로
  #      계산돼, ansible 5개가 멀쩡히 돌던 작업을 강제 재부팅했다.
  #
  # 실패는 0 이 아니라 BAD 로 두고 이번 회차를 건너뛴다. 감시자가
  # 스스로 오판해 정상 작업을 죽이는 것이 아무것도 안 하는 것보다 나쁘다.
  AGE=$(sshi 'M=$(sudo stat -c %Y /home/ubuntu/cluster2.log 2>/dev/null); if [ -n "$M" ]; then echo $(( $(date +%s) - M )); else echo BAD; fi' | tr -d '\r')
  if [ "$AGE" = "BAD" ]; then
    log "로그 mtime 조회 실패 — 이번 회차 건너뜀 (오판 방지)"
    continue
  fi
  if [ -z "$AGE" ] || ! echo "$AGE" | grep -qE '^[0-9]+$'; then
    ssh_fail=$((ssh_fail+1))
    log "SSH 무응답 ($ssh_fail/$SSH_FAIL_LIMIT)"
    if [ "$ssh_fail" -ge "$SSH_FAIL_LIMIT" ]; then
      recover_count=$((recover_count+1))
      [ "$recover_count" -gt "$MAX_RECOVER" ] && { log "복구 상한 초과 — 종료"; echo "failed" > "$STATE"; exit 1; }
      recover "$recover_count"; ssh_fail=0
    fi
    continue
  fi
  ssh_fail=0

  # ansible 살아있나
  ALIVE=$(sshi 'pgrep -c -f "ansible-playbook.*cluster.yml"' | tr -d '\r')
  log "정체 ${AGE}s · ansible=${ALIVE:-0}"

  if [ "${ALIVE:-0}" = "0" ]; then
    log "ansible 프로세스 없음 — 재기동"
    start_cluster
    continue
  fi

  if [ "$AGE" -gt "$STALL_LIMIT" ]; then
    recover_count=$((recover_count+1))
    [ "$recover_count" -gt "$MAX_RECOVER" ] && { log "복구 상한 초과 — 종료"; echo "failed" > "$STATE"; exit 1; }
    log "⚠️ ${AGE}s 정체 — I/O 급정지로 판단"
    recover "$recover_count"
  fi
done
