<#
.SYNOPSIS
    wezterm-kit 验收：逐项检查装机结果，失败项直接报出来。
.DESCRIPTION
    装完 install.ps1 后跑这个。任何一项 [FAIL] 都能定位到是哪一步出问题。
    退出码 0 = 全部通过，1 = 有失败项。
.EXAMPLE
    powershell -File .\verify.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$script:pass = 0
$script:fail = 0

function Check {
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    if ($Ok) {
        $script:pass++
        Write-Host "  [OK]   $Name" -ForegroundColor Green
    } else {
        $script:fail++
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
    if ($Detail) { Write-Host "         $Detail" -ForegroundColor DarkGray }
}

# 刚装完的程序可能还没进 PATH，补几个常见落点
function Find-Exe {
    param([string]$Name, [string[]]$Fallback)
    $c = Get-Command $Name -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in $Fallback) {
        if ($p -and (Test-Path -LiteralPath $p)) { return $p }
    }
    return $null
}

$WezCfg = Join-Path $HOME '.wezterm.lua'
$NuDir  = Join-Path $env:APPDATA 'nushell'
$NuCfg  = Join-Path $NuDir 'config.nu'
$NuEnv  = Join-Path $NuDir 'env.nu'
$SsCfg  = Join-Path $HOME '.config\starship.toml'

Write-Host ''
Write-Host '=== wezterm-kit 验收 ===' -ForegroundColor Magenta
Write-Host ''

# ---------- 1. 可执行文件 ----------
Write-Host '[ 软件 ]' -ForegroundColor Cyan

$wezterm = Find-Exe 'wezterm' @(
    (Join-Path $env:ProgramFiles 'WezTerm\wezterm.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\WezTerm\wezterm.exe')
)
Check 'WezTerm 已安装' ([bool]$wezterm) $(if ($wezterm) { $wezterm } else { 'PATH 里没找到，也没在常见安装目录' })

$nu = Find-Exe 'nu' @((Join-Path $env:LOCALAPPDATA 'Programs\nu\bin\nu.exe'))
Check 'Nushell 已安装' ([bool]$nu) $(if ($nu) { $nu } else { 'PATH 里没找到，也没在常见安装目录' })

$starship = Find-Exe 'starship' @(
    (Join-Path $env:ProgramFiles 'starship\bin\starship.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\starship\bin\starship.exe')
)
Check 'Starship 已安装' ([bool]$starship) $(if ($starship) { $starship } else { 'PATH 里没找到，也没在常见安装目录' })

# ---------- 2. 字体 ----------
Write-Host ''
Write-Host '[ 字体 ]' -ForegroundColor Cyan

$ttf    = 'CaskaydiaCoveNerdFont-Regular.ttf'
$fontOk = (Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts\$ttf")) -or
          (Test-Path -LiteralPath (Join-Path $env:windir "Fonts\$ttf"))
Check 'Nerd Font 文件已就位' $fontOk "查找 $ttf（用户级和系统级都查了）"

# 注册表里登记的是短名 CaskaydiaCove NF，不是终端里用的全称 CaskaydiaCove Nerd Font
$regName = 'CaskaydiaCove NF Regular (TrueType)'
$regVal = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -Name $regName -ErrorAction SilentlyContinue
if (-not $regVal) {
    $regVal = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -Name $regName -ErrorAction SilentlyContinue
}
Check '字体已注册到系统' ($null -ne $regVal) "查找 $regName（HKCU 和 HKLM 都查了），没有就重跑 install.ps1"

# ---------- 3. 配置文件 ----------
Write-Host ''
Write-Host '[ 配置文件 ]' -ForegroundColor Cyan

Check 'WezTerm 配置存在' (Test-Path -LiteralPath $WezCfg) $WezCfg
Check 'Nushell 配置存在' (Test-Path -LiteralPath $NuCfg) $NuCfg
Check 'Starship 配置存在' (Test-Path -LiteralPath $SsCfg) $SsCfg

# ---------- 4. 配置能不能真的跑起来 ----------
Write-Host ''
Write-Host '[ 运行验证 ]' -ForegroundColor Cyan

if ($wezterm) {
    # 拿 ls-fonts 当配置加载的冒烟测试：
    # 配置有错时 WezTerm 会在 stderr 打 ERROR，但退出码仍是 0，所以只能看输出内容
    $out = (& $wezterm --config-file $WezCfg ls-fonts 2>&1 | Out-String)
    Check 'WezTerm 配置能正常加载' ($out -match 'Primary font:' -and $out -notmatch 'ERROR')
    Check '字体解析到 CaskaydiaCove' ($out -match 'CaskaydiaCove') '解析不到说明字体没装好，会退化成默认字体'
} else {
    Write-Host '         WezTerm 没装，跳过配置加载检查' -ForegroundColor DarkGray
}

if ($nu) {
    $nuOut = (& $nu --config $NuCfg --env-config $NuEnv -c 'print "wezterm-kit-nu-ok"' 2>&1 | Out-String)
    Check 'Nushell 能加载配置' ($nuOut -match 'wezterm-kit-nu-ok')
} else {
    Write-Host '         Nushell 没装，跳过配置加载检查' -ForegroundColor DarkGray
}

if ($starship) {
    $env:STARSHIP_CONFIG = $SsCfg
    $ssOut = (& $starship prompt 2>&1 | Out-String)
    Check 'Starship 能渲染提示符' ($ssOut.Trim().Length -gt 0) '渲染为空说明 starship.toml 没被读到'
} else {
    Write-Host '         Starship 没装，跳过提示符检查' -ForegroundColor DarkGray
}

# ---------- 5. AI CLI 快捷命令 ----------
Write-Host ''
Write-Host '[ AI CLI 快捷命令 ]' -ForegroundColor Cyan

if (Test-Path -LiteralPath $NuCfg) {
    $nuText = [IO.File]::ReadAllText($NuCfg)
    $shortcuts = @()
    if ($nuText -match 'def cc \[\]') { $shortcuts += 'cc' }
    if ($nuText -match 'def qw \[\]') { $shortcuts += 'qw' }
    if ($nuText -match 'def cx \[\]') { $shortcuts += 'cx' }
    if ($nuText -match 'def gm \[\]') { $shortcuts += 'gm' }
    if ($shortcuts.Count -gt 0) {
        Write-Host "  [OK]   已注入 $($shortcuts.Count) 个： $($shortcuts -join '  ')" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host '  [ -- ] 一个都没有' -ForegroundColor Yellow
        Write-Host '         装完 claude / qwen / codex / gemini 后重跑 install.ps1 即可自动补上' -ForegroundColor DarkGray
    }
}

# ---------- 汇总 ----------
Write-Host ''
if ($script:fail -eq 0) {
    Write-Host "全部通过（$script:pass 项）" -ForegroundColor Green
    Write-Host '如果终端里字体或配色看着不对，把 WezTerm 完全退出再重开一次。' -ForegroundColor DarkGray
    exit 0
}
Write-Host "通过 $script:pass 项，失败 $script:fail 项" -ForegroundColor Red
Write-Host '按上面的 [FAIL] 提示修，或者看 docs\排错.md' -ForegroundColor DarkGray
exit 1
