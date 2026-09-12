#!/bin/bash
# 기존 SSH known_hosts 파일 삭제 (새 인스턴스로 인한 충돌 방지)
if [ -f ~/.ssh/known_hosts ]; then
  echo "Removing old SSH known_hosts file..."
  rm -f ~/.ssh/known_hosts
fi

# 임시 파일 생성
tmpfile=$(mktemp)

# 현재 실행 중인 EC2 인스턴스 목록 가져오기
ec2_instances=$(aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value | [0]]' \
  --output text | tr '\n' '|' | sed 's/|$//')

# /etc/hosts에서 현재 EC2 인스턴스 이름들을 모두 제거
if [ -n "$ec2_instances" ]; then
  grep -vE "($ec2_instances)" /etc/hosts > "$tmpfile"
else
  cp /etc/hosts "$tmpfile"
fi

sudo cp "$tmpfile" /etc/hosts
rm -f "$tmpfile"

# 현재 실행 중인 EC2 인스턴스들을 /etc/hosts에 추가
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running \
  --query 'Reservations[*].Instances[*].[InstanceId, Tags[?Key==`Name`].Value | [0], PublicIpAddress]' \
  --output text |
while read -r ec2id ec2Name ip; do
  echo "$ip $ec2Name"
  sudo bash -c "echo $ip $ec2Name >> /etc/hosts"
done

echo "/etc/hosts------------"
cat /etc/hosts
echo "----------------------"

# 각 호스트에 접속해서 hostname 설정
echo ""
echo "Setting hostname on each VM..."
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value | [0], PublicIpAddress]' \
  --output text |
while read -r ec2Name ip; do
  # 현재 인스턴스는 제외
  if [ "$ec2Name" != "i1" ]; then
    echo "Setting hostname $ec2Name on $ip..."
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$ip "sudo hostnamectl set-hostname $ec2Name" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "  ✓ Hostname set successfully on $ec2Name"
    else
      echo "  ✗ Failed to set hostname on $ec2Name (might still be booting)"
    fi
  fi
done
echo "Hostname configuration complete!"
