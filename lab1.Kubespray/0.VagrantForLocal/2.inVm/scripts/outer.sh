#!/bin/bash
# 바깥 VM(i1) 프로비저닝 — 이 안에서 vm01~vm03 을 만들 수 있게 준비한다.
#
#   1) LVM 확장 — box 기본 디스크는 64GB 인데 LVM 이 31GB 만 잡는다(실측).
#                안쪽 노드 3대가 18GB 이상 쓰므로 전량으로 넓힌다.
#   2) VirtualBox 설치 — 안쪽 VM 을 만들 하이퍼바이저
#   3) Vagrant 설치 — Ubuntu 24.04 리포에 없어(실측: Candidate 없음) HashiCorp 저장소를 쓴다
#   4) ubuntu 계정 — 상위 폴더와 같은 규약(sudo 무암호)
#   5) Kubespray 도구 + 전용 venv
#
# 인자: $1 virtualbox 패키지명 · $2 vagrant 설치 출처 · $3 deb URL · $4 LVM 확장 여부

set -uo pipefail

VBOX_PKG="${1:-virtualbox}"
VAGRANT_FROM="${2:-hashicorp}"
VAGRANT_DEB="${3:-}"
EXPAND_LVM="${4:-yes}"

export DEBIAN_FRONTEND=noninteractive

say(){ echo "=== [outer] $* ==="; }

# ---------------------------------------------------------------- 0) 공유 폴더
say "0/6 공유 폴더 확인·복구"
# ⚠️ 커널을 올린 직후의 부팅에서는 Guest Additions 가 아직 **옛 커널용**이라
#    vboxsf 마운트가 조용히 실패한다. /sreMsa 가 빈 디렉토리로 남고,
#    그러면 이 스크립트가 6단계에서 installOnEc2.sh 를 못 찾는다.
#
#    2026-08-31 실측: 그 상태에서 `vagrant reload` 를 한 번 더 하면
#    중첩 환경의 커널이 RCU 스톨에 빠져(task blocked 368s+) 부팅 자체가 멈췄다.
#    그래서 재부팅을 늘리는 대신 **여기서 GA 를 재빌드하고 직접 마운트**한다.
#
#    공유 폴더 이름은 Vagrantfile 의 마운트 지점에서 그대로 온다(실측 확인):
#      sreMsa -> /sreMsa · prgs -> /prgs · vagrant -> /vagrant
SHARES="sreMsa prgs vagrant"
need_remount=0
for m in $SHARES; do
  mountpoint -q "/$m" 2>/dev/null || need_remount=1
done

if [ "$need_remount" = "1" ]; then
  echo "  일부 공유 폴더가 붙지 않았다 — Guest Additions 를 현재 커널용으로 재빌드한다"
  GA="$(ls -d /opt/VBoxGuestAdditions-* 2>/dev/null | head -1)"
  if [ -n "$GA" ] && [ -x "$GA/init/vboxadd" ]; then
    echo "    $GA/init/vboxadd setup"
    "$GA/init/vboxadd" setup 2>&1 | tail -6 | sed 's/^/      /'
    systemctl restart vboxadd-service 2>/dev/null || true
  else
    echo "    GA 소스 폴더를 찾지 못했다 — dkms 경로로 시도"
    dpkg-reconfigure -f noninteractive virtualbox-guest-dkms 2>/dev/null || true
  fi
  modprobe vboxsf 2>/dev/null || true

  for m in $SHARES; do
    mountpoint -q "/$m" 2>/dev/null && continue
    [ -d "/$m" ] || mkdir -p "/$m"
    if mount -t vboxsf -o uid=0,gid=0 "$m" "/$m" 2>/dev/null; then
      echo "    /$m 마운트 성공"
    else
      echo "    /$m 마운트 실패"
    fi
  done
fi

for m in $SHARES; do
  if mountpoint -q "/$m" 2>/dev/null; then
    printf '  /%-8s OK (%s개 항목)\n' "$m" "$(ls -1 "/$m" 2>/dev/null | wc -l)"
  else
    printf '  /%-8s !! 마운트 안 됨\n' "$m"
  fi
done

# ---------------------------------------------------------------- 1) 디스크
say "1/6 디스크 확장"
if [ "$EXPAND_LVM" = "yes" ]; then
  before=$(df -h / | awk 'NR==2{print $2}')
  LV=$(lvs --noheadings -o lv_path 2>/dev/null | head -1 | tr -d ' ')
  if [ -n "$LV" ]; then
    lvextend -l +100%FREE "$LV" 2>&1 | sed 's/^/  /' || true
    resize2fs "$LV" 2>&1 | tail -2 | sed 's/^/  /' || true
    echo "  / : ${before} -> $(df -h / | awk 'NR==2{print $2}')"
  else
    echo "  LVM 을 찾지 못했다 — 건너뛴다"
  fi
else
  echo "  건너뜀 (settings.yml 의 expand_lvm: false)"
fi

# ---------------------------------------------------------------- 2) 계정
say "2/6 ubuntu 계정 준비"
# 상위 폴더 scripts/common.sh 와 같은 규약이다. 안쪽 실습 명령이 그대로 통해야 한다.
if ! id -u ubuntu >/dev/null 2>&1; then
  useradd -m -s /bin/bash ubuntu
  echo "  ubuntu 생성"
else
  echo "  ubuntu 이미 있음"
fi
echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-ubuntu
chmod 440 /etc/sudoers.d/90-ubuntu
install -d -m 700 -o ubuntu -g ubuntu /home/ubuntu/.ssh
if [ -f /home/vagrant/.ssh/authorized_keys ]; then
  cat /home/vagrant/.ssh/authorized_keys >> /home/ubuntu/.ssh/authorized_keys
  sort -u /home/ubuntu/.ssh/authorized_keys -o /home/ubuntu/.ssh/authorized_keys
  chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
  chmod 600 /home/ubuntu/.ssh/authorized_keys
fi

# `vagrant ssh` 로 들어오면 ubuntu 셸로 전환한다 (상위 폴더와 동일).
# 대화형일 때만 바꾼다 — 비대화형까지 바꾸면 프로비저닝·rsync 가 깨진다.
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
fi

# i1 은 Kubernetes 노드가 아니므로 swap 을 켜 둔다. 안쪽 VM 을 띄우는 동안
# 메모리가 몰리는 구간의 완충이 된다.
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
  chmod 600 /swapfile; mkswap /swapfile >/dev/null
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  swapon /swapfile 2>/dev/null || true
  echo "  swap 2GB 생성"
fi

systemctl disable --now ufw >/dev/null 2>&1 || true

# motd 비활성 — 상위 폴더 scripts/common.sh 와 같은 조치.
# Ubuntu 동적 motd 8개가 로그인마다 약 30초를 먹고, pam_motd 는 비대화형 ssh 에도 걸린다.
chmod -x /etc/update-motd.d/* 2>/dev/null || true
sed -i 's/^\(session[[:space:]]*optional[[:space:]]*pam_motd\.so.*\)$/#\1/' /etc/pam.d/sshd 2>/dev/null || true
[ -f /etc/default/motd-news ] && sed -i 's/^ENABLED=1/ENABLED=0/' /etc/default/motd-news
rm -f /run/motd.dynamic 2>/dev/null || true
echo "  motd 비활성 완료"

# ---------------------------------------------------------------- 3) VirtualBox
say "3/6 VirtualBox 설치 (몇 분 걸린다)"
apt-get update -qq 2>&1 | tail -2

# ⚠️ box 커널의 헤더가 리포에서 내려간 경우가 있다 (2026-08-30 실측).
#    bento/ubuntu-24.04 가 커널 6.8.0-86 으로 굳어 있는데 archive 에는
#    linux-headers-6.8.0-86-generic 이 더 없다(Candidate: none). 그러면
#    linux-headers-generic 이 최신(6.8.0-138)을 끌어오고 DKMS 는 그 커널용으로
#    빌드해 버려서, 정작 실행 중인 커널에는 vboxdrv 가 없는 상태가 된다.
#    설치는 성공한 것처럼 보이는데 VM 을 켤 때만 죽는다.
#
#    그래서 헤더 가용 여부를 먼저 보고, 없으면 커널 자체를 올린 뒤 재부팅한다.
KVER="$(uname -r)"
NEED_REBOOT=0
if apt-cache policy "linux-headers-${KVER}" 2>/dev/null | grep -qE "Candidate: [0-9]"; then
  echo "  실행 커널(${KVER}) 헤더가 리포에 있다 — 그대로 진행"
  apt-get install -y -qq "linux-headers-${KVER}" 2>&1 | tail -2
else
  echo "  !! 실행 커널(${KVER}) 의 헤더가 리포에 없다"
  echo "     커널을 최신으로 올린다. 반영하려면 재부팅이 필요하다."
  apt-get install -y -qq linux-image-generic linux-headers-generic 2>&1 | tail -3
  NEW="$(ls -1 /lib/modules 2>/dev/null | sort -V | tail -1)"
  echo "     설치된 최신 커널: ${NEW}"
  [ "$NEW" != "$KVER" ] && NEED_REBOOT=1
fi

# ⚠️ 커널 헤더를 함께 깔지 않으면 DKMS 가 vboxdrv 모듈을 만들지 못한다.
#    그러면 설치는 성공한 것처럼 보이는데 VM 을 켤 때 이렇게 죽는다.
#      "Please install the virtualbox-dkms package and the appropriate headers"
#    2026-08-30 실측에서 실제로 이 상태가 됐다. 헤더는 실행 중인 커널 것이어야 한다.
apt-get install -y -qq \
  "$VBOX_PKG" virtualbox-dkms dkms build-essential 2>&1 | tail -5

for u in ubuntu vagrant; do usermod -aG vboxusers "$u" 2>/dev/null || true; done

# 모듈을 실제로 올린다. DKMS 빌드가 늦게 끝나는 경우가 있어 명시적으로 부른다.
echo "  커널 모듈 빌드·적재"
if command -v /sbin/vboxconfig >/dev/null 2>&1; then
  /sbin/vboxconfig 2>&1 | tail -5 | sed 's/^/    /'
else
  dpkg-reconfigure -f noninteractive virtualbox-dkms 2>&1 | tail -3 | sed 's/^/    /' || true
  modprobe vboxdrv 2>&1 | sed 's/^/    /' || true
fi

echo "  버전: $(VBoxManage --version 2>/dev/null || echo '확인 실패')"
if lsmod | grep -q '^vboxdrv'; then
  echo "  vboxdrv 적재됨 ✔"
elif [ "$NEED_REBOOT" = "1" ]; then
  echo "  ⏳ 커널을 올렸으므로 재부팅 후에 적재된다. 호스트에서:"
  echo "       vagrant reload --provision"
else
  echo "  !! vboxdrv 가 없다 — 안쪽 VM 을 켤 수 없다."
  echo "     dkms status / dmesg | grep -i vbox 로 원인을 확인할 것"
fi

# host-only 대역 허용. 192.168.56.0/21 은 VirtualBox 기본 허용 범위지만,
# 배포판 패키지는 이 파일이 없는 채로 설치되는 경우가 있어 명시해 둔다.
install -d /etc/vbox
if [ ! -f /etc/vbox/networks.conf ]; then
  printf '* 192.168.56.0/21\n* 3001::/64\n' > /etc/vbox/networks.conf
  echo "  /etc/vbox/networks.conf 생성"
fi

# ---------------------------------------------------------------- 4) Vagrant
say "4/6 Vagrant 설치"
if command -v vagrant >/dev/null 2>&1; then
  echo "  이미 있음: $(vagrant --version)"
elif [ "$VAGRANT_FROM" = "deb_url" ] && [ -n "$VAGRANT_DEB" ]; then
  echo "  출처: ${VAGRANT_DEB}"
  wget -qO /tmp/vagrant.deb "$VAGRANT_DEB" && dpkg -i /tmp/vagrant.deb 2>&1 | tail -3
else
  # Ubuntu 24.04(noble) 리포에는 vagrant 가 없다 — 실측으로 확인했다.
  echo "  출처: HashiCorp apt 저장소"
  apt-get install -y -qq wget gpg lsb-release 2>&1 | tail -2
  wget -qO- https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list
  apt-get update -qq 2>&1 | tail -2
  apt-get install -y -qq vagrant 2>&1 | tail -3
fi
echo "  버전: $(vagrant --version 2>/dev/null || echo '설치 실패')"

# ---------------------------------------------------------------- 5) ssh 키
say "5/6 ubuntu ssh 키 (i1 -> 안쪽 노드)"
if [ ! -f /home/ubuntu/.ssh/id_rsa ]; then
  sudo -u ubuntu ssh-keygen -t rsa -b 2048 -f /home/ubuntu/.ssh/id_rsa -N '' -q
  echo "  생성"
else
  echo "  기존 키 사용"
fi
sudo -u ubuntu bash -c 'cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys; sort -u /home/ubuntu/.ssh/authorized_keys -o /home/ubuntu/.ssh/authorized_keys'
chmod 600 /home/ubuntu/.ssh/authorized_keys
grep -q '^StrictHostKeyChecking' /etc/ssh/ssh_config || echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config
grep -q '^UserKnownHostsFile' /etc/ssh/ssh_config || echo 'UserKnownHostsFile /dev/null' >> /etc/ssh/ssh_config

# ---------------------------------------------------------------- 6) Kubespray 도구
say "6/6 Kubespray 도구 설치"
INSTALLER=/sreMsa/lab1.Kubespray/1.InstanceForTerraform/installOnEc2.sh
if [ -f "$INSTALLER" ]; then
  echo "  ${INSTALLER} 실행 (5~10분)"
  bash "$INSTALLER" 2>&1 | tail -5
else
  echo "  !! ${INSTALLER} 없음 — 공유 폴더 마운트를 확인할 것"
fi

echo ""
say "완료"
echo "  다음: vagrant ssh   (ubuntu 계정으로 들어간다)"
echo "        그 안에서  bash /sreMsa/lab1.Kubespray/0.VagrantForLocal/2.inVm/inner/doInner.sh"
