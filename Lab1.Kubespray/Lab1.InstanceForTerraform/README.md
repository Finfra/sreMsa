# Step1. AWS Instance를 생성합니다.
* 단, 이미 인스턴스를 제공 받았을 경우 제공 받은 인스턴스를 사용하고 이하 모든 Step을 생략 합니다.
* Zone은 상관없으며, Ubuntu 18.04이상 OS와 인스턴스 타입 t2.micro에서도 작동합니다. 단, 권장사항은 Ubuntu 20.04이며 인스턴스 타입이 t2.small 이며, Main Disk도 40G 입니다.

# Step2. Install Terraform And Ansible
* 아래 스크립트를 실행합니다.
```
curl https://raw.githubusercontent.com/Finfra/sreMsa/main/Lab1.Kubespray/Lab1.InstanceForTerraform/installOnEc2.sh|bash
```

# Step3. 설치 확인
```
terraform -version 
ansible --version
```
