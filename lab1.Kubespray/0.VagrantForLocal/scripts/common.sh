#!/bin/bash
# 전 노드 공통 프로비저닝 (i1 · vm01~vm0N)
#
#   1) /etc/hosts 에 i1·vm0N 을 등록하고, 호스트명이 127.0.0.1 로 풀리는 것을 막는다
#   2) ubuntu 계정을 만든다 — AWS 인스턴스와 계정명을 맞추기 위한 것이다
#   3) swap 을 끄고 ssh 의 호스트키 확인을 끈다
#
# 인자 $1 : Vagrantfile 이 만들어 넘긴 hosts 블록

set -uo pipefail

HOSTS_BLOCK="${1:-}"
HN="$(hostname)"

echo "=== [common] ${HN} — /etc/hosts 갱신 ==="

# 호스트명이 루프백으로 풀리면 kubespray 가 노드 주소를 127.x 로 잡는다.
# 그 줄들을 지우고 아래에서 실제 host-only IP 로 다시 넣는다.
sed -i '/^127\.0\.1\.1/d' /etc/hosts
sed -i "/^127\.0\.0\.1[[:space:]]\+${HN}\([[:space:]]\|$\)/d" /etc/hosts
grep -qE '^127\.0\.0\.1[[:space:]]+localhost' /etc/hosts || sed -i '1i 127.0.0.1 localhost' /etc/hosts

# 마커 사이만 교체한다. 재실행해도 중복되지 않는다.
sed -i '/# >>> sreMsa >>>/,/# <<< sreMsa <<</d' /etc/hosts
{
  echo "# >>> sreMsa >>>"
  printf '%s\n' "$HOSTS_BLOCK"
  echo "# <<< sreMsa <<<"
} >> /etc/hosts

echo "--- /etc/hosts ---"
cat /etc/hosts
echo "------------------"

echo "=== [common] ${HN} — ubuntu 계정 준비 ==="
# AWS 경로가 `ssh ubuntu@vm01`, `ansible-playbook -u ubuntu` 를 쓰므로
# 로컬에도 같은 이름의 계정을 둔다.
if ! id -u ubuntu >/dev/null 2>&1; then
  useradd -m -s /bin/bash ubuntu
  echo "ubuntu 계정 생성"
else
  echo "ubuntu 계정 이미 있음"
fi

# sudo 무암호 — kubespray 의 --become 이 암호를 묻지 않게 한다
echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-ubuntu
chmod 440 /etc/sudoers.d/90-ubuntu

install -d -m 700 -o ubuntu -g ubuntu /home/ubuntu/.ssh

echo "=== [common] ${HN} — swap off ==="
swapoff -a || true
sed -i '/[[:space:]]swap[[:space:]]/s/^\(.*\)$/#\1/' /etc/fstab

echo "=== [common] ${HN} — 방화벽 비활성 ==="
# kubespray 요구사항: "The firewalls are not managed, you'll need to implement
# your own rules... you should disable your firewall"
systemctl disable --now ufw >/dev/null 2>&1 || true
ufw disable >/dev/null 2>&1 || true

echo "=== [common] ${HN} — ssh 호스트키 확인 끄기 ==="
grep -q '^StrictHostKeyChecking' /etc/ssh/ssh_config || \
  echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config
grep -q '^UserKnownHostsFile' /etc/ssh/ssh_config || \
  echo 'UserKnownHostsFile /dev/null' >> /etc/ssh/ssh_config

echo "=== [common] ${HN} 완료 ==="
