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
#   ssh -F ssh-config i1     0.12s  ← 이 스크립트가 쓰는 접속 경로
#   VBoxManage showvminfo    0.08s  ← 이 스크립트가 쓰는 상태 확인 경로
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
#
# ⚠️ VM 이 꺼져 있을 때 멈추지 않는 것이 이 스크립트의 조건이다.
#    예전 판은 VM 4대가 poweroff 인 상태에서 실행하면 화면에 아무것도 내지 않은 채
#    멈췄고 Ctrl+C 도 잘 듣지 않았다. 실기에서 겪은 문제다.
#    막는 곳이 세 군데다. 앞의 것이 뚫려도 뒤가 받는다.
#      ① VirtualBox 에 상태를 먼저 묻는다      — 꺼져 있으면 0.08초 만에 안내하고 끝낸다
#      ② vagrant 호출에 시간 상한과 빈 stdin   — Ruby 가 입력을 기다리며 멈추는 것을 막는다
#      ③ ssh 에 ConnectTimeout                 — 응답 없는 상대를 무한히 기다리지 않는다

param(
    [string]$Target = "i1",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Command
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

$cfg = ".vagrant\ssh-config"

# ---------------------------------------------------------------------------
# 외부 명령을 부르는 두 가지 도구
# ---------------------------------------------------------------------------

# Windows PowerShell 5.1 은 $ErrorActionPreference = "Stop" 인 상태에서 외부 명령의
# stderr 를 파이프라인으로 받으면(2>&1) 그 줄을 예외로 바꿔 스크립트를 그 자리에서
# 끝낸다. 그러면 아래에 준비해 둔 안내문에 도달하지 못하고 빨간 글씨만 남는다.
# 외부 명령은 전부 이 함수로 부른다.
function Invoke-Capture {
    param([string]$Exe, [string[]]$Arguments)
    $keep = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out  = & $Exe @Arguments 2>&1
        return @{ Output = $out; Code = $LASTEXITCODE }
    } finally { $ErrorActionPreference = $keep }
}

# vagrant 는 stdin 이 콘솔에 붙어 있으면 입력을 기다리며 멈출 수 있다.
# bash 판(doSsh.sh)에서 먼저 겪어 `< /dev/null` 로 막아 둔 것과 같은 문제다.
# PowerShell 에는 입력 리다이렉션 문법이 없으므로 Start-Process 로 빈 파일을 물린다.
# 읽는 즉시 EOF 라 기다릴 수가 없다. 시간 상한도 같이 건다.
function Invoke-VagrantSshConfig {
    param([int]$TimeoutSec = 60)

    $stdin = New-TemporaryFile   # 빈 파일 = 읽는 즉시 EOF
    $so    = New-TemporaryFile
    $se    = New-TemporaryFile
    try {
        $p = Start-Process -FilePath "vagrant" -ArgumentList "ssh-config" `
                           -NoNewWindow -PassThru `
                           -RedirectStandardInput  $stdin.FullName `
                           -RedirectStandardOutput $so.FullName `
                           -RedirectStandardError  $se.FullName
        if (-not $p.WaitForExit($TimeoutSec * 1000)) {
            try { $p.Kill() } catch { }
            return @{ Code = 124
                      Output = @("vagrant 가 $TimeoutSec 초 안에 끝나지 않아 중단했다.",
                                 "VirtualBox 가 응답하지 않는 상태일 수 있다. PC 를 다시 시작해 본다.") }
        }
        # 나온 내용으로 판정한다. Start-Process 로 띄운 프로세스는 ExitCode 를
        # 못 읽는 경우가 드물게 있어, 그 값만 믿으면 멀쩡한 결과를 버리게 된다.
        $out = @(Get-Content $so.FullName)
        if ($out.Count -gt 0) { return @{ Code = 0; Output = $out } }

        $err = @(Get-Content $se.FullName)
        if ($err.Count -eq 0) { $err = @("vagrant 가 아무 출력도 내지 않았다 (exit=$($p.ExitCode))") }
        return @{ Code = 1; Output = $err }
    } finally {
        Remove-Item $stdin.FullName, $so.FullName, $se.FullName -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# 1. 대상 VM 이 켜져 있는지 먼저 본다 (0.08초)
#
# 꺼진 VM 을 상대로는 그 뒤의 어떤 단계도 성공할 수 없다. 여기서 끊으면
# `vagrant status`(9초)를 칠 필요도, ssh 가 멈추는 것을 볼 일도 없다.
# VirtualBox 가 없거나 VM 이름을 못 찾으면 이 확인을 건너뛴다 — 확인은 편의 장치이지
# 관문이 아니며, 뚫려도 아래 ②③ 이 받는다.
# ---------------------------------------------------------------------------
$vmName = "sreMsa-$Target"   # Vagrantfile 의 vb.name 규약 (i1 -> sreMsa-i1)

$vbm = (Get-Command VBoxManage -ErrorAction SilentlyContinue).Source
if (-not $vbm) {
    # VirtualBox 설치 프로그램이 PATH 를 건드리지 않는 경우가 많다.
    $guess = Join-Path ${env:ProgramFiles} "Oracle\VirtualBox\VBoxManage.exe"
    if (Test-Path $guess) { $vbm = $guess }
}

if ($vbm) {
    $r = Invoke-Capture $vbm @("showvminfo", $vmName, "--machinereadable")
    if ($r.Code -ne 0) {
        Write-Host "  '$vmName' 을 VirtualBox 에서 찾을 수 없다. 아직 만들지 않았을 수 있다:" -ForegroundColor Red
        Write-Host "    vagrant up $Target"
        exit 1
    }
    $m = $r.Output | Select-String '^VMState="(.*)"' | Select-Object -First 1
    if ($m) {
        $state = $m.Matches[0].Groups[1].Value
        if ($state -ne "running") {
            Write-Host "  '$Target' 이 켜져 있지 않다 (지금: $state). 먼저 켠다:" -ForegroundColor Red
            Write-Host "    vagrant up $Target"
            Write-Host "  네 대를 다 켜려면 이름 없이: vagrant up"
            exit 1
        }
    }
}

# ---------------------------------------------------------------------------
# 2. 접속 정보(ssh-config) 준비
#
# Vagrantfile 이 더 새로우면 포트가 바뀌었을 수 있으므로 다시 뽑는다.
# ---------------------------------------------------------------------------
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

    $r = Invoke-VagrantSshConfig -TimeoutSec 60
    if ($r.Code -ne 0) {
        Write-Host "  ssh-config 를 뽑지 못했다. VM 이 running 인지 확인할 것 (vagrant status)" -ForegroundColor Red
        $r.Output | ForEach-Object { Write-Host "    $_" }
        exit 1
    }

    # 이 실습의 명령은 전부 ubuntu 기준이다. User 를 ubuntu 로 바꿔 두면
    # 대화형이든 명령 실행이든 언제나 ubuntu 로 붙는다.
    # (common.sh 가 vagrant 의 공개키를 ubuntu 에도 등록해 두었기 때문에 가능하다)
    $r.Output -replace '^(\s*User\s+).*', '${1}ubuntu' | Set-Content -Path $cfg -Encoding ASCII
}

# 접속 대상이 config 에 없으면 안내한다 (오타·미기동)
$hosts = @(Select-String -Path $cfg -Pattern '^Host\s+(\S+)' |
           ForEach-Object { $_.Matches[0].Groups[1].Value })
if ($hosts -notcontains $Target) {
    Write-Host "  '$Target' 이 ssh-config 에 없다. 사용 가능한 대상:" -ForegroundColor Red
    $hosts | ForEach-Object { Write-Host "    $_" }
    Write-Host "  VM 을 새로 만들었다면 이 파일을 지우고 다시 실행할 것: del $cfg"
    exit 1
}

# ---------------------------------------------------------------------------
# 3. 접속
#
# ConnectTimeout 을 준다. 상대가 응답하지 않으면 ssh 는 기본적으로 무한히 기다린다
# (실측: 응답 없는 192.168.56.10 에 붙이면 40초가 지나도 끝나지 않는다).
# 10초면 충분하고, 끊긴 뒤에 무엇을 해야 하는지 바로 안내할 수 있다.
# ---------------------------------------------------------------------------
$sshArgs = @("-F", $cfg, "-o", "ConnectTimeout=10", $Target)
if ($Command) { $sshArgs += $Command }

& ssh @sshArgs
$code = $LASTEXITCODE

# 255 는 ssh 가 붙지 못했다는 뜻이다(원격에서 돌린 명령이 실패한 것과 구분된다).
if ($code -eq 255) {
    Write-Host ""
    Write-Host "  '$Target' 에 접속하지 못했다. VM 이 방금 꺼졌거나 포트가 바뀌었을 수 있다:" -ForegroundColor Red
    Write-Host "    vagrant up $Target"
    Write-Host "  VM 을 다시 만들었다면 접속 정보를 새로 뽑는다: del $cfg"
}
exit $code
