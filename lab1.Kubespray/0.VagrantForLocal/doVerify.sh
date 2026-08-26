#!/bin/bash
# i1 에서 vm01~vm0N 으로 Ansible 이 실제로 동작하는지 확인한다.
# i1 안에서 ubuntu 계정으로 실행한다.
#
#   bash /vagrant/doVerify.sh
#
# Kubespray 를 돌리기 전에 이것부터 통과시킨다.
# 여기서 걸리는 문제는 cluster.yml 을 20분 돌린 뒤 실패하는 것보다 훨씬 싸다.

set -uo pipefail

GEN="${GEN:-/vagrant/hosts.generated}"
ok=0; ng=0

pass() { echo "  [ OK ] $*"; ok=$((ok+1)); }
fail() { echo "  [FAIL] $*"; ng=$((ng+1)); }

echo "=============================================="
echo " sreMsa 로컬 실습 환경 점검"
echo "=============================================="

# ---------------------------------------------------------------- 0. 실행 위치
echo ""
echo "[0] 실행 환경"
[ "$(hostname)" = "i1" ] && pass "i1 에서 실행 중" || fail "i1 이 아닌 $(hostname) 에서 실행 중 — i1 에서 실행할 것"
[ "$(whoami)" = "ubuntu" ] && pass "ubuntu 계정" || fail "$(whoami) 계정 — 'sudo su - ubuntu' 후 실행할 것"

if [ ! -f "$GEN" ]; then
  echo ""
  echo "!! ${GEN} 가 없다. 호스트에서 vagrant up 을 먼저 실행할 것."
  exit 1
fi

nodes=(); ips=()
while read -r ip name; do
  [ "$name" = "i1" ] && continue
  nodes+=("$name"); ips+=("$ip")
done < "$GEN"
echo "  대상 노드: ${nodes[*]}"

# ---------------------------------------------------------------- 1. 도구
echo ""
echo "[1] i1 의 도구"
command -v ansible >/dev/null && pass "ansible $(ansible --version | head -1 | awk '{print $NF}' | tr -d ')')" || fail "ansible 없음 — installOnEc2.sh 가 실패했다"
command -v python  >/dev/null && pass "python $(python --version 2>&1 | awk '{print $2}')" || fail "python 없음"
[ -f ~/.ssh/id_rsa ] && pass "ssh 개인키 있음" || fail "~/.ssh/id_rsa 없음"

# ---------------------------------------------------------------- 2. 이름 해석
echo ""
echo "[2] 이름 해석 (/etc/hosts)"
for i in "${!nodes[@]}"; do
  n="${nodes[$i]}"; want="${ips[$i]}"
  got="$(getent hosts "$n" | awk '{print $1}' | head -1)"
  if [ "$got" = "$want" ]; then
    pass "$n -> $got"
  else
    fail "$n -> '${got:-해석 실패}' (기대값 $want)"
  fi
done

# ---------------------------------------------------------------- 3. 무암호 ssh
echo ""
echo "[3] i1 -> 각 노드 무암호 ssh"
for n in "${nodes[@]}"; do
  if out="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                "ubuntu@${n}" 'hostname' 2>/dev/null)"; then
    [ "$out" = "$n" ] && pass "ssh ubuntu@${n} -> hostname=$out" \
                      || fail "ssh 는 되지만 hostname 이 '$out' (기대값 $n)"
  else
    fail "ssh ubuntu@${n} 실패 — 호스트에서 'vagrant provision ${n}' 실행"
  fi
done

# ---------------------------------------------------------------- 4. 무암호 sudo
echo ""
echo "[4] 각 노드 무암호 sudo (--become 전제)"
for n in "${nodes[@]}"; do
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
      "ubuntu@${n}" 'sudo -n true' >/dev/null 2>&1 \
    && pass "${n}: sudo 무암호" || fail "${n}: sudo 가 암호를 묻는다"
done

# ---------------------------------------------------------------- 5. 노드 IP
echo ""
echo "[5] 노드가 인식하는 자기 IP  ★ 로컬 고유 함정"
echo "     VirtualBox 는 eth0 이 NAT 이고 그 주소가 모든 VM 에서 10.0.2.15 로 같다."
echo "     inventory 에 ip= 를 주지 않으면 kubespray 가 이 주소를 노드 주소로 잡아 클러스터가 깨진다."
for i in "${!nodes[@]}"; do
  n="${nodes[$i]}"; want="${ips[$i]}"
  got="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
             "ubuntu@${n}" "ip -4 -o addr show | awk '{print \$4}' | cut -d/ -f1 | grep -v '^127' | tr '\n' ' '" 2>/dev/null)"
  if echo "$got" | grep -qw "$want"; then
    pass "${n}: host-only ${want} 보유  (전체: ${got})"
  else
    fail "${n}: host-only ${want} 없음 (전체: ${got})"
  fi
done

# ---------------------------------------------------------------- 6. swap
echo ""
echo "[6] swap 해제"
for n in "${nodes[@]}"; do
  s="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no "ubuntu@${n}" 'swapon --show' 2>/dev/null)"
  [ -z "$s" ] && pass "${n}: swap 없음" || fail "${n}: swap 이 켜져 있다"
done

# ---------------------------------------------------------------- 7. ansible ping
echo ""
echo "[7] Ansible 연결  ★ 이번 확인의 핵심"
INV="$HOME/kubespray/inventory/inventory.ini"
if [ -f "$INV" ]; then
  echo "     inventory: $INV"
else
  INV="$(mktemp)"
  { echo "[all]"; for i in "${!nodes[@]}"; do echo "${nodes[$i]} ansible_host=${ips[$i]}"; done; } > "$INV"
  echo "     inventory: 임시 생성 (kubespray 를 아직 clone 하지 않음)"
fi

if ansible -i "$INV" all -u ubuntu -m ping -o 2>&1 | tee /tmp/ansible_ping.log | grep -q 'SUCCESS'; then
  while read -r line; do
    name="$(echo "$line" | awk '{print $1}')"
    echo "$line" | grep -q 'SUCCESS' && pass "ansible ping ${name}" || fail "ansible ping ${name}"
  done < /tmp/ansible_ping.log
else
  fail "ansible ping 전체 실패 — 아래 출력을 확인할 것"
  sed 's/^/       /' /tmp/ansible_ping.log
fi

echo ""
echo "[8] Ansible 권한 상승 (become)"
if ansible -i "$INV" all -u ubuntu -b --become-user=root -m command -a 'id -un' -o >/tmp/ansible_become.log 2>&1; then
  grep -c 'rc=0' /tmp/ansible_become.log >/dev/null && pass "become 으로 root 획득" || fail "become 실패"
else
  fail "become 실패 — 아래 출력을 확인할 것"
  sed 's/^/       /' /tmp/ansible_become.log
fi

echo ""
echo "=============================================="
printf " 통과 %d · 실패 %d\n" "$ok" "$ng"
echo "=============================================="
if [ "$ng" -eq 0 ]; then
  echo " 모두 통과. Kubespray 를 진행해도 된다."
  exit 0
else
  echo " 실패 항목을 먼저 해결할 것. cluster.yml 은 그 뒤에."
  exit 1
fi
