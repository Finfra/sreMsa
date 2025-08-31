#!/bin/bash
# Python 버전 기반 통합 DevOps 설치 스크립트
# 현재 설치된 Python 버전에 따라 자동 분기

# Version Setting
TERRAFORM_VERSION="1.13.1"
ANSIBLE_VERSION="10.7.0"

# Python 버전 확인 함수
check_python_version() {
    if command -v python3.12 &> /dev/null; then
        PYTHON_VERSION=$(python3.12 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
        PYTHON_CMD="python3.12"
        echo "3.12"
    elif command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
        PYTHON_CMD="python3"
        echo "$PYTHON_VERSION"
    else
        echo "0"
    fi
}

DETECTED_PYTHON=$(check_python_version)
echo "=== 현재 Python 버전: $DETECTED_PYTHON ==="

# System Variable Setting
export LC_ALL=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
grep -qxF "export LC_ALL=C.UTF-8" /etc/bash.bashrc || echo "export LC_ALL=C.UTF-8" >> /etc/bash.bashrc
grep -qxF "export DEBIAN_FRONTEND=noninteractive" /etc/bash.bashrc || echo "export DEBIAN_FRONTEND=noninteractive" >> /etc/bash.bashrc

# Hostname 설정
hostname i1
hostname > /etc/hostname

# 기본 패키지 설치
apt update
apt -y install unzip curl jq git wget vim locales software-properties-common lsb-release

# Locale 설정
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Python 버전별 설치 분기
if [[ "$DETECTED_PYTHON" == "3.12" ]]; then
    echo "=== Python 3.12 감지 - 기존 설치 활용 ==="
    
    # pip 및 개발 패키지만 추가 설치
    apt install -y python3-pip python3.12-venv python3.12-dev 2>/dev/null || true
    
    # Python 심볼릭 링크 설정
    [[ -f /usr/bin/python ]] && rm /usr/bin/python
    ln -s /usr/bin/python3.12 /usr/bin/python
    
    # AWS CLI 설치 (break-system-packages 옵션 사용)
    python3.12 -m pip install --break-system-packages awscli
    
    # Ansible 설치
    pip install --break-system-packages netaddr jinja2
    pip install --break-system-packages ansible==$ANSIBLE_VERSION
    
elif [[ "$DETECTED_PYTHON" > "3.10" && "$DETECTED_PYTHON" < "3.12" ]]; then
    echo "=== Python $DETECTED_PYTHON 감지 - 기존 버전 활용 ==="
    
    # 기존 Python 사용, pip만 확인/설치
    apt install -y python3-pip 2>/dev/null || {
        curl -sS https://bootstrap.pypa.io/get-pip.py | $PYTHON_CMD
    }
    
    # Python 심볼릭 링크 설정
    [[ -f /usr/bin/python ]] && rm /usr/bin/python
    ln -s $(which $PYTHON_CMD) /usr/bin/python
    
    # AWS CLI 설치
    python -m pip install awscli
    
    # Ansible 설치
    pip install netaddr jinja2
    pip install ansible==$ANSIBLE_VERSION
    
    # OpenSSL 충돌 해결
    pip uninstall -y pyOpenSSL 2>/dev/null || true
    
else
    echo "=== Python 3.12 새로 설치 ==="
    
    # Python 3.12 설치 (3.11 대신 3.12로 변경)
    add-apt-repository ppa:deadsnakes/ppa -y
    apt update
    apt install -y python3.12 python3-pip python3.12-venv python3.12-dev
    
    # Python 심볼릭 링크 설정
    [[ -f /usr/bin/python ]] && rm /usr/bin/python
    ln -s /usr/bin/python3.12 /usr/bin/python
    
    # AWS CLI 설치
    python3.12 -m pip install --break-system-packages awscli
    
    # Ansible 설치
    pip install --break-system-packages netaddr jinja2
    pip install --break-system-packages ansible==$ANSIBLE_VERSION
fi

# AWS CLI 자동완성 설정
complete -C aws_completer aws

# Language Setting
grep -qxF "set input-meta on" /etc/bash.bashrc || cat <<EOF >> /etc/bash.bashrc
set input-meta on
set output-meta on
set convert-meta off
EOF

# Terraform 설치
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

# Delete AWS Key Pair alias
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

echo "=== 설치 완료 ==="
echo "최종 Python 버전: $(python --version)"
echo "Terraform 버전: $(terraform version | head -1)"
echo "Ansible 버전: $(ansible --version | head -1)"
echo "AWS CLI 버전: $(aws --version)"

# bashrc 적용
. ~/.bashrc