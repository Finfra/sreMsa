#!/bin/bash

# This is Simple Script executor

ec2IdsAndName=$(aws ec2 describe-instances     --filters Name=instance-state-name,Values=running     --query 'Reservations[*].Instances[].[InstanceId, Tags[?Key==`Name`]]' --output text|sed -z  "s/\\nName[[:blank:]]/,/g")
for i in $ec2IdsAndName; do
	  ec2id=$(echo $i|awk 'BEGIN{FS=","}{printf $1}')
	  ec2Name=$(echo $i|awk 'BEGIN{FS=","}{printf $2}')
    ip=$(aws ec2 describe-instances --instance-ids $ec2id --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
	  # echo "ssh ubuntu@$ip hostname"
		echo Instance Id : $ec2id ,Public : $ip , Instance Name:  $ec2Name
	  # scp $(pwd)/do.sh $ip:/tmp/do.sh
	  # # ssh ubuntu@$ip sudo sh -c '/usr/bin/chmod +x /tmp/do.sh'
		# ssh ubuntu@$ip  'sudo chmod 755 /tmp/do.sh'
	  # ssh ubuntu@$ip sudo sh -c '/tmp/do.sh'
done
