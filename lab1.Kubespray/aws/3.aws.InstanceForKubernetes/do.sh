#!/bin/bash
#hostname
apt -y update
apt -y install docker.io ansible unzip

usermod -G docker 


# install pip
apt -y install  python3.8
apt -y install python3.8-distutils
wget https://bootstrap.pypa.io/get-pip.py
python3.8 get-pip.py

python3.8 -m pip install --user --upgrade pip

# install awscli and ebcli
python3.8 -m pip install  awscli
python3.8 -m pip install  awsebcli

[[ -f /usr/bin/python ]]&&rm /usr/bin/python
ln -s /usr/bin/python3.8 /usr/bin/python
[[ -f /usr/bin/pip ]]&&rm /usr/bin/pip
ln -s /usr/local/bin/pip3.8 /usr/bin/pip
[[ -f /usr/bin/pip3 ]]&&rm /usr/bin/pip3
ln -s /usr/local/bin/pip3.8 /usr/bin/pip3

echo -e "sdhci\n" | sudo tee -a /etc/modprobe.d/blacklist.conf
