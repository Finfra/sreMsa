# Step1. AWS Instance를 생성합니다.
* 단, 이미 인스턴스를 제공 받았을 경우 제공 받은 인스턴스를 사용하고 이하 모든 Step을 생략 합니다.
* Zone은 상관없습니다.

| 항목              | 권장값               | 최소         |
| :---------------- | :------------------- | :----------- |
| OS                | Ubuntu 24.04         | Ubuntu 22.04 |
| 인스턴스 타입     | t3.small             | t3.micro     |
| 루트 디스크       | 40 GB                | —            |
| 호스트명          | **`i1`**             | —            |
| 보안 그룹 Inbound | **22 · 9411 · 8081** | —            |

* 9411 은 lab5 의 Zipkin, 8081 은 실습용 웹이 씁니다. 나중에 막히지 않도록 지금 함께 열어 둡니다.

# Step2. Repoitory Update
* 필수 아님 : 단, http://mirrors.kernel.org/ubuntu/ 상태 이상할때(apt install명령이 잘 안될때) 실행
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
* 아래 스크립트를 실행합니다.
* Python 버전을 자동 감지하여 설치합니다 (3.10~3.12 지원, 없을 경우 3.12 설치)
```
sudo -i bash -c 'curl https://raw.githubusercontent.com/Finfra/sreMsa/main/lab1.Kubespray/aws/1.aws.byTerraform/installOnEc2.sh | bash'
```

# Step4. 설치 확인
```
terraform -version
ansible --version
python --version
aws --version
```

