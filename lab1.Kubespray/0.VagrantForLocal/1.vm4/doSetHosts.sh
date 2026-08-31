#!/bin/bash
# AWS 경로의 3.InstanceForKubernetes/doSetHosts.sh 에 대응하는 로컬판.
# i1 안에서 실행한다.
#
# AWS 판은 `aws ec2 describe-instances` 로 IP 를 알아내야 하지만
# 로컬은 IP 가 고정이라 Vagrant 가 부팅할 때 이미 /etc/hosts 를 넣어 두었다.
# 그래서 이 스크립트가 하는 일은 확인과 정리뿐이다.
#   * hosts.generated 와 /etc/hosts 가 어긋났으면 다시 넣는다
#   * known_hosts 를 비운다 (VM 을 다시 만들면 호스트키가 바뀐다)
#   * 모든 노드에 무암호 ssh 가 되는지 실제로 확인한다

set -uo pipefail

GEN="/vagrant/hosts.generated"

echo "=== known_hosts 정리 ==="
rm -f ~/.ssh/known_hosts

if [ ! -f "$GEN" ]; then
  echo "!! ${GEN} 가 없다. 호스트에서 vagrant up 을 먼저 실행했는지 확인할 것."
  exit 1
fi

# Windows 호스트가 만든 파일이라 CR 이 섞일 수 있다. 정리본을 만들어 쓴다.
GEN_CLEAN="$(mktemp)"
tr -d '\r' < "$GEN" > "$GEN_CLEAN"
GEN="$GEN_CLEAN"

echo "=== /etc/hosts 확인 ==="
if ! diff -q <(sed -n '/# >>> sreMsa >>>/,/# <<< sreMsa <<</p' /etc/hosts | sed '1d;$d') "$GEN" >/dev/null 2>&1; then
  echo "  어긋나 있어 다시 넣는다."
  sudo sed -i '/# >>> sreMsa >>>/,/# <<< sreMsa <<</d' /etc/hosts
  {
    echo "# >>> sreMsa >>>"
    cat "$GEN"
    echo "# <<< sreMsa <<<"
  } | sudo tee -a /etc/hosts >/dev/null
else
  echo "  이미 일치한다."
fi

echo "/etc/hosts------------"
cat /etc/hosts
echo "----------------------"

echo ""
echo "=== 각 노드 접속 확인 ==="
fail=0
while read -r ip name; do
  [ "$name" = "i1" ] && continue
  printf '  %-6s (%s) ... ' "$name" "$ip"
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes \
         "ubuntu@${name}" 'hostname' >/dev/null 2>&1; then
    echo "OK"
  else
    echo "실패"
    fail=1
  fi
done < "$GEN"

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "!! 접속에 실패한 노드가 있다. 호스트에서 아래를 실행해 키를 다시 심는다."
  echo "!!   vagrant provision vm01 vm02 vm03"
  exit 1
fi

echo ""
echo "모든 노드 접속 확인 완료."
