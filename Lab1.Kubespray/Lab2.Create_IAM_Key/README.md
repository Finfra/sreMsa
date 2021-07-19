# Step1. Aws 계정 생성
* https://aws.amazon.com/free 에 접속하여 계정을 생성합니다.
  - 단, 이미 계정을 제공 받았을 경우 제공 받은 계정을 사용합니다.

# Step2. IAM Secret Key 생성
1. IAM서비스(https://console.aws.amazon.com/iam)에 접속합니다.
2. 죄측의 Users메뉴를 선택하여 https://console.aws.amazon.com/iamv2/home#/users 에 접근합니다.
3. 우측 상단의 "Add users" 버튼을 큭릭하여 유저를 생성합니다.
4. "User name" 항목에 "terraform"이라고 입력합니다.(유저명은 어떤 것을 선택하던 상관 없습니다.)
5. 생성된 "terraform"유저를 선택 하여 Summary화면으로 들어 옵니다.
6. "Add permissions"버튼 클릭합니다.
7. "Attach existing policies directly"를 클릭합니다.
8. "AdministratorAccess"권한과 "PowerUserAccess" 권한을 검색하여 추가해 줍니다.
9. "Summary"화면에서 "Security credentials" 탭을 클릭합니다.
10. "Create access key"를 클릭하여 Security키와 Access키를 생성하고 "Download.csv file" 메뉴를 클릭하여 Security 키를 잘 저장해 둡니다. (향후 사용함. "Secret access key"의 "show"링크를 눌러서 나오는 Secret key도 같은 것 이지만 2중으로 저장해 둘 것)
