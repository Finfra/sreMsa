#!/bin/bash
# 바깥 VM(i1) 안에서 실행 — 안쪽 노드 vm01~vm03 을 만들고 Kubespray 까지 준비한다.
#
#   bash /sreMsa/lab1.Kubespray/0.VagrantForLocal/2.inVm/inner/doInner.sh
#
# 하는 일
#   1) 바깥 VM 의 ubuntu 공개키를 .keys/ 에 둔다 (안쪽 노드가 이 키를 신뢰한다)
#   2) box 를 확보한다 — /prgs 에 있으면 그것을 쓰고, 없으면 내려받는다
#   3) vagrant up 으로 vm01~vm03 을 만든다
#   4) Kubespray 와 전용 venv 를 준비한다
#
# ⚠️ venv 가 필요한 이유 (2026-08-30 실측)
#   installOnEc2.sh 가 설치하는 ansible 은 core 2.17.x 인데 kubespray release-2.28 은
#   `2.16.4 <= ansible < 2.17.0` 을 요구해 cluster.yml 이 첫 태스크에서 죽는다.
#   requirements.txt 가 ansible==9.13.0(core 2.16.x)을 고정하므로 venv 로 맞춘다.

set -uo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"          # 공유 폴더 안의 원본 (2.inVm/inner)
INVM="$(cd "$SRC/.." && pwd)"                 # 2.inVm
# 프로비저닝 스크립트(common.sh·node.sh)는 이웃 폴더 1.vm4 것을 그대로 쓴다.
# 복제하지 않으므로 1.vm4 를 고치면 이쪽에도 반영된다.
export SREMSA_LOCAL="$(cd "$INVM/../1.vm4" && pwd)"

# ⚠️ 작업 폴더는 반드시 로컬 디스크여야 한다.
#    공유 폴더(vboxsf)에서 `vagrant up` 하면 이렇게 죽는다 (2026-08-30 실측):
#      "The private key to connect to the machine via SSH must be owned
#       by the user running Vagrant."
#    vboxsf 가 소유권을 마운트 옵션으로 고정해 Vagrant 가 키 소유자를 바꿀 수 없고,
#    ssh 는 그런 키를 거부한다. 그래서 필요한 파일만 홈으로 복사해 거기서 돈다.
BASE="${SREMSA_INNER_DIR:-$HOME/inner}"

say(){ echo ""; echo "=== [inner] $* ==="; }

# ---------------------------------------------------------------- 0) 전제 확인
say "0/6 전제 확인"
if [ "$(id -un)" != "ubuntu" ]; then
  echo "  !! ubuntu 계정으로 실행할 것 (현재: $(id -un))"
  echo "     sudo -i -u ubuntu 후 다시 실행"
  exit 1
fi
command -v VBoxManage >/dev/null 2>&1 || { echo "  !! VirtualBox 가 없다"; exit 1; }
command -v vagrant    >/dev/null 2>&1 || { echo "  !! Vagrant 가 없다"; exit 1; }
echo "  VirtualBox : $(VBoxManage --version)"
echo "  Vagrant    : $(vagrant --version)"
echo "  VT-x       : $(lscpu | grep -i '^Virtualization' | awk '{print $2}')"
if ! lscpu | grep -qi 'VT-x\|AMD-V'; then
  echo "  !! 게스트에 가상화 확장이 없다. 바깥 VM 의 --nested-hw-virt 설정을 확인할 것"
  exit 1
fi
echo "  메모리     : $(free -g | awk 'NR==2{print $2}')GB (총) / $(free -g | awk 'NR==2{print $7}')GB (가용)"
echo "  디스크     : $(df -h / | awk 'NR==2{print $4}') 여유"

# ---------------------------------------------------------------- 1) 작업 폴더 · 키
say "1/6 작업 폴더 준비 (로컬 디스크) · i1 공개키 배치"
mkdir -p "$BASE/.keys"
cp -f "$SRC/Vagrantfile"   "$BASE/Vagrantfile"
cp -f "$INVM/settings.yml" "$BASE/settings.yml"
echo "  작업 폴더: $BASE  (원본: $SRC)"
echo "  상위 폴더: $SREMSA_LOCAL"
if [ -f ~/.ssh/id_rsa.pub ]; then
  cp -f ~/.ssh/id_rsa.pub "$BASE/.keys/id_rsa.pub"
  echo "  $(cut -c1-50 "$BASE/.keys/id_rsa.pub")..."
else
  echo "  !! ~/.ssh/id_rsa.pub 이 없다. outer.sh 가 제대로 돌았는지 확인할 것"
  exit 1
fi

# ---------------------------------------------------------------- 2) box
say "2/6 box 확보"
BOX_NAME="bento/ubuntu-24.04"
if vagrant box list 2>/dev/null | grep -q "$BOX_NAME"; then
  echo "  이미 등록됨: $(vagrant box list | grep "$BOX_NAME")"
else
  LOCAL_BOX=""
  for d in /prgs /sreMsa/_prgs /sreMsa/lab1.Kubespray/_prgs; do
    [ -d "$d" ] || continue
    f=$(ls "$d"/*.box 2>/dev/null | head -1)
    [ -n "$f" ] && { LOCAL_BOX="$f"; break; }
  done
  if [ -n "$LOCAL_BOX" ]; then
    echo "  로컬 파일에서 등록: $LOCAL_BOX"
    vagrant box add "$BOX_NAME" "$LOCAL_BOX" --force 2>&1 | tail -3
  else
    echo "  로컬 box 없음 — 내려받는다 (621MB, 회선에 따라 오래 걸린다)"
    vagrant box add "$BOX_NAME" --provider virtualbox 2>&1 | tail -3
  fi
fi

# ---------------------------------------------------------------- 3) 노드 생성
say "3/6 안쪽 노드 생성 (vagrant up)"
cd "$BASE" || { echo "  !! 작업 폴더 진입 실패: $BASE"; exit 1; }
echo "  중첩 가상화라 상위 폴더 방식보다 느리다."
date '+  %H:%M:%S 시작'
# 실패 원인을 놓치지 않도록 전체 로그를 남기고 요약만 화면에 낸다.
vagrant up < /dev/null > "$BASE/up.log" 2>&1
UP_RC=$?
grep -E "Importing|Booting|Machine booted|Mounting|common\]|node\]|error|Error|Warning|must be owned|Timed out" "$BASE/up.log" | tail -40
if [ "$UP_RC" != "0" ]; then
  echo "  !! vagrant up 실패 (rc=$UP_RC) — 전체 로그: $BASE/up.log"
  tail -20 "$BASE/up.log" | sed 's/^/    /'
fi
date '+  %H:%M:%S 종료'

echo "--- 상태 ---"
vagrant status 2>&1 | sed -n '3,10p'
VBoxManage list runningvms | sed 's/^/  /'

# ---------------------------------------------------------------- 4) hosts
say "4/6 이름 해석 준비"
if ! grep -q '# >>> sreMsa >>>' /etc/hosts 2>/dev/null; then
  {
    echo "# >>> sreMsa >>>"
    cat "$BASE/hosts.generated"
    echo "# <<< sreMsa <<<"
  } | sudo tee -a /etc/hosts >/dev/null
  echo "  /etc/hosts 갱신"
else
  echo "  이미 등록됨"
fi
for n in vm01 vm02 vm03; do
  printf '  %s -> ' "$n"
  # -n 은 필수다. ssh 가 stdin 을 읽어 버리면, 이 스크립트를 `bash -s` 로
  # 넘겨 실행하는 경우 나머지 줄이 통째로 사라진다(2026-08-30 실측).
  ssh -n -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$n hostname 2>/dev/null || echo "접속 실패"
done

# ---------------------------------------------------------------- 5) Kubespray
say "5/6 Kubespray + venv 준비"
cd ~ || exit 1
if [ ! -d ~/kubespray ]; then
  git clone -b release-2.28 https://github.com/kubernetes-sigs/kubespray 2>&1 | tail -2
fi
cd ~/kubespray || exit 1
echo "  커밋: $(git log -1 --format='%H' | cut -c1-12)  galaxy: $(grep '^version:' galaxy.yml | awk '{print $2}')"

if [ ! -d ~/ksvenv ]; then
  echo "  venv 생성 (ansible 을 kubespray 요구 버전으로 맞춘다)"
  python3 -m venv ~/ksvenv
  source ~/ksvenv/bin/activate
  pip install -q -U pip
  pip install -q -r ~/kubespray/requirements.txt
else
  source ~/ksvenv/bin/activate
fi
echo "  ansible: $(ansible --version | head -1)"

# ---------------------------------------------------------------- 6) 중첩 전용 설정
say "6/6 중첩 전용 타임아웃 상향"
# ⚠️ 중첩 가상화에서는 kubeadm join 의 TLS Bootstrap 이 kubespray 기본 제한 120초를
#    넘겨 rc=124(timeout)로 죽는다. 2026-08-30 실측에서 vm01·vm02 는 failed=0 으로
#    끝났는데 vm03 워커 join 만 정확히 이 지점에서 걸렸다.
#    설정 오류가 아니라 속도 문제이므로 제한만 늘린다.
GV=~/kubespray/inventory/group_vars/all/all.yml
if [ -f "$GV" ] && ! grep -q 'kubeadm_join_timeout' "$GV"; then
  cat >> "$GV" <<'YML'

# --- 중첩(nested) 환경 전용 ---
# 기본 120s 로는 kubeadm join 의 TLS Bootstrap 이 끝나지 않는다(실측 rc=124).
kubeadm_join_timeout: 600s
kubeadm_init_timeout: 600s
YML
  echo "  kubeadm_join_timeout: 600s 추가"
else
  echo "  이미 설정됨 (또는 inventory 미생성 — cluster.yml 전에 doMakeInventory.sh 실행 필요)"
fi

echo ""
echo "=== [inner] 완료 ==="
echo "  다음 단계 — 안쪽 노드에 Kubernetes 를 올린다:"
echo ""
echo "    source ~/ksvenv/bin/activate"
echo "    cd ~/kubespray"
echo "    bash /sreMsa/lab1.Kubespray/0.VagrantForLocal/1.vm4/doMakeInventory.sh"
echo "    ansible-playbook --flush-cache -u ubuntu -b --become --become-user=root \\"
echo "      -i inventory/inventory.ini --private-key ~/.ssh/id_rsa cluster.yml"
