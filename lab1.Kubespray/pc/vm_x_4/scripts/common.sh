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

# vagrant 계정이 신뢰하는 키를 ubuntu 에도 넣는다.
# `vagrant ssh-config` 로 뽑은 설정으로 `ubuntu@` 에 직접 붙을 수 있게 된다.
if [ -f /home/vagrant/.ssh/authorized_keys ]; then
  cat /home/vagrant/.ssh/authorized_keys >> /home/ubuntu/.ssh/authorized_keys
  sort -u /home/ubuntu/.ssh/authorized_keys -o /home/ubuntu/.ssh/authorized_keys
  chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
  chmod 600 /home/ubuntu/.ssh/authorized_keys
fi

# `vagrant ssh` 로 들어오면 곧바로 ubuntu 셸로 전환한다.
#
# 이 실습의 명령은 전부 ubuntu 계정 기준이다. vagrant 계정 상태로 doVerify.sh 를
# 돌리면 [0] 이 "sudo su - ubuntu 후 실행할 것" 을 안내하고 끝나는데, 그 한 번의
# 실행이 남긴 파일이 이후 ubuntu 로 제대로 실행해도 계속 실패하게 만들었다.
# 처음부터 ubuntu 로 떨어뜨려 그 사슬을 끊는다.
#
# 두 가지를 지킨다.
#   * `su - ubuntu` 는 못 쓴다. useradd 로 만든 ubuntu 는 비밀번호가 잠긴 상태
#     (passwd -S 가 L)라 su 가 인증에 실패한다. vagrant 는 NOPASSWD sudo 를
#     가지므로 `sudo -i -u ubuntu` 를 쓴다.
#   * 대화형($- 에 i 포함)일 때만 전환한다. `vagrant ssh -c "..."` · 프로비저닝 ·
#     rsync 같은 비대화형 경로가 vagrant 계정으로 남아야 vagrant up 이 깨지지 않는다.
if ! grep -q 'SREMSA_AS_UBUNTU' /home/vagrant/.bashrc 2>/dev/null; then
  cat >> /home/vagrant/.bashrc <<'RC'

# --- sreMsa: vagrant ssh 로 들어오면 ubuntu 셸로 전환 ---
if [[ $- == *i* ]] && [ "$(id -un)" = "vagrant" ] \
   && [ -z "${SREMSA_AS_UBUNTU:-}" ] && id -u ubuntu >/dev/null 2>&1; then
  export SREMSA_AS_UBUNTU=1
  exec sudo -i -u ubuntu
fi
RC
  chown vagrant:vagrant /home/vagrant/.bashrc
  echo "  vagrant -> ubuntu 자동 전환 등록"
else
  echo "  vagrant -> ubuntu 자동 전환 이미 등록됨"
fi

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

echo "=== [common] ${HN} — motd 비활성 (ssh 접속 지연 제거) ==="
# Ubuntu 의 동적 motd 는 로그인마다 /etc/update-motd.d/ 를 전부 실행한다.
# 2026-08-30 실측(bento/ubuntu-24.04) — 8개 합계 약 30초:
#   50-landscape-sysinfo 7.1s · 10-help-text 6.6s · 50-motd-news 4.3s(인터넷 접속 시도)
#   85-fwupd 4.1s · 91-contract-ua-esm-status 3.5s · 99-bento 2.6s · 97-overlayroot 1.5s
#
# ⚠️ pam_motd 는 **비대화형 ssh 에도** 걸린다. 그래서 사람이 `ssh vm01` 할 때만이 아니라
#    ansible 이 노드에 붙을 때마다 이 비용을 낸다. 실측에서 `ssh vm01 true` 가 14초였다.
#
# 지우지 않고 실행권한만 뗀다 — 되돌리려면 chmod +x 하면 된다.
chmod -x /etc/update-motd.d/* 2>/dev/null || true
# pam 단계에서 아예 부르지 않게 한다 (볼트 Debian.md "motd 내리기" 와 같은 조치)
sed -i 's/^\(session[[:space:]]*optional[[:space:]]*pam_motd\.so.*\)$/#\1/' /etc/pam.d/sshd 2>/dev/null || true
# motd-news 는 외부 접속을 시도하므로 설정으로도 끈다
[ -f /etc/default/motd-news ] && sed -i 's/^ENABLED=1/ENABLED=0/' /etc/default/motd-news
rm -f /run/motd.dynamic 2>/dev/null || true
echo "  update-motd.d 실행권한 해제 · pam_motd 주석 · motd-news 비활성"

echo "=== [common] ${HN} — ssh 호스트키 확인 끄기 ==="
grep -q '^StrictHostKeyChecking' /etc/ssh/ssh_config || \
  echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config
grep -q '^UserKnownHostsFile' /etc/ssh/ssh_config || \
  echo 'UserKnownHostsFile /dev/null' >> /etc/ssh/ssh_config

echo "=== [common] ${HN} 완료 ==="
