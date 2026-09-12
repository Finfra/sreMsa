# doSsh.ps1 — `vagrant ssh` 대신 쓰는 빠른 접속 헬퍼 (Windows PowerShell)
#
#   .\doSsh.ps1              # i1 에 접속
#   .\doSsh.ps1 vm01         # vm01 에 접속
#   .\doSsh.ps1 i1 hostname  # i1 에서 명령 하나만 실행
#
# 왜 필요한가 — `vagrant ssh` 는 명령 하나에 5~10초가 걸린다.
# 실기(Windows 10 · i7-6700T · 16GB)에서 측정한 값이다.
#
#   vagrant --version        1.6s   Ruby 런타임 부팅만
#   vagrant --help          11.3s   + 내장 플러그인·커맨드 전체 로드
#   vagrant status           9.0s   + Vagrantfile 파싱 + VM 상태 조회
#   vagrant ssh i1 -c true   6.8s
#   ssh -F ssh-config i1     0.12s  ← 이 스크립트가 쓰는 경로
#
# VM 도 디스크도 느린 것이 아니다(측정 당시 CPU 17% · RAM 7.7GB 여유).
# Vagrant CLI 가 명령을 하나 처리할 때마다 Ruby 런타임과 내장 플러그인
# 수십 개를 새로 로드하는 구조 때문이며, 사용자가 줄일 수 있는 부분이 아니다.
#
# 그래서 접속 정보를 한 번만 뽑아 두고 그 다음부터는 ssh 를 직접 쓴다.
# `vagrant` 를 부르는 것은 ssh-config 를 만드는 최초 1회뿐이다.
#
# ssh 는 Windows 10 에 기본 탑재된 것을 쓴다(C:\Windows\System32\OpenSSH\ssh.exe).
# 별도 설치가 필요 없으므로 이 실습은 Git for Windows 를 쓰지 않는다.

param(
    [string]$Target = "i1",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Command
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

$cfg = ".vagrant\ssh-config"

# Vagrantfile 이 더 새로우면 포트가 바뀌었을 수 있으므로 다시 뽑는다.
$stale = $true
if (Test-Path $cfg) {
    $stale = (Get-Item "Vagrantfile").LastWriteTime -gt (Get-Item $cfg).LastWriteTime
}

if ($stale) {
    if (-not (Get-Command vagrant -ErrorAction SilentlyContinue)) {
        Write-Host "  vagrant 를 찾을 수 없다. 설치했는지, 설치 후 창을 새로 열었는지 확인할 것" -ForegroundColor Red
        Write-Host "  (설치 직후에는 이미 열려 있던 창에 PATH 가 잡히지 않는다)"
        exit 1
    }
    Write-Host "  ssh-config 생성 중 — vagrant 를 부르므로 이번 한 번만 느리다" -ForegroundColor DarkGray
    New-Item -ItemType Directory -Force -Path ".vagrant" | Out-Null

    $raw = & vagrant ssh-config 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  실패: VM 이 running 인지 확인할 것 (vagrant status)" -ForegroundColor Red
        $raw | ForEach-Object { Write-Host "    $_" }
        exit 1
    }

    # 이 실습의 명령은 전부 ubuntu 기준이다. User 를 ubuntu 로 바꿔 두면
    # 대화형이든 명령 실행이든 언제나 ubuntu 로 붙는다.
    # (common.sh 가 vagrant 의 공개키를 ubuntu 에도 등록해 두었기 때문에 가능하다)
    $raw -replace '^(\s*User\s+).*', '${1}ubuntu' | Set-Content -Path $cfg -Encoding ASCII
}

# 접속 대상이 config 에 없으면 안내한다 (오타·미기동)
$hosts = Select-String -Path $cfg -Pattern '^Host\s+(\S+)' |
         ForEach-Object { $_.Matches[0].Groups[1].Value }
if ($hosts -notcontains $Target) {
    Write-Host "  '$Target' 이 ssh-config 에 없다. 사용 가능한 대상:" -ForegroundColor Red
    $hosts | ForEach-Object { Write-Host "    $_" }
    Write-Host "  VM 을 새로 만들었다면 이 파일을 지우고 다시 실행할 것: del $cfg"
    exit 1
}

if ($Command) { & ssh -F $cfg $Target @Command }
else          { & ssh -F $cfg $Target }
exit $LASTEXITCODE
