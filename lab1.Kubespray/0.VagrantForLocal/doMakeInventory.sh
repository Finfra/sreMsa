#!/bin/bash
# Kubespray inventory 를 만든다. i1 안에서 실행한다.
#
# AWS 경로(3.InstanceForKubernetes/README.md 5~6단계)와 같은 내용이되
# 로컬에서는 한 가지가 반드시 다르다.
#
#   ip=<host-only IP> 를 노드마다 명시해야 한다.
#
# VirtualBox VM 은 eth0 이 NAT 이고 그 주소가 모든 VM 에서 10.0.2.15 로 같다.
# ip= 를 주지 않으면 kubespray 가 그 주소를 노드 주소로 잡아 클러스터가 깨진다.
# AWS 에서는 이 문제가 없어 ip= 가 필요 없었다.

set -uo pipefail

GEN="${GEN:-/vagrant/hosts.generated}"
KSDIR="${KSDIR:-$HOME/kubespray}"

if [ ! -f "$GEN" ]; then
  echo "!! ${GEN} 가 없다."; exit 1
fi
if [ ! -d "$KSDIR" ]; then
  echo "!! ${KSDIR} 가 없다. 먼저 kubespray 를 clone 할 것:"
  echo "!!   git clone -b release-2.28 https://github.com/kubernetes-sigs/kubespray ~/kubespray"
  exit 1
fi

# hosts.generated 에서 노드 목록을 읽는다 (i1 은 Kubernetes 노드가 아니므로 제외)
# Windows 호스트가 만든 파일이라 CR 이 섞일 수 있다. 먼저 제거한다.
GEN_CLEAN="$(mktemp)"
tr -d '\r' < "$GEN" > "$GEN_CLEAN"

names=(); ips=()
while read -r ip name; do
  [ -z "$name" ] && continue
  [ "$name" = "i1" ] && continue
  names+=("$name"); ips+=("$ip")
done < "$GEN_CLEAN"

n="${#names[@]}"
if [ "$n" -lt 1 ]; then echo "!! 노드가 없다."; exit 1; fi

# control plane 은 AWS 경로와 같게 앞의 2대로 둔다 (노드가 1대뿐이면 1대)
cp_count=2
[ "$n" -lt 2 ] && cp_count=1

mkdir -p "${KSDIR}/inventory/group_vars/all"

{
  echo "[all]"
  for i in $(seq 0 $((n-1))); do
    line="${names[$i]} ansible_host=${ips[$i]} ip=${ips[$i]}"
    [ "$i" -eq 0 ] && line="${line} etcd_member_name=etcd1"
    echo "$line"
  done
  echo ""
  echo "[kube_control_plane]"
  for i in $(seq 0 $((cp_count-1))); do echo "${names[$i]}"; done
  echo ""
  echo "[etcd]"
  echo "${names[0]}"
  echo ""
  echo "[kube_node]"
  for i in $(seq 0 $((n-1))); do echo "${names[$i]}"; done
  echo ""
  echo "[k8s_cluster:children]"
  echo "kube_control_plane"
  echo "kube_node"
} > "${KSDIR}/inventory/inventory.ini"

cat > "${KSDIR}/inventory/group_vars/all/all.yml" <<'YAML'
# AWS 경로와 동일한 항목
ping_access_ip: false
wait_for_services_timeout: 900
kube_apiserver_request_timeout: "90s"

# 로컬(VirtualBox) 전용
# 회선이 느리거나 강의장에서 여러 명이 동시에 설치할 때는 아래를 켠다.
# 바이너리를 노드마다 받지 않고 한 번만 받아 나눠 주므로 외부 트래픽이 1/N 로 준다.
# 다만 배포 단계가 늘어 전체 시간은 오히려 길어질 수 있고 아직 실기 검증 전이라
# 기본은 꺼 둔다. (검증 필요)
# download_run_once: true
# download_localhost: false
YAML

echo "=== ${KSDIR}/inventory/inventory.ini ==="
cat "${KSDIR}/inventory/inventory.ini"
echo ""
echo "=== ${KSDIR}/inventory/group_vars/all/all.yml ==="
cat "${KSDIR}/inventory/group_vars/all/all.yml"
