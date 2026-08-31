#!/bin/bash
# 콘솔 서버(i1) 전용 프로비저닝
#
#   1) AWS 경로와 같은 도구를 깐다 — 1.InstanceForTerraform/installOnEc2.sh 를 그대로 실행한다
#      (ansible · python · terraform · awscli. 로컬에서 terraform·awscli 는 쓰지 않지만
#       AWS 경로와 환경을 동일하게 두기 위해 스크립트를 나누지 않는다)
#   2) ubuntu 계정의 ssh 키를 만들고 공개키를 /vagrant/.keys/ 에 남긴다
#      -> vm01~vm0N 이 부팅하면서 이 키를 자기 authorized_keys 에 넣는다

set -uo pipefail

INSTALLER_LOCAL="/sreMsa/lab1.Kubespray/1.InstanceForTerraform/installOnEc2.sh"
INSTALLER_URL="https://raw.githubusercontent.com/Finfra/sreMsa/main/lab1.Kubespray/1.InstanceForTerraform/installOnEc2.sh"

echo "=== [i1] ubuntu 계정 ssh 키 생성 ==="
if [ ! -f /home/ubuntu/.ssh/id_rsa ]; then
  sudo -u ubuntu ssh-keygen -t rsa -b 2048 -f /home/ubuntu/.ssh/id_rsa -N '' -q
  echo "  새 키 생성"
else
  echo "  기존 키 사용"
fi

# i1 자신에게도 붙을 수 있게 해 둔다 (kubespray 가 vm01 을 대상으로 잡을 때와 동일한 경로 확인용)
sudo -u ubuntu bash -c 'cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'
sudo -u ubuntu bash -c 'sort -u /home/ubuntu/.ssh/authorized_keys -o /home/ubuntu/.ssh/authorized_keys'
chmod 600 /home/ubuntu/.ssh/authorized_keys

echo "=== [i1] 공개키를 /vagrant/.keys/ 로 복사 ==="
mkdir -p /vagrant/.keys
cp -f /home/ubuntu/.ssh/id_rsa.pub /vagrant/.keys/id_rsa.pub
chmod 644 /vagrant/.keys/id_rsa.pub
echo "  $(cat /vagrant/.keys/id_rsa.pub | cut -c1-50)..."

echo "=== [i1] DevOps 도구 설치 (installOnEc2.sh) ==="
echo "    5~10분 걸린다. apt·pip 다운로드가 대부분이다."
if [ -f "$INSTALLER_LOCAL" ]; then
  echo "    소스: ${INSTALLER_LOCAL} (공유 폴더)"
  bash "$INSTALLER_LOCAL"
else
  echo "    소스: ${INSTALLER_URL} (공유 폴더가 없어 원격에서 받음)"
  curl -fsSL "$INSTALLER_URL" | bash
fi

echo "=== [i1] 설치 확인 ==="
python  --version 2>&1 | sed 's/^/  /'
ansible --version 2>&1 | head -1 | sed 's/^/  /'

echo "=== [i1] 완료 ==="
echo "    다음: vagrant ssh i1   (접속하면 ubuntu 계정으로 바로 들어간다)"
