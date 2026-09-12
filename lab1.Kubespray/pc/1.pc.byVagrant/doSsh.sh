#!/bin/bash
# `vagrant ssh` 대신 쓰는 빠른 접속 헬퍼. 호스트(Windows Git Bash)에서 실행한다.
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
#   ssh -F ssh-config i1     0.12s  ← 이 스크립트가 쓰는 경로
#   VBoxManage showvminfo    0.08s
#
# VM 도 디스크도 느린 것이 아니다(측정 당시 CPU 17% · RAM 7.7GB 여유).
# Vagrant CLI 가 명령을 하나 처리할 때마다 Ruby 런타임과 내장 플러그인
# 수십 개를 새로 로드하는 구조 때문이며, 사용자가 줄일 수 있는 부분이 아니다.
# 참고로 Windows Defender 제외 경로를 추가해도 달라지지 않는다(실측 확인).
#
# 그래서 접속 정보를 한 번만 뽑아 두고 그 다음부터는 ssh 를 직접 쓴다.
# `vagrant` 를 부르는 것은 ssh-config 를 만드는 최초 1회뿐이다.

set -uo pipefail

CD="$(cd "$(dirname "$0")" && pwd)"
cd "$CD" || exit 1

CFG=".vagrant/ssh-config"
TARGET="${1:-i1}"
[ $# -gt 0 ] && shift

# Vagrantfile 이 더 새로우면 포트가 바뀌었을 수 있으므로 다시 뽑는다.
if [ ! -f "$CFG" ] || [ Vagrantfile -nt "$CFG" ]; then
  echo "  ssh-config 생성 중 — vagrant 를 부르므로 이번 한 번만 느리다" >&2
  mkdir -p .vagrant
  ERR="$(mktemp)"; TMP="$(mktemp)"
  # `< /dev/null` 이 없으면 vagrant 가 stdin 을 물고 멈춘다.
  # 스크립트를 비대화형으로 호출했을 때 실제로 겪은 문제다.
  if ! vagrant ssh-config < /dev/null > "$TMP" 2>"$ERR"; then
    echo "  실패: VM 이 running 인지 확인할 것 (vagrant status)" >&2
    sed 's/^/    /' "$ERR" >&2
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

exec ssh -F "$CFG" "$TARGET" "$@"
