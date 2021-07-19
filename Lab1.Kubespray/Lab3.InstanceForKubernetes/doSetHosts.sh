#!/bin/bash
cat /etc/hosts |grep -v vm0>~/.tmp
sudo cp ~/.tmp /etc/hosts

ec2IdsAndName=$(aws ec2 describe-instances     --filters Name=instance-state-name,Values=running     --query 'Reservations[*].Instances[].[InstanceId, Tags[?Key==`Name`]]' --output text|sed -z  "s/\\nName[[:blank:]]/,/g")
for i in $ec2IdsAndName; do
	  ec2id=$(echo $i|awk 'BEGIN{FS=","}{printf $1}')
	  ec2Name=$(echo $i|awk 'BEGIN{FS=","}{printf $2}')
    ip=$(aws ec2 describe-instances --instance-ids $ec2id --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
    echo  $ip  $ec2Name
sudo bash -c "echo  $ip  $ec2Name  >> /etc/hosts"
done

echo "/etc/hosts------------"
cat /etc/hosts
echo "----------------------"
