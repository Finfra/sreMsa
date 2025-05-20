#!/bin/bash
tmpfile=$(mktemp)
grep -v vm0 /etc/hosts > "$tmpfile"
sudo cp "$tmpfile" /etc/hosts
rm -f "$tmpfile"

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
