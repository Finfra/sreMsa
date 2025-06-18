#!/bin/bash

# Version Setting
TERRAFORM_VERSION="1.8.3"
ANSIBE_VERSION="9.13.0"           # 9.13.0

# System Variable Setting
export LC_ALL=C.UTF-8
export DEBIAN_FRONTEND=noninteractive

grep -qxF "export LC_ALL=C.UTF-8" /etc/bash.bashrc || echo "export LC_ALL=C.UTF-8" >> /etc/bash.bashrc
grep -qxF "export DEBIAN_FRONTEND=noninteractive" /etc/bash.bashrc || echo "export DEBIAN_FRONTEND=noninteractive" >> /etc/bash.bashrc

hostname i1
hostname > /etc/hostname

apt update
apt -y install unzip curl jq git wget vim locales software-properties-common lsb-release

locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# install python3.12 + pip
add-apt-repository ppa:deadsnakes/ppa -y
apt update
apt install -y python3-pip python3.12-venv python3.12-dev 

[[ -f /usr/bin/python ]] && rm /usr/bin/python
ln -s /usr/bin/python3.12 /usr/bin/python


# install awscli
python3.12 -m pip install --break-system-packages awscli
complete -C aws_completer aws

# install ansible
pip install --break-system-packages netaddr jinja2
pip install --break-system-packages ansible==$ANSIBE_VERSION

# Language Setting
grep -qxF "set input-meta on" /etc/bash.bashrc || cat <<EOF >> /etc/bash.bashrc
set input-meta on
set output-meta on
set convert-meta off
EOF

# Terraform Install
[[ ! $(which terraform) ]] \
    && wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.*

# 편의 설정
grep -qxF "export EDITOR=vi" /etc/bash.bashrc || echo "export EDITOR=vi" >> /etc/bash.bashrc

# Terraform Apply alias
cmd='
terraform destroy -auto-approve
terraform init
terraform apply -auto-approve
cat terraform.tfstate|grep public_ip|grep -v associate
'
grep -q "^alias ta=" /etc/bash.bashrc || echo "alias ta=\"echo '$cmd';$cmd\"" >> /etc/bash.bashrc

# Terraform Destroy alias
cmd='terraform destroy -auto-approve
'
grep -q "^alias td=" /etc/bash.bashrc || echo "alias td=\"echo '$cmd';$cmd\"" >> /etc/bash.bashrc

# Delete AWS Key Pair
cmd='aws ec2 delete-key-pair --key-name mykey
'
grep -q "^alias dk=" /etc/bash.bashrc || echo "alias dk=\"echo '$cmd';$cmd\"" >> /etc/bash.bashrc

# SSH alias 예시
cat <<EOF >> /etc/bash.bashrc
alias s1="ssh -t 'vm01' 'sudo su -c bash'"
alias s2="ssh -t 'vm02' 'sudo su -c bash'"
alias s3="ssh -t 'vm03' 'sudo su -c bash'"
EOF

# SSH StrictHostKeyChecking 끄기
grep -q "^StrictHostKeyChecking" /etc/ssh/ssh_config || echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

# Clean
apt-get clean

. ~/.bashrc
