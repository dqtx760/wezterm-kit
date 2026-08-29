<#
.SYNOPSIS
    wezterm-kit 一键装机：WezTerm + Nushell + Starship + Nerd Font + 全套配置。
.DESCRIPTION
    WezTerm 有两个通道，用 -Channel 选：
      Nightly  每夜构建，开发者每天从主分支打包，持续有新特性和 bug 修复（默认，推荐）
      Stable   官方正式版，停在 20240203，自 2024-02 起不再更新，只走 winget

    幂等    可反复运行，结果一致，不会重复安装。
    免管理员 字体装到用户级目录 + 写 HKCU 注册表，不需要提权。
    可预演  加 -WhatIf 只打印将要做什么，不改动任何东西。
    会备份  覆盖任何已有配置前，先存一份 <文件名>.bak.<时间戳>。
.PARAMETER Channel
    WezTerm 安装通道：Nightly（默认，推荐）或 Stable。
    Nightly  从 GitHub 下 WezTerm-nightly-setup.exe 静默安装，带 sha256 校验，
             装完 WezTerm 自己会检查更新并提示。
    Stable   走 winget install wez.wezterm，版本停在 20240203，不再收 bug 修复。
.PARAMETER BackgroundImage
    背景图片绝对路径。默认用仓库自带的 assets\background.png。
    图片会被复制到 %LOCALAPPDATA%\wezterm-kit\background.png 后再引用，
    所以克隆的仓库删掉也不影响。
    （启用背景时窗口上内边距会自动设成 30 给图让位，不启用则是 2）
.PARAMETER NoBackground
    不用任何背景图，连仓库自带的那张也不用。
.PARAMETER ProxyPort
    代理端口，例如 7890。不传则完全不写代理配置。
.PARAMETER FontName
    终端字体名，默认 CaskaydiaCove Nerd Font。
.PARAMETER FontSize
    字号，默认 14。
.PARAMETER AiCliAutoAccept
    给 cc/cx/gm 加上「跳过所有确认」的参数。默认关闭——那等于把本机执行权交给模型。
.PARAMETER SkipApps
    跳过软件安装，只处理字体和配置。
.PARAMETER SkipFonts
    跳过字体安装。
.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1
    默认：装上软件 + 字体 + 仓库自带的背景图
.EXAMPLE
    .\install.ps1 -BackgroundImage "D:\data\images\bg.png" -ProxyPort 7890
.EXAMPLE
    .\install.ps1 -NoBackground
.EXAMPLE
    .\install.ps1 -Channel Stable
    改用 winget 装 WezTerm 正式版（停在 20240203，不再收 bug 修复）
.EXAMPLE
    .\install.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Nightly', 'Stable')]
    [string] $Channel = 'Nightly',
    [string] $BackgroundImage,
    [switch] $NoBackground,
    [int]    $ProxyPort = 0,
    [string] $FontName  = 'CaskaydiaCove Nerd Font',
    [double] $FontSize  = 14,
    [switch] $AiCliAutoAccept,
    [switch] $SkipApps,
    [switch] $SkipFonts
)

$ErrorActionPreference = 'Stop'
# 关掉 Invoke-WebRequest 的进度条：下 45MB 的安装包时它会刷满整个屏幕
$ProgressPreference = 'SilentlyContinue'

$KitRoot = Split-Path -Parent $PSScriptRoot
$Stamp   = Get-Date -Format 'yyyyMMdd-HHmmss'
$Inv     = [Globalization.CultureInfo]::InvariantCulture

$FontVersion = 'v3.5.1'

# WezTerm Nightly 的固定直链（文件每天被覆盖更新，链接不变，可直接收藏）
$NightlyUrl = 'https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-setup.exe'

# 背景图：没显式指定、也没说不要，就用仓库自带的那张
if ($NoBackground) {
    $BackgroundImage = ''
} elseif (-not $BackgroundImage) {
    $bundled = Join-Path $KitRoot 'assets\background.png'
    if (Test-Path -LiteralPath $bundled) { $BackgroundImage = $bundled }
}

# AI CLI 的「跳过所有确认」参数。
# qwen 0.21.8 没有这个参数，留空（老版本 qwen 用的 -y 早已失效，会被静默忽略）。
$AiFlags = @{
    claude   = '--dangerously-skip-permissions'
    codex    = '--dangerously-bypass-approvals-and-sandbox'
    gemini   = '-y'
    qwen     = ''
    kimi     = ''
    grok     = ''
    opencode = ''
}

# 刚装完的程序可能还没进当前会话的 PATH，补几个常见落点
$AiCliFallback = @{
    claude   = @((Join-Path $env:APPDATA 'npm\claude.cmd'))
    qwen     = @((Join-Path $env:APPDATA 'npm\qwen.cmd'))
    gemini   = @((Join-Path $env:APPDATA 'npm\gemini.cmd'))
    codex    = @((Join-Path $env:LOCALAPPDATA 'Programs\OpenAI\Codex\bin\codex.cmd'))
    kimi     = @((Join-Path $env:APPDATA 'npm\kimi.cmd'))
    grok     = @((Join-Path $env:APPDATA 'npm\grok.cmd'))
    opencode = @((Join-Path $env:APPDATA 'npm\opencode.cmd'))
}

$WezCfg = Join-Path $HOME '.wezterm.lua'
$NuDir  = Join-Path $env:APPDATA 'nushell'
$NuCfg  = Join-Path $NuDir 'config.nu'
$NuEnv  = Join-Path $NuDir 'env.nu'
$SsCfg  = Join-Path $HOME '.config\starship.toml'

# -------------------- 输出 --------------------
function Write-Step { param([string]$Msg) Write-Host ">> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "   [OK]  $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "   [!!]  $Msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$Msg) Write-Host "   [XX]  $Msg" -ForegroundColor Red }
function Write-Note { param([string]$Msg) Write-Host "         $Msg" -ForegroundColor DarkGray }

# -------------------- 工具函数 --------------------
function Read-Tpl {
    param([string]$Relative)
    $p = Join-Path $KitRoot $Relative
    if (-not (Test-Path -LiteralPath $p)) { throw "模板文件不存在: $p" }
    return [IO.File]::ReadAllText($p)
}

function Write-Config {
    param([string]$Path, [string]$Content)
    if ($WhatIfPreference) {
        Write-Host "   [预演] 写入 $Path" -ForegroundColor Yellow
        return
    }
    $dir = Split-Path -Path $Path -Parent
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $enc = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
    [IO.File]::WriteAllText($Path, $Content, $enc)
    Write-Ok "已写入 $Path"
}

function Backup-File {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $bak = "$Path.bak.$Stamp"
    if ($WhatIfPreference) {
        Write-Host "   [预演] 备份 $Path" -ForegroundColor Yellow
        return
    }
    Copy-Item -LiteralPath $Path -Destination $bak -Force
    Write-Ok "已备份 $(Split-Path -Path $Path -Leaf) -> $(Split-Path -Path $bak -Leaf)"
}

function Test-Cli {
    param([string]$Name)
    if (Get-Command $Name -ErrorAction SilentlyContinue) { return $true }
    if ($AiCliFallback.ContainsKey($Name)) {
        foreach ($p in $AiCliFallback[$Name]) {
            if ($p -and (Test-Path -LiteralPath $p)) { return $true }
        }
    }
    return $false
}

function Install-App {
    param([string]$Id, [string]$Name)
    Write-Step "检查 $Name（$Id）"

    $listed = & winget list --id $Id --exact --disable-interactivity 2>$null
    if ($LASTEXITCODE -eq 0 -and ($listed | Select-String -SimpleMatch -Pattern $Id)) {
        Write-Ok "$Name 已安装，跳过"
        return $true
    }

    if ($WhatIfPreference) {
        Write-Host "   [预演] winget install --id $Id" -ForegroundColor Yellow
        return $true
    }

    & winget install --id $Id --exact --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$Name 安装完成"
        return $true
    }
    Write-Fail "$Name 安装失败（exit $LASTEXITCODE）"
    Write-Note "手动装完再重跑本脚本即可，脚本会跳过已装的软件"
    return $false
}

function Install-NerdFont {
    param([string]$Version = $FontVersion)

    Write-Step '检查 Nerd Font（CaskaydiaCove Nerd Font）'

    $fontDir  = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $fontDirS = Join-Path $env:windir 'Fonts'
    $regKey   = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    $regKeyS  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

    # 注册表里登记的是短名 "CaskaydiaCove NF"，不是终端里用的全称
    # "CaskaydiaCove Nerd Font"。DirectWrite 两个名字都认，指向同一套字体。
    $regName = 'CaskaydiaCove NF Regular (TrueType)'

    $want = @(
        'CaskaydiaCoveNerdFont-Regular.ttf',
        'CaskaydiaCoveNerdFont-Bold.ttf',
        'CaskaydiaCoveNerdFont-Italic.ttf',
        'CaskaydiaCoveNerdFont-BoldItalic.ttf'
    )

    # 系统级、用户级都要查：装在哪的都有
    $hasReg = [bool](Get-ItemProperty -Path $regKey -Name $regName -ErrorAction SilentlyContinue)
    if (-not $hasReg) {
        $hasReg = [bool](Get-ItemProperty -Path $regKeyS -Name $regName -ErrorAction SilentlyContinue)
    }
    $hasFile = (Test-Path -LiteralPath (Join-Path $fontDir $want[0])) -or
               (Test-Path -LiteralPath (Join-Path $fontDirS $want[0]))

    if ($hasReg -and $hasFile) {
        Write-Ok '字体已安装，跳过'
        return $true
    }

    if ($WhatIfPreference) {
        Write-Host "   [预演] 下载 nerd-fonts $Version 并注册到用户级字体目录" -ForegroundColor Yellow
        return $true
    }

    $zip = Join-Path $env:TEMP "CascadiaCode-$Version.zip"
    $dir = Join-Path $env:TEMP "CascadiaCode-$Version"

    Write-Note "下载 nerd-fonts $Version（约 20MB）..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest `
        -Uri "https://github.com/ryanoasis/nerd-fonts/releases/download/$Version/CascadiaCode.zip" `
        -OutFile $zip -UseBasicParsing

    if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
    Expand-Archive -LiteralPath $zip -DestinationPath $dir -Force

    if (-not (Test-Path -LiteralPath $fontDir)) {
        New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
    }

    # Windows 字体注册表：值名决定字体在应用里显示成什么名字
    # 沿用 Nerd Font 官方安装器的短名写法（CaskaydiaCove NF ...）
    $regNames = @{
        'CaskaydiaCoveNerdFont-Regular.ttf'    = 'CaskaydiaCove NF Regular (TrueType)'
        'CaskaydiaCoveNerdFont-Bold.ttf'       = 'CaskaydiaCove NF Bold (TrueType)'
        'CaskaydiaCoveNerdFont-Italic.ttf'     = 'CaskaydiaCove NF Italic (TrueType)'
        'CaskaydiaCoveNerdFont-BoldItalic.ttf' = 'CaskaydiaCove NF Bold Italic (TrueType)'
    }

    foreach ($f in $want) {
        $src = Get-ChildItem -LiteralPath $dir -Filter $f -Recurse | Select-Object -First 1
        if (-not $src) { Write-Warn "压缩包里没找到 $f，跳过"; continue }
        Copy-Item -LiteralPath $src.FullName -Destination (Join-Path $fontDir $f) -Force
        New-ItemProperty -Path $regKey -Name $regNames[$f] -Value $f -PropertyType String -Force | Out-Null
    }

    Write-Ok "字体已装到 $fontDir"
    Write-Note '注册表改完需要重启 WezTerm 才会看到新字体'
    return $true
}

function Install-WezTermNightly {
    param([string]$Version = $NightlyUrl)

    Write-Step '检查 WezTerm Nightly'

    # Nightly 每天覆盖同一个文件，没有版本号可比对，所以每次都重新下载安装
    $tmp   = Join-Path $env:TEMP 'WezTerm-nightly-setup.exe'
    $shaF  = "$tmp.sha256"
    $logF  = Join-Path $env:TEMP 'wezterm-nightly-install.log'

    if ($WhatIfPreference) {
        Write-Host "   [预演] 下载 $Version 并静默安装" -ForegroundColor Yellow
        return $true
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Note '下载 WezTerm Nightly（约 45MB）...'
    try {
        Invoke-WebRequest -Uri $Version -OutFile $tmp -UseBasicParsing
    } catch {
        Write-Fail "下载失败：$_"
        Write-Note '网络不通的话，可以改用 -Channel Stable 走 winget，或者挂上代理重跑'
        return $false
    }

    # 校验：Nightly 每天换文件，sha256 必须核对，下到一半断流会装出个坏的
    $expected = ''
    try {
        Invoke-WebRequest -Uri "$Version.sha256" -OutFile $shaF -UseBasicParsing
        $expected = ((Get-Content -LiteralPath $shaF -Raw) -split '\s+')[0].ToLower()
    } catch {
        Write-Warn '拿不到 sha256 校验文件，跳过校验'
    }
    if ($expected) {
        $actual = (Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $expected) {
            Write-Fail 'sha256 校验不通过，已中止安装（文件可能没下完整）'
            Write-Note "期望 $expected"
            Write-Note "实际 $actual"
            return $false
        }
        Write-Ok "sha256 校验通过（$($actual.Substring(0, 12))...）"
    }

    Write-Note '静默安装中...'
    $proc = Start-Process -FilePath $tmp -ArgumentList '/VERYSILENT', '/NORESTART', '/SUPPRESSMSGBOXES', "/LOG=$logF" -Wait -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Ok 'WezTerm Nightly 安装完成'
        Write-Note "安装日志 $logF"
        Write-Note 'Nightly 自带更新检查，之后有新构建 WezTerm 会自己提示'
        return $true
    }
    Write-Fail "安装失败（exit $($proc.ExitCode)），看日志 $logF"
    return $false
}

# ==================== 开始 ====================
Write-Host ''
Write-Host '=== wezterm-kit 装机 ===' -ForegroundColor Magenta
if ($WhatIfPreference) { Write-Host '预演模式：不会真的改动任何东西' -ForegroundColor Yellow }
Write-Host "仓库目录 $KitRoot" -ForegroundColor DarkGray
Write-Host ''

# ---------- 0. 环境 ----------
Write-Step '环境检查'
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Fail '需要 PowerShell 5.0 或更高'
    exit 1
}
Write-Ok "PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)，WezTerm 通道 $Channel"

# ---------- 1. 软件 ----------
if ($SkipApps) {
    Write-Warn '按 -SkipApps 跳过软件安装'
} else {
    # Nushell / Starship 走 winget；WezTerm 看通道
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Fail '没找到 winget。Windows 10 1709+ / Windows 11 自带，或到 Microsoft Store 装「应用安装程序」'
        Write-Note 'Nushell 和 Starship 要靠 winget 装，没有它装不了'
        exit 1
    }
    Write-Ok 'winget 可用'

    if ($Channel -eq 'Stable') {
        Install-App -Id 'wez.wezterm' -Name 'WezTerm（Stable 20240203，已停更）' | Out-Null
    } else {
        Install-WezTermNightly | Out-Null
    }
    Install-App -Id 'Nushell.Nushell'   -Name 'Nushell'  | Out-Null
    Install-App -Id 'Starship.Starship' -Name 'Starship' | Out-Null
}

# ---------- 2. 字体 ----------
if ($SkipFonts) { Write-Warn '按 -SkipFonts 跳过字体安装' } else { Install-NerdFont | Out-Null }

# ---------- 3. 备份 ----------
Write-Step '备份已有配置'
Backup-File $WezCfg
Backup-File $NuCfg
Backup-File $NuEnv
Backup-File $SsCfg

# ---------- 4. WezTerm 配置 ----------
Write-Step '生成 WezTerm 配置'
$cfg = Read-Tpl 'config\wezterm\wezterm.lua'
$cfg = $cfg.Replace('__FONT_NAME__', $FontName)
$cfg = $cfg.Replace('__FONT_SIZE__', $FontSize.ToString($Inv))
$cfg = $cfg.Replace('__PADDING_TOP__', $(if ($BackgroundImage) { '30' } else { '2' }))

if ($BackgroundImage) {
    if (Test-Path -LiteralPath $BackgroundImage) {
        # 复制到固定位置再引用。不直接指向原文件，是为了让克隆的仓库删掉之后背景图还在
        $bgStore = Join-Path $env:LOCALAPPDATA 'wezterm-kit'
        $bgDest  = Join-Path $bgStore 'background.png'
        if (-not (Test-Path -LiteralPath $bgStore)) {
            New-Item -ItemType Directory -Path $bgStore -Force | Out-Null
        }
        if (-not $WhatIfPreference) {
            Copy-Item -LiteralPath $BackgroundImage -Destination $bgDest -Force
        }
        $bg = Read-Tpl 'config\wezterm\blocks\background.lua'
        # WezTerm 的路径分隔符认正斜杠
        $bg = $bg.Replace('__BACKGROUND_IMAGE__', ($bgDest -replace '\\', '/'))
        $cfg = $cfg.Replace('--__BACKGROUND_BLOCK__', $bg)
        Write-Ok "背景图已启用，复制到 $bgDest"
    } else {
        Write-Warn "背景图不存在，已跳过：$BackgroundImage"
        $cfg = $cfg.Replace('--__BACKGROUND_BLOCK__', '')
    }
} else {
    $cfg = $cfg.Replace('--__BACKGROUND_BLOCK__', '')
}

if ($ProxyPort -gt 0) {
    $px = Read-Tpl 'config\wezterm\blocks\proxy.lua'
    $cfg = $cfg.Replace('--__PROXY_BLOCK__', $px.Replace('__PROXY_URL__', "http://127.0.0.1:$ProxyPort"))
    Write-Ok "代理已写入端口 $ProxyPort"
} else {
    $cfg = $cfg.Replace('--__PROXY_BLOCK__', '')
}
Write-Config -Path $WezCfg -Content $cfg

# ---------- 5. Nushell 配置 ----------
Write-Step '生成 Nushell 配置'
$nu = Read-Tpl 'config\nushell\config.nu'

if ($ProxyPort -gt 0) {
    $px = Read-Tpl 'config\nushell\blocks\proxy.nu'
    $nu = $nu.Replace('#__PROXY_BLOCK__', $px.Replace('__PROXY_URL__', "http://127.0.0.1:$ProxyPort"))
} else {
    $nu = $nu.Replace('#__PROXY_BLOCK__', '')
}

Write-Step '检测已安装的 AI CLI'
$snips = @()
foreach ($cli in @('claude', 'qwen', 'codex', 'gemini', 'kimi', 'grok', 'opencode')) {
    if (Test-Cli $cli) {
        $flag = ''
        if ($AiCliAutoAccept) { $flag = $AiFlags[$cli] }
        $snips += (Read-Tpl "snippets\$cli.nu").Replace('__FLAGS__', $flag)
        Write-Ok "检测到 $cli，已加入快捷命令"
    } else {
        Write-Note "未检测到 $cli，跳过"
    }
}
$nu = $nu.Replace('#__SNIPPETS__', ($snips -join "`n"))
# 片段里 AI CLI 参数为空时会留下行尾空格，清掉
$nu = [regex]::Replace($nu, '[ \t]+(?=\r?\n|$)', '')
Write-Config -Path $NuCfg -Content $nu
Write-Config -Path $NuEnv -Content (Read-Tpl 'config\nushell\env.nu')

# ---------- 6. Starship 配置 ----------
Write-Step '写入 Starship 配置'
Write-Config -Path $SsCfg -Content (Read-Tpl 'config\starship\starship.toml')

# ---------- 收尾 ----------
Write-Host ''
Write-Host '=== 完成 ===' -ForegroundColor Magenta
Write-Host '  1. 完全退出 WezTerm 再重开（字体和配色要重启才生效）' -ForegroundColor White
Write-Host "  2. 跑验收： powershell -File `"$PSScriptRoot\verify.ps1`"" -ForegroundColor White
if ($AiCliAutoAccept) {
    Write-Host ''
    Write-Warn '你开了 -AiCliAutoAccept：带跳过确认参数的命令（cc/cx/gm 等）会跳过所有确认，等于把本机执行权直接交给模型'
}
Write-Host ''
