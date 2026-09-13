#!/bin/bash
# `vagrant ssh` 대신 쓰는 빠른 접속 헬퍼 (bash 판).
#
# ⚠️ Windows 실습에서는 이 파일이 아니라 doSsh.ps1 을 쓴다.
#    Git for Windows 를 설치하지 않기로 했으므로 Windows 에는 bash 가 없다.
#    이 파일은 호스트가 macOS·Linux 일 때(강사 검증 환경)를 위해 남겨 둔다.
#
#   ./doSsh.sh              # i1 에 접속
#   ./doSsh.sh vm01         # vm01 에 접속
#   ./doSsh.sh i1 hostname  # i1 에서 명령 하나만 실행
#
# 왜 필요한가 — `vagrant ssh` 는 명령 하나에 5~10초가 걸린다.
# 실기(Windows 10 · i7-6700T · 16GB)에서 측정한 값이다.
#
#   vagrant --version        1.6s   Ruby 런타임 부팅만
#   vagrant --help          11.3s   + 내장 플러그인·커맨드 전체 로드
#   vagrant status           9.0s   + Vagrantfile 파싱 + VM 상태 조회
#   vagrant ssh i1 -c true   6.8s
#   ssh -F ssh-config i1     0.12s  ← 이 스크립트가 쓰는 접속 경로
#   VBoxManage showvminfo    0.08s  ← 이 스크립트가 쓰는 상태 확인 경로
#
# VM 도 디스크도 느린 것이 아니다(측정 당시 CPU 17% · RAM 7.7GB 여유).
# Vagrant CLI 가 명령을 하나 처리할 때마다 Ruby 런타임과 내장 플러그인
# 수십 개를 새로 로드하는 구조 때문이며, 사용자가 줄일 수 있는 부분이 아니다.
# 참고로 Windows Defender 제외 경로를 추가해도 달라지지 않는다(실측 확인).
#
# 그래서 접속 정보를 한 번만 뽑아 두고 그 다음부터는 ssh 를 직접 쓴다.
# `vagrant` 를 부르는 것은 ssh-config 를 만드는 최초 1회뿐이다.
#
# ⚠️ VM 이 꺼져 있을 때 멈추지 않는 것이 이 스크립트의 조건이다.
#    막는 곳이 세 군데다. 앞의 것이 뚫려도 뒤가 받는다 (doSsh.ps1 과 같은 구조).
#      ① VirtualBox 에 상태를 먼저 묻는다      — 꺼져 있으면 0.08초 만에 안내하고 끝낸다
#      ② vagrant 호출에 시간 상한과 빈 stdin   — Ruby 가 입력을 기다리며 멈추는 것을 막는다
#      ③ ssh 에 ConnectTimeout                 — 응답 없는 상대를 무한히 기다리지 않는다

set -uo pipefail

CD="$(cd "$(dirname "$0")" && pwd)"
cd "$CD" || exit 1

CFG=".vagrant/ssh-config"
TARGET="${1:-i1}"
[ $# -gt 0 ] && shift

# ── 1. 대상 VM 이 켜져 있는지 먼저 본다 (0.08초) ─────────────────────
#
# 꺼진 VM 을 상대로는 그 뒤의 어떤 단계도 성공할 수 없다. 여기서 끊으면
# `vagrant status`(9초)를 칠 필요도, ssh 가 멈추는 것을 볼 일도 없다.
# VirtualBox 가 없거나 VM 이름을 못 찾으면 건너뛴다 — 확인은 편의 장치이지
# 관문이 아니며, 뚫려도 아래 ②③ 이 받는다.
VM="sreMsa-${TARGET}"   # Vagrantfile 의 vb.name 규약 (i1 -> sreMsa-i1)
if command -v VBoxManage >/dev/null 2>&1; then
  if ! INFO="$(VBoxManage showvminfo "$VM" --machinereadable 2>/dev/null)"; then
    echo "  '${VM}' 을 VirtualBox 에서 찾을 수 없다. 아직 만들지 않았을 수 있다:" >&2
    echo "    vagrant up ${TARGET}" >&2
    exit 1
  fi
  STATE="$(printf '%s\n' "$INFO" | sed -n 's/^VMState="\(.*\)"$/\1/p' | head -1)"
  if [ -n "$STATE" ] && [ "$STATE" != "running" ]; then
    echo "  '${TARGET}' 이 켜져 있지 않다 (지금: ${STATE}). 먼저 켠다:" >&2
    echo "    vagrant up ${TARGET}" >&2
    echo "  네 대를 다 켜려면 이름 없이: vagrant up" >&2
    exit 1
  fi
fi

# ── 2. 접속 정보(ssh-config) 준비 ─────────────────────────────────────
# Vagrantfile 이 더 새로우면 포트가 바뀌었을 수 있으므로 다시 뽑는다.
if [ ! -f "$CFG" ] || [ Vagrantfile -nt "$CFG" ]; then
  echo "  ssh-config 생성 중 — vagrant 를 부르므로 이번 한 번만 느리다" >&2
  mkdir -p .vagrant
  ERR="$(mktemp)"; TMP="$(mktemp)"

  # 시간 상한. VirtualBox 가 응답하지 않으면 vagrant 도 같이 멎는다.
  TO=""
  command -v timeout  >/dev/null 2>&1 && TO="timeout 60"
  command -v gtimeout >/dev/null 2>&1 && TO="gtimeout 60"

  # `< /dev/null` 이 없으면 vagrant 가 stdin 을 물고 멈춘다.
  # 스크립트를 비대화형으로 호출했을 때 실제로 겪은 문제다.
  if ! $TO vagrant ssh-config < /dev/null > "$TMP" 2>"$ERR"; then
    RC=$?
    if [ $RC -eq 124 ]; then
      echo "  vagrant 가 60초 안에 끝나지 않아 중단했다." >&2
      echo "  VirtualBox 가 응답하지 않는 상태일 수 있다. 호스트를 다시 시작해 본다." >&2
    else
      echo "  ssh-config 를 뽑지 못했다. VM 이 running 인지 확인할 것 (vagrant status)" >&2
      sed 's/^/    /' "$ERR" >&2
    fi
    rm -f "$ERR" "$TMP"
    exit 1
  fi
  # 이 실습의 명령은 전부 ubuntu 기준이다. User 를 ubuntu 로 바꿔 두면
  # 대화형이든 명령 실행이든 언제나 ubuntu 로 붙는다.
  # (common.sh 가 vagrant 의 공개키를 ubuntu 에도 등록해 두었기 때문에 가능하다)
  sed 's/^\([[:space:]]*User[[:space:]]\).*/\1ubuntu/' "$TMP" > "$CFG"
  rm -f "$ERR" "$TMP"
fi

# 접속 대상이 config 에 없으면 안내한다 (오타·미기동)
if ! grep -qE "^Host[[:space:]]+${TARGET}$" "$CFG"; then
  echo "  '${TARGET}' 이 ssh-config 에 없다. 사용 가능한 대상:" >&2
  grep -E '^Host ' "$CFG" | awk '{print "    " $2}' >&2
  echo "  VM 을 새로 만들었다면 이 파일을 지우고 다시 실행할 것: rm ${CFG}" >&2
  exit 1
fi

# ── 3. 접속 ───────────────────────────────────────────────────────────
# ConnectTimeout 을 준다. 상대가 응답하지 않으면 ssh 는 기본적으로 무한히 기다린다
# (실측: 응답 없는 192.168.56.10 에 붙이면 40초가 지나도 끝나지 않는다).
ssh -F "$CFG" -o ConnectTimeout=10 "$TARGET" "$@"
CODE=$?

# 255 는 ssh 가 붙지 못했다는 뜻이다(원격에서 돌린 명령이 실패한 것과 구분된다).
if [ $CODE -eq 255 ]; then
  echo "" >&2
  echo "  '${TARGET}' 에 접속하지 못했다. VM 이 방금 꺼졌거나 포트가 바뀌었을 수 있다:" >&2
  echo "    vagrant up ${TARGET}" >&2
  echo "  VM 을 다시 만들었다면 접속 정보를 새로 뽑는다: rm ${CFG}" >&2
fi
exit $CODE
