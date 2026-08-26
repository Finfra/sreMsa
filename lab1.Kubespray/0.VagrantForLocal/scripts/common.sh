#!/bin/bash
# 전 노드 공통 프로비저닝 (i1 · vm01~vm0N)
#
#   1) /etc/hosts 에 i1·vm0N 을 등록하고, 호스트명이 127.0.0.1 로 풀리는 것을 막는다
#   2) ubuntu 계정을 만든다 — AWS 인스턴스와 계정명을 맞추기 위한 것이다
#   3) swap 을 정리한다 — Kubernetes 노드는 끄고, i1 은 오히려 만들어 준다
#   4) 방화벽과 ssh 호스트키 확인을 끈다
#
# 인자 $1 : Vagrantfile 이 만들어 넘긴 hosts 블록

set -uo pipefail

HOSTS_BLOCK="${1:-}"
HN="$(hostname)"

echo "=== [common] ${HN} — /etc/hosts 갱신 ==="

# 호스트명이 루프백으로 풀리면 kubespray 가 노드 주소를 127.x 로 잡는다.
#
# Ubuntu 는 127.0.1.1 을, Vagrant 는 hostname 을 설정하면서 127.0.2.1 을 넣는다.
#   127.0.2.1 vm01 vm01     <- Vagrant 가 넣는 줄
# 이대로 두면 노드에서 `getent hosts vm01` 이 루프백을 답한다. 우리가 아래에서
# 넣는 실제 IP 보다 파일 위쪽에 있어 먼저 잡히기 때문이다.
#
# 그래서 127.x 대역에서 이 호스트명을 가리키는 줄을 모두 지운다.
# `127.0.0.1 localhost` 는 호스트명을 필드로 갖지 않으므로 그대로 살아남는다.
awk -v hn="$HN" '
  $1 ~ /^127\./ { for (i = 2; i <= NF; i++) if ($i == hn) next }
  { print }
' /etc/hosts > /tmp/hosts.new && cat /tmp/hosts.new > /etc/hosts && rm -f /tmp/hosts.new
sed -i '/^127\.0\.1\.1/d' /etc/hosts
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

if [ "$HN" = "i1" ]; then
  # i1 은 Kubernetes 노드가 아니라 kubelet 이 없다. swap 을 끌 이유가 없고,
  # 메모리를 작게 줬으므로 Ansible fork 가 몰리는 구간의 완충으로 오히려 필요하다.
  echo "=== [common] ${HN} — swap 확보 (Kubernetes 노드가 아니다) ==="
  if [ -f /swapfile ]; then
    echo "  이미 있음"
  else
    fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null
    grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "  2GB 생성"
  fi
  swapon /swapfile 2>/dev/null || true
  swapon --show || echo "  (swap 활성화 실패 — 메모리가 빠듯하면 settings.yml 의 i1.memory 를 올릴 것)"
else
  # Kubernetes 노드는 kubelet 이 swap 을 거부하므로 반드시 꺼야 한다.
  echo "=== [common] ${HN} — swap off (kubelet 요구사항) ==="
  swapoff -a || true
  sed -i '/[[:space:]]swap[[:space:]]/s/^\(.*\)$/#\1/' /etc/fstab
fi

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
