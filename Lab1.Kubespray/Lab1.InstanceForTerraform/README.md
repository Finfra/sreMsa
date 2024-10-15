# Step1. AWS Instance를 생성합니다.
* 단, 이미 인스턴스를 제공 받았을 경우 제공 받은 인스턴스를 사용하고 이하 모든 Step을 생략 합니다.
* host명은 i1으로 합니다.
* Zone은 상관없으며, Ubuntu 18.04이상 OS와 인스턴스 타입 t2.micro에서도 작동합니다. 단, 권장사항은 Ubuntu 24.04이며 인스턴스 타입이 t2.small 이며, Main Disk도 40G 입니다.
* Security Group Setting
  - Inbound : 22, 9411,8081

# Step2. Repoitory Update
* 필수 아님 : 단, http://mirrors.kernel.org/ubuntu/ 상태 이상할때(apt install명령이 잘 않될때)만 실행
```
REPO_LINE="deb http://mirror.kakao.com/ubuntu/ noble main universe"
if ! grep -Fxq "$REPO_LINE" /etc/apt/sources.list; then
  echo "$REPO_LINE" | sudo tee -a /etc/apt/sources.list
  echo "Repository line added successfully."
else
  echo "Repository line already exists."
fi
sudo apt-get update
```

# Step3. Install Terraform And Ansible
* 아래 스크립트를 실행합니다. (한줄씩 복붙)
```
sudo -i
curl https://raw.githubusercontent.com/Finfra/sreMsa/main/Lab1.Kubespray/Lab1.InstanceForTerraform/installOnEc2.sh|bash
```

# Step4. 설치 확인
```
terraform -version
ansible --version
```

