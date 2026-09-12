#!/bin/bash
# doFixRbac.sh — kubeadm 1.29+ 의 admin.conf Forbidden 을 복구한다.
#
# 언제 쓰나:
#   kubectl 이 이렇게 막힐 때.
#     Error from server (Forbidden): nodes is forbidden:
#       User "kubernetes-admin" cannot list resource "nodes" at the cluster scope
#   또는 cluster.yml 이 여기서 실패할 때.
#     TASK [kubernetes/control-plane : Create kubeadm token ...]
#     stderr: unable to create Secret: secrets is forbidden: User ...
#
# 왜 생기나 (2026-09-06 실측):
#   1.28 이하 : admin.conf 가 O=system:masters       → RBAC 우회 super-user
#   1.29 이상 : admin.conf 가 O=kubeadm:cluster-admins → ClusterRoleBinding 필요
#   kubeadm init 이 그 바인딩을 만들어야 하는데, apiserver 가 반복 재시작하면
#   (실측 attempt=34) 부트스트랩이 유실된다. 권한이 없으니 kubectl 로 바인딩을
#   만들 수도 없어 순환에 빠진다.
#
# 어떻게 끊나:
#   1.29+ 가 남기는 super-admin.conf(O=system:masters)로 바인딩을 직접 만든다.
#
# 사용: 안쪽 control-plane 노드(vm01)에서 root 로 실행

set -eu
SA=/etc/kubernetes/super-admin.conf

[ -f "$SA" ] || { echo "❌ $SA 없음 — 1.29 미만이면 다른 경로가 필요하다"; exit 1; }

echo "== super-admin.conf 확인 =="
grep client-certificate-data "$SA" | awk '{print $2}' | base64 -d | openssl x509 -noout -subject

echo "== ClusterRoleBinding 생성 =="
kubectl --kubeconfig="$SA" create clusterrolebinding kubeadm-cluster-admins \
  --clusterrole=cluster-admin --group=kubeadm:cluster-admins 2>&1 || echo "  (이미 있으면 무시)"

echo "== admin.conf 를 root kubeconfig 로 설치 =="
mkdir -p /root/.kube
cp -f /etc/kubernetes/admin.conf /root/.kube/config
chmod 600 /root/.kube/config

echo "== 검증 =="
kubectl get no -o wide
