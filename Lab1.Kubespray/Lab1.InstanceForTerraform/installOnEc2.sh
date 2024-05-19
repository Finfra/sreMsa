#!/bin/bash

# Version Setting
TERRAFORM_VERSION="1.8.3"
ANSIBE_VERSION="9.5.1"           # core 2.16.6

# System Variable Setting
export LC_ALL=C.UTF-8
export DEBIAN_FRONTEND=noninteractive

echo "export LC_ALL=C.UTF-8">>/etc/bash.bashrc
echo "export DEBIAN_FRONTEND=noninteractive">>/etc/bash.bashrc

hostname i1
hostname > /etc/hostname



apt -y update
apt -y install docker.io docker-compose unzip mysql-client unzip jq
groupadd docker
usermod -G docker ubuntu


# install pip
apt install -y python3-full
apt install -y python3-pip
pip3 install --break-system-packages numpy

[[ -f /usr/bin/python ]]&&rm /usr/bin/python
ln -s /usr/bin/python3.12 /usr/bin/python



# install awscli
python3 -m pip install --break-system-packages awscli
#python3 -m pip install  awsebcli
complete -C aws_completer aws

# install ansible
pip3 install --break-system-packages netaddr jinja2
pip3 install --break-system-packages ansible==$ANSIBE_VERSION

# for Language Setting
cat <<EOF>> /etc/bash.bashrc
set input-meta on
set output-meta on
set convert-meta off
EOF


# Terraform Install
[[ ! $(which terraform) ]] \
    && wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.*

# Setting for ssh
[[ ! $(cat /etc/ssh/ssh_config|grep \^StrictHostKeyChecking) ]] \
    && echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

# Setting for Convenient
echo "export EDITOR=vi" >> /etc/bash.bashrc

## Alias for Terraform Apply
cmd='
terraform destroy -auto-approve
terraform init
terraform apply -auto-approve
cat terraform.tfstate|grep public_ip|grep -v associate
'
echo "alias ta=\"echo '$cmd';$cmd\"">>/etc/bash.bashrc

## Alias for Terraform Destroy
cmd='terraform destroy -auto-approve
'
echo "alias td=\"echo '$cmd';$cmd\"">>/etc/bash.bashrc

## Alias for Delete aws Key pair
cmd='aws ec2 delete-key-pair --key-name mykey
'
echo "alias dk=\"echo '$cmd';$cmd\"">>/etc/bash.bashrc



cat <<EOF>> /etc/bash.bashrc
    alias s1="ssh -t 'vm01' 'sudo su -c  bash'"
    alias s2="ssh -t 'vm02' 'sudo su -c  bash'"
    alias s3="ssh -t 'vm03' 'sudo su -c  bash'"
EOF





# clean up
apt-get clean

. ~/.profile
