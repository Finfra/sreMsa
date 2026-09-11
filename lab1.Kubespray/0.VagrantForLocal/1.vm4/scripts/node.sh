#!/bin/bash
# Kubernetes 노드(vm01~vm0N) 전용 프로비저닝
#
# i1 이 만들어 /vagrant/.keys/ 에 남긴 공개키를 ubuntu·root 계정에 등록한다.
# 이것이 있어야 i1 에서 `ssh vm01`, `ansible -m ping` 이 암호 없이 된다.

set -uo pipefail

PUB="/vagrant/.keys/id_rsa.pub"
HN="$(hostname)"
KEY_ARG="${1:-}"

echo "=== [node] ${HN} — i1 공개키 등록 ==="

# 공유 폴더(/vagrant)가 마운트되지 않는 경우가 있어 이중으로 받는다.
#   1순위 : Vagrantfile 이 호스트의 .keys/id_rsa.pub 를 읽어 인자로 넘긴 값
#   2순위 : 게스트에서 본 /vagrant/.keys/id_rsa.pub
if [ -n "$KEY_ARG" ]; then
  PUB="$(mktemp)"
  printf '%s\n' "$KEY_ARG" > "$PUB"
  echo "  키 출처: Vagrantfile 인자"
elif [ -f "$PUB" ]; then
  echo "  키 출처: ${PUB} (공유 폴더)"
fi

if [ ! -f "$PUB" ]; then
  echo "!! ${PUB} 가 없다."
  echo "!! i1 이 아직 만들어지지 않았다는 뜻이다. i1 을 먼저 올린 뒤"
  echo "!!   vagrant provision ${HN}"
  echo "!! 을 실행하면 이 단계만 다시 돈다."
  exit 0
fi

add_key() {
  local home="$1" owner="$2"
  install -d -m 700 -o "$owner" -g "$owner" "${home}/.ssh"
  touch "${home}/.ssh/authorized_keys"
  grep -qxF "$(cat "$PUB")" "${home}/.ssh/authorized_keys" || cat "$PUB" >> "${home}/.ssh/authorized_keys"
  chown "${owner}:${owner}" "${home}/.ssh/authorized_keys"
  chmod 600 "${home}/.ssh/authorized_keys"
  echo "  ${owner} 등록 완료"
}

add_key /home/ubuntu ubuntu
add_key /root root

echo "=== [node] ${HN} 완료 ==="
