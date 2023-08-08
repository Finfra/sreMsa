#!/bin/bash

# Version Setting
TERRAFORM_VERSION="1.5.4"

# System Variable Setting
export LC_ALL=C.UTF-8
export DEBIAN_FRONTEND=noninteractive

echo "export LC_ALL=C.UTF-8">>/etc/bash.bashrc
echo "export DEBIAN_FRONTEND=noninteractive">>/etc/bash.bashrc

hostname i1
hostname > /etc/hostname



apt -y update
sudo apt update



apt -y install docker.io unzip mysql-client jq
usermod -G docker ubuntu


# install pip
add-apt-repository ppa:deadsnakes/ppa
apt -y install  python3.10
apt -y install python3.10-distutils
wget https://bootstrap.pypa.io/get-pip.py
python3.10 get-pip.py

python3.10 -m pip install --user --upgrade pip

[[ -f /usr/bin/python ]]&&rm /usr/bin/python
ln -s /usr/bin/python3.10 /usr/bin/python
[[ -f /usr/bin/pip ]]&&rm /usr/bin/pip
ln -s /usr/local/bin/pip3.10 /usr/bin/pip
[[ -f /usr/bin/pip3 ]]&&rm /usr/bin/pip3
ln -s /usr/local/bin/pip3.10 /usr/bin/pip3



# install awscli and ebcli
pip uninstall -y botocore
pip install botocore==1.29.99
python3.10 -m pip install  awscli
#python3.10 -m pip install  awsebcli
complete -C aws_completer aws

# install ansible
sudo pip3.10 install netaddr jinja2
sudo pip3.10 install ansible==7.6.0

# for Language Setting
cat <<EOF>> /etc/bash.bashrc
set input-meta on
set output-meta on
set convert-meta off
EOF



# install terraform
T_VERSION=$(/usr/local/bin/terraform -v | head -1 | cut -d ' ' -f 2 | tail -c +2)
T_RETVAL=${PIPESTATUS[0]}

[[ $T_VERSION != $TERRAFORM_VERSION ]] || [[ $T_RETVAL != 0 ]] \
    && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.*                                                                   \
    && wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.*


# Setting for ssh
x=$(cat /etc/ssh/ssh_config|grep \^StrictHostKeyChecking)
if [ ${#x} -eq 0 ] ;then
    echo "StrictHostKeyChecking no">>/etc/ssh/ssh_config
fi

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
