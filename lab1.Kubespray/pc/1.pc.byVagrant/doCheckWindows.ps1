# doCheckWindows.ps1 — 2일차 환경을 만들기 전에 Windows 호스트를 점검한다
#
#   .\doCheckWindows.ps1
#
# i1 안에서 도는 doVerify.sh 의 호스트판이다. 그쪽이 "Kubespray 를 20분 돌린 뒤
# 실패하는 것보다 1분 만에 원인을 아는 편이 낫다"는 이유로 있는 것처럼,
# 이쪽은 "vagrant up 을 40분 돌린 뒤 실패하는 것"을 막는다.
#
# ⚠️ 아무것도 고치지 않는다. 보기만 하고 무엇을 해야 하는지 알린다.
#    관리자 권한이 없어도 돌아가며, 못 보는 항목은 [확인불가] 로 넘어간다.
#
# 판정
#   [ OK ]   그대로 진행해도 된다
#   [경고]   진행은 되지만 나중에 증상으로 드러날 수 있다
#   [실패]   이 상태로는 vagrant up 이 성공하지 못한다
#   [확인불가] 권한·환경 때문에 판정하지 못했다. 실패로 세지 않는다

$ErrorActionPreference = "Continue"

# 콘솔이 UTF-8 이 아니면 한글이 깨진다. 바꿀 수 없는 환경도 있으므로 실패해도 넘어간다.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$script:ok = 0; $script:warn = 0; $script:ng = 0
function Pass ($m) { Write-Host "  [ OK ] $m";     $script:ok++ }
function Warn ($m) { Write-Host "  [경고] $m" -ForegroundColor Yellow; $script:warn++ }
function Fail ($m) { Write-Host "  [실패] $m" -ForegroundColor Red;    $script:ng++ }
function Skip ($m) { Write-Host "  [확인불가] $m" -ForegroundColor DarkGray }
function Note ($m) { Write-Host "         $m" -ForegroundColor DarkGray }

Write-Host "=============================================="
Write-Host " sreMsa 2일차 — Windows 호스트 점검"
Write-Host "=============================================="

# ---------------------------------------------------------------- 0. 실행 환경
Write-Host ""
Write-Host "[0] 실행 환경"
try {
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host ("  Windows   : {0} (build {1})" -f $os.Caption, $os.BuildNumber)
} catch { Skip "Windows 버전을 읽지 못했다" }
Write-Host ("  PowerShell: {0}" -f $PSVersionTable.PSVersion)

$isAdmin = $false
try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
                   [Security.Principal.WindowsBuiltInRole]::Administrator)
} catch { }
if ($isAdmin) { Pass "관리자 권한으로 실행 중" }
else {
    Warn "관리자 권한이 아니다 — 일부 항목을 못 본다"
    Note "설정을 바꾸려면 어차피 관리자 PowerShell 이 필요하다"
}

# ---------------------------------------------------------------- 1. 가상화
Write-Host ""
Write-Host "[1] CPU 가상화 (VT-x / AMD-V)"
try {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    Write-Host ("  CPU       : {0}" -f $cpu.Name.Trim())
    Write-Host ("  논리 프로세서: {0}" -f $cpu.NumberOfLogicalProcessors)
    if ($cpu.VirtualizationFirmwareEnabled -eq $true) {
        Pass "펌웨어(BIOS)에서 가상화가 켜져 있다"
    } elseif ($cpu.VirtualizationFirmwareEnabled -eq $false) {
        # 하이퍼바이저가 떠 있으면 이 값이 신뢰할 수 없다. 아래 [2] 가 실제 판정이다.
        Warn "가상화가 꺼진 것으로 보인다 — BIOS/UEFI 에서 VT-x(AMD-V) 를 켤 것"
        Note "하이퍼바이저가 떠 있으면 이 값이 잘못 나오기도 한다. [2] 를 함께 볼 것"
    } else { Skip "가상화 지원 여부를 읽지 못했다" }
    if ($cpu.NumberOfLogicalProcessors -lt 8) {
        Warn ("논리 프로세서가 {0}개다 — VM 이 7개를 가져가므로 느려진다" -f $cpu.NumberOfLogicalProcessors)
    }
} catch { Skip "CPU 정보를 읽지 못했다" }

# ---------------------------------------------------------------- 2. 하이퍼바이저
Write-Host ""
Write-Host "[2] 하이퍼바이저가 떠 있나  ★ 2일차 최대 관문"
Write-Host "     Hyper-V 가 떠 있으면 VirtualBox 는 VM 을 못 띄우거나 10배 느려진다."
$hv = $null
try { $hv = (Get-CimInstance Win32_ComputerSystem).HypervisorPresent } catch { }
if ($hv -eq $false)   { Pass "HypervisorPresent = False — VirtualBox 가 쓸 수 있다" }
elseif ($hv -eq $true) {
    Fail "HypervisorPresent = True — 아직 하이퍼바이저가 올라와 있다"
    Note "관리자 PowerShell: bcdedit /set hypervisorlaunchtype off  후 '다시 시작'"
    Note "그래도 True 면 아래 [3] 이 원인을 알려준다"
} else { Skip "HypervisorPresent 를 읽지 못했다" }

# bcdedit 설정값 자체도 본다. 재부팅 전에는 설정과 실제가 다르다.
try {
    $bcd = (& bcdedit /enum "{current}" 2>$null | Out-String)
    if ($bcd -match 'hypervisorlaunchtype\s+(\w+)') {
        $v = $Matches[1]
        if ($v -ieq 'off') {
            if ($hv -eq $true) { Note "bcdedit 는 이미 Off 다 — 재부팅을 안 했거나 [3] 이 되살리고 있다" }
            else               { Pass "bcdedit hypervisorlaunchtype = Off" }
        } else {
            Fail ("bcdedit hypervisorlaunchtype = {0} — Off 로 바꾸고 재부팅할 것" -f $v)
        }
    } else { Note "bcdedit 에 hypervisorlaunchtype 항목이 없다 (기본값 Auto 로 동작)" }
} catch { Skip "bcdedit 를 읽지 못했다 (관리자 권한 필요)" }

# ---------------------------------------------------------------- 3. VBS
Write-Host ""
Write-Host "[3] Hyper-V 를 되살리는 것들  ★ Windows 11 고유"
Write-Host "     bcdedit off 를 했는데도 [2] 가 True 라면 대개 여기다."
$dgSeen = $false
try {
    $dg = Get-CimInstance -ClassName Win32_DeviceGuard `
              -Namespace "root\Microsoft\Windows\DeviceGuard" -ErrorAction Stop
    $dgSeen = $true
    $running = @($dg.SecurityServicesRunning)
    $vbs = $dg.VirtualizationBasedSecurityStatus

    if ($vbs -eq 2) {
        Fail "VBS(가상화 기반 보안)가 실행 중 — 이것이 하이퍼바이저를 계속 올린다"
    } elseif ($vbs -eq 1) {
        Warn "VBS 가 구성돼 있으나 실행 중은 아니다"
    } else { Pass "VBS 꺼짐" }

    if ($running -contains 2) {
        Fail "메모리 무결성(HVCI)이 켜져 있다"
        Note "Windows 보안 → 장치 보안 → 코어 격리 세부 정보 → 메모리 무결성 끄기 → 재시작"
    } else { Pass "메모리 무결성(HVCI) 꺼짐" }

    if ($running -contains 1) {
        Fail "Credential Guard 가 켜져 있다 — 회사 정책(Intune·그룹 정책)으로 강제된 경우가 많다"
        Note "정책으로 강제된 PC 는 개인이 끌 수 없다. 강사에게 알리고 복구용 USB 로 진행한다"
    } else { Pass "Credential Guard 꺼짐" }
} catch { Skip "DeviceGuard 정보를 읽지 못했다 (관리자 권한 또는 미지원)" }
if (-not $dgSeen -and $hv -eq $true) {
    Note "수동 확인: Windows 보안 → 장치 보안 → 코어 격리 세부 정보"
}

# Windows 기능 — 켜져 있어도 bcdedit off 면 대개 무력화되지만, 원인 추적에 쓴다.
try {
    $feats = @("Microsoft-Hyper-V-All", "VirtualMachinePlatform",
               "HypervisorPlatform", "Containers-DisposableClientVM")
    $on = @()
    foreach ($f in $feats) {
        $s = Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction SilentlyContinue
        if ($s -and $s.State -eq "Enabled") { $on += $f }
    }
    if ($on.Count -eq 0) { Pass "Hyper-V 계열 Windows 기능이 모두 꺼져 있다" }
    else {
        if ($hv -eq $false) { Note ("켜진 기능: {0} — 하이퍼바이저가 안 떴으므로 문제 없다" -f ($on -join ", ")) }
        else {
            Warn ("켜진 기능: {0}" -f ($on -join ", "))
            Note "bcdedit off 로도 안 잡히면 관리자 PowerShell 에서 기능을 끈다:"
            Note "  dism /online /disable-feature /featurename:VirtualMachinePlatform /norestart"
            Note "  ※ 1일차 Docker Desktop·WSL2 를 다시 쓰려면 되돌려야 한다"
        }
    }
} catch { Skip "Windows 기능 상태를 읽지 못했다 (관리자 권한 필요)" }

# ---------------------------------------------------------------- 4. 빠른 시작
Write-Host ""
Write-Host "[4] 빠른 시작 (Fast Startup)"
Write-Host "     켜져 있으면 '종료 후 켜기' 가 진짜 재부팅이 아니라 bcdedit 이 안 먹는다."
try {
    $hb = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" `
              -Name HiberbootEnabled -ErrorAction Stop).HiberbootEnabled
    if ($hb -eq 1) {
        Warn "빠른 시작이 켜져 있다 — 반드시 '다시 시작'(shutdown -r) 으로 재부팅할 것"
        Note "'종료' 후 전원을 켜는 것은 재부팅이 아니다"
    } else { Pass "빠른 시작 꺼짐" }
} catch { Skip "빠른 시작 설정을 읽지 못했다" }

# ---------------------------------------------------------------- 5. 폴더 경로
Write-Host ""
Write-Host "[5] 다운로드 폴더와 실습 소스  ★ OneDrive 가 가로채는 일이 있다"
$dl = $null
try {
    # 실제 Downloads 위치. OneDrive 백업이 켜지면 여기가 OneDrive 안으로 바뀐다.
    $dl = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" `
              -Name "{374DE290-123F-4565-9164-39C4925E467B}" -ErrorAction Stop)."{374DE290-123F-4565-9164-39C4925E467B}"
} catch { }
if (-not $dl) { $dl = Join-Path $env:USERPROFILE "Downloads" }
Write-Host ("  다운로드  : {0}" -f $dl)

$expect = Join-Path $env:USERPROFILE "Downloads"
if ($dl -ne $expect) {
    Warn "다운로드 폴더가 기본 위치가 아니다"
    Note ("문서의 `$env:USERPROFILE\Downloads 는 {0} 를 가리킨다" -f $expect)
    Note "실습 폴더는 위에 표시된 실제 경로에 두거나, 아래 경로로 옮긴다"
}
if ($dl -match 'OneDrive') {
    Fail "다운로드 폴더가 OneDrive 안에 있다 — VM 파일이 동기화돼 PC 가 마비된다"
    Note "OneDrive 설정 → 동기화 및 백업 → 폴더 백업 관리 에서 '다운로드' 를 끈다"
    Note "또는 실습 폴더를 C:\sreMsa 처럼 OneDrive 밖에 두고 거기서 vagrant up 한다"
}

foreach ($n in @("sreMsa", "_prgs")) {
    $p = Join-Path $dl $n
    if (Test-Path $p) { Pass "$n 폴더 있음" } else { Fail "$n 폴더가 없다 — 구글 드라이브에서 복사할 것 ($p)" }
}

# ---------------------------------------------------------------- 6. 경로 안전성
Write-Host ""
Write-Host "[6] 경로에 위험한 글자가 있나"
$here = $PSScriptRoot
Write-Host ("  현재 폴더 : {0}" -f $here)
if ([regex]::IsMatch($here, '[^\x00-\x7F]')) {
    Warn "경로에 한글 등 비ASCII 글자가 있다 — VirtualBox·Vagrant 가 드물게 실패한다"
    Note "막히면 실습 폴더를 C:\sreMsa 로 옮겨 거기서 진행한다"
} else { Pass "경로가 ASCII 만으로 되어 있다" }

# .vagrant\machines\... 가 더 붙으므로 여유를 보고 판정한다.
if ($here.Length -gt 150) {
    Warn ("경로가 {0}자로 길다 — Vagrant 가 만드는 하위 경로가 260자 제한에 걸릴 수 있다" -f $here.Length)
    Note "막히면 C:\sreMsa 처럼 짧은 경로로 옮긴다"
} else { Pass ("경로 길이 {0}자" -f $here.Length) }

# ---------------------------------------------------------------- 7. 자원
Write-Host ""
Write-Host "[7] 메모리·디스크"
try {
    $memGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    if ($memGB -ge 24)     { Pass ("메모리 {0}GB — 여유롭다" -f $memGB) }
    elseif ($memGB -ge 15) { Warn ("메모리 {0}GB — 가능하되 브라우저·IDE 를 닫는 편이 좋다 (VM 합계 9.5GB)" -f $memGB) }
    else                   { Fail ("메모리 {0}GB — VM 4대(9.5GB)를 띄우기 어렵다. 강사에게 알릴 것" -f $memGB) }
} catch { Skip "메모리 용량을 읽지 못했다" }
try {
    $drive = (Get-Item $here).PSDrive.Name
    $free  = [math]::Round((Get-PSDrive $drive).Free / 1GB, 1)
    if ($free -ge 60) { Pass ("{0}: 여유 {1}GB" -f $drive, $free) }
    else              { Fail ("{0}: 여유 {1}GB — 60GB 이상 필요하다" -f $drive, $free) }
} catch { Skip "디스크 여유를 읽지 못했다" }

# ---------------------------------------------------------------- 8. 프로그램
Write-Host ""
Write-Host "[8] 프로그램 설치"
$vbm = (Get-Command VBoxManage -ErrorAction SilentlyContinue).Source
if (-not $vbm) {
    $guess = Join-Path ${env:ProgramFiles} "Oracle\VirtualBox\VBoxManage.exe"
    if (Test-Path $guess) { $vbm = $guess; Note "VBoxManage 가 PATH 에 없다 — 설치 후 창을 새로 열면 잡힌다" }
}
if ($vbm) {
    try { Pass ("VirtualBox {0}" -f ((& $vbm --version 2>$null) -join "").Trim()) }
    catch { Warn "VBoxManage 는 있으나 실행되지 않는다" }
} else {
    Fail "VirtualBox 가 없다 — _prgs\Day2 에서 vc_redist 를 먼저, 그다음 VirtualBox 를 설치할 것"
}

if (Get-Command vagrant -ErrorAction SilentlyContinue) {
    try { Pass ("Vagrant {0}" -f ((& vagrant --version 2>$null) -join "").Trim()) }
    catch { Warn "vagrant 가 있으나 실행되지 않는다" }
    # box 등록 확인. vagrant 는 느리므로 파일로 먼저 본다.
    $boxDir = Join-Path $env:USERPROFILE ".vagrant.d\boxes"
    if (Test-Path (Join-Path $boxDir "bento-VAGRANTSLASH-ubuntu-24.04")) {
        Pass "box bento/ubuntu-24.04 등록됨"
    } else {
        Fail "box 가 등록되지 않았다 — 이대로 vagrant up 하면 인터넷에서 621MB 를 받는다"
        Note "cd `$env:USERPROFILE\Downloads\_prgs\Day2"
        Note "vagrant box add bento/ubuntu-24.04 ./bento-ubuntu-24.04-202510.26.0-virtualbox-amd64.box"
    }
} else {
    Fail "Vagrant 가 없다 — _prgs\Day2\vagrant_2.4.9_windows_amd64.msi 를 설치할 것"
}

# ---------------------------------------------------------------- 9. 실행 정책·차단
Write-Host ""
Write-Host "[9] PowerShell 실행 정책과 차단된 파일"
try {
    $pol = Get-ExecutionPolicy
    if ($pol -in @("Bypass", "Unrestricted", "RemoteSigned")) { Pass ("실행 정책 {0}" -f $pol) }
    else {
        Warn ("실행 정책이 {0} 라 .ps1 실행이 막힌다" -f $pol)
        Note "그 창에서만 한 번 허용: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass"
    }
} catch { Skip "실행 정책을 읽지 못했다" }

# 구글 드라이브·인터넷에서 받은 파일에는 Zone.Identifier 가 붙어 SmartScreen 이 막는다.
try {
    $blocked = @(Get-ChildItem -Path $here -Filter *.ps1 -ErrorAction SilentlyContinue | Where-Object {
        Get-Item $_.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue
    })
    if ($blocked.Count -gt 0) {
        Warn ("차단 표시가 붙은 스크립트 {0}개 — 인터넷에서 받은 파일로 취급된다" -f $blocked.Count)
        Note ("해제: Get-ChildItem '{0}' -Recurse | Unblock-File" -f $here)
    } else { Pass "이 폴더의 스크립트에 차단 표시가 없다" }
} catch { Skip "파일 차단 여부를 확인하지 못했다" }

# ---------------------------------------------------------------- 10. hosts
Write-Host ""
Write-Host "[10] hosts 파일 (3장에서 등록한다)"
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
try {
    $txt = Get-Content $hostsPath -ErrorAction Stop
    $need = @("i1", "vm01", "vm02", "vm03")
    $have = @($need | Where-Object { $txt -match ("\s{0}\s*$" -f $_) })
    if ($have.Count -eq $need.Count) { Pass "i1·vm01~vm03 이 모두 등록돼 있다" }
    elseif ($have.Count -eq 0)       { Note "아직 등록 전이다 — 2장(vagrant up) 뒤 3장에서 한다" }
    else                             { Warn ("일부만 등록돼 있다: {0}" -f ($have -join ", ")) }
} catch { Skip "hosts 파일을 읽지 못했다" }

# ---------------------------------------------------------------- 11. 실행 엔진
Write-Host ""
Write-Host "[11] VirtualBox 실행 엔진 (VM 을 한 번이라도 띄운 뒤에 의미가 있다)"
Write-Host "     Hyper-V 와 겹치면 VirtualBox 7 은 실패하지 않고 NEM 으로 폴백해 10배 느려진다."
Write-Host "     이 항목만은 '지금' 이 아니라 '마지막으로 VM 을 띄웠을 때' 를 본다."
$logs = @()
try {
    $vmRoot = Join-Path $env:USERPROFILE "VirtualBox VMs"
    if (Test-Path $vmRoot) {
        $logs = @(Get-ChildItem $vmRoot -Recurse -Filter VBox.log -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 1)
    }
} catch { }
if ($logs.Count -eq 0) { Note "아직 VM 로그가 없다 — vagrant up 을 한 뒤 다시 확인한다" }
else {
    try {
        $log    = $logs[0]
        $vmName = $log.Directory.Parent.Name
        Write-Host ("  로그      : {0}  ({1:yyyy-MM-dd HH:mm})" -f $vmName, $log.LastWriteTime)

        # 이번 부팅보다 오래된 로그는 '[2][3] 을 고치기 전' 의 기록이다.
        # 그때 NEM 으로 돌았다는 사실은 지금 상태에 대해 아무것도 말해 주지 않는다.
        $stale = $false
        try {
            $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
            if ($log.LastWriteTime -lt $boot) { $stale = $true }
        } catch { }

        $txt = Get-Content $log.FullName -Raw -ErrorAction Stop

        # ⚠️ 'NEM' 이라는 글자를 그냥 찾으면 안 된다 (2026.09.15 실제 오진).
        #    PowerShell 의 -match 는 대소문자를 안 가리므로 정상 로그의
        #      Mnemonic - Description  ...  [/NEM/] (level 1)
        #      UseNEMInstead <integer> = 0 (0)      ← NEM 을 '안 쓴다' 는 줄
        #    이 전부 걸린다. VT-x 로 잘 돈 로그가 [실패] 로 읽혔다.
        #    그래서 엔진 번호와 HM 초기화 줄로 가른다. 대소문자도 -cmatch 로 가린다.
        #      Using execution engine 1  → 하드웨어 가상화(VT-x/AMD-V)
        #      Using execution engine 2  → NEM (Hyper-V 동거 · 10배 느림)
        $engine = ''
        $m = [regex]::Match($txt, 'Using execution engine (\d+)')
        if ($m.Success) { $engine = $m.Groups[1].Value }

        $hmUsed  = $txt -cmatch 'HM: Using (VT-x|AMD-V)'
        $nemUsed = ($txt -cmatch 'fall back to NEM|NEM: Using|Snail execution mode') -or
                   ($txt -cmatch 'UseNEMInstead\s+<integer>\s+=\s+0x0*[1-9]')

        if ($hmUsed -and -not $nemUsed) {
            Pass ("VT-x 네이티브로 돌았다 (정상 · execution engine {0})" -f $engine)
        }
        elseif ($nemUsed -or $engine -eq '2') {
            if ($stale) {
                Warn ("{0} 가 NEM 으로 돌았지만 그것은 이번 부팅 전 기록이다" -f $vmName)
                Note "지금 [2][3] 이 모두 OK 라면 이미 고쳐진 것이다 — vagrant destroy -f 후 다시 띄우면 이 항목도 바뀐다"
            } else {
                Fail ("{0} 가 NEM(Hyper-V 동거) 으로 돌았다 — 이것이 '부팅 타임아웃' 의 진짜 원인이다" -f $vmName)
                Note "[2][3] 을 다시 잡고 재부팅한 뒤 vagrant destroy -f && vagrant up"
            }
        }
        elseif ($engine -eq '1') { Pass "하드웨어 가상화로 돌았다 (정상 · execution engine 1)" }
        else {
            Note "실행 엔진을 판정하지 못했다 — 아래로 직접 본다"
            Note ("Select-String -Path '{0}' -Pattern 'Using execution engine|HM: Using'" -f $log.FullName)
        }
    } catch { Skip "VBox.log 를 읽지 못했다" }
}

# ---------------------------------------------------------------- 결과
Write-Host ""
Write-Host "=============================================="
Write-Host (" 결과 : OK {0} · 경고 {1} · 실패 {2}" -f $script:ok, $script:warn, $script:ng)
Write-Host "=============================================="
if ($script:ng -gt 0) {
    Write-Host " [실패] 를 먼저 해결한다. 이 상태로 vagrant up 하면 시간만 버린다." -ForegroundColor Red
    exit 1
}
if ($script:warn -gt 0) {
    Write-Host " 진행해도 되지만 [경고] 가 나중에 증상으로 돌아올 수 있다." -ForegroundColor Yellow
}
exit 0
