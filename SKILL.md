---
name: wezterm-kit
description: 在 Windows 上一键装好 WezTerm 终端环境（WezTerm + Nushell + Starship + Nerd Font + 全套配置），替代 cmd / PowerShell / Windows Terminal。当用户要求配置终端、安装 WezTerm、搭建 Nushell、美化命令行提示符、或想让终端能显示图标和分屏时使用。
---

# wezterm-kit

给 Windows 装一套开箱即用的现代终端：WezTerm 做终端模拟器，Nushell 做 shell，Starship 做提示符，CaskaydiaCove Nerd Font 负责图标和连字。

## 什么时候用

- 用户要装 / 配置 WezTerm
- 用户想换掉 cmd、PowerShell 或 Windows Terminal
- 用户想让终端提示符显示 git 分支、图标、语言版本
- 用户想搭 Nushell 环境

## 前置条件

- Windows 10 1709+ 或 Windows 11（要有 winget）
- 不需要管理员权限
- 装之前**让用户先关掉正在运行的 WezTerm**，否则 winget 装不上

## 执行步骤

### 第 1 步：问清三件事

别猜，直接问用户：

0. **WezTerm 用哪个通道？** 默认 Nightly。这一点要主动告诉用户，让他自己选：
   - **Nightly（推荐）**：每天从主分支自动打包，Stable 之后的新特性和 bug 修复都在里面，装完自带更新检查
   - **Stable**：停在 `20240203-110809-5046fc22`，自 2024-02 起不再更新，只走 winget，长期不收 bug 修复

   用户明确要 Stable 才加 `-Channel Stable`。

1. **背景图用哪张？** 仓库自带一张（`assets\background.png`），默认就是它，用户不用管。
   用户想换就问绝对路径；想彻底不要背景就加 `-NoBackground`。
   （启用背景时窗口上内边距自动设成 30 给图让位，不启用是 2）
2. **要不要配代理？** 要的话问端口（常见 7890 / 10809）。不传就完全不写代理配置。
3. **要不要给 AI CLI 开自动确认？** 只有在用户明确要求时才加 `-AiCliAutoAccept`。
   默认是关的——这个开关会让带跳过确认参数的命令（如 `cc`/`cx`/`gm`）跳过所有权限确认，等于把本机执行权交给模型。

用户嫌麻烦就说「先来套默认的」，直接跑无参数版本，回头想改随时重跑。

### 第 2 步：跑安装脚本

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1
```

带参数：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 `
    -BackgroundImage "D:\data\images\bg.png" `
    -ProxyPort 7890
```

不确定会发生什么时，先加 `-WhatIf` 跑一遍预演，只打印不改动：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -WhatIf
```

### 第 3 步：跑验收

```powershell
powershell -ExecutionPolicy Bypass -File scripts\verify.ps1
```

退出码 0 是全通过，1 是有失败项。任何 `[FAIL]` 都带了原因，照着修。

### 第 4 步：提醒用户

- **完全退出 WezTerm 再重开**（不是关窗口，是退出进程）。字体和配色要重启才生效。
- 快捷键变了：`Ctrl+W` 关标签页，`Ctrl+Shift+W` 才关整个应用。

## 参数速查

| 参数 | 作用 | 默认 |
|---|---|---|
| `-Channel <Nightly\|Stable>` | WezTerm 安装通道 | `Nightly` |
| `-BackgroundImage <路径>` | 换成自己的背景图。路径不存在则跳过并提示 | 仓库自带 `assets\background.png` |
| `-NoBackground` | 不用任何背景图 | 关 |
| `-ProxyPort <端口>` | 写入 http/https 代理 | 不写代理 |
| `-FontName <名字>` | 终端字体 | `CaskaydiaCove Nerd Font` |
| `-FontSize <数字>` | 字号 | 14 |
| `-AiCliAutoAccept` | 给 AI CLI（cc/cx/gm 等带跳过确认参数的）加跳过确认的参数 | 关 |
| `-SkipApps` | 不装软件，只写配置和字体 | 关 |
| `-SkipFonts` | 不装字体 | 关 |
| `-WhatIf` | 预演，不改动任何东西 | 关 |

## 硬性约束

- **不要手动编辑 `config/` 下的模板文件去满足用户的定制需求。** 那是模板，重跑脚本会被覆盖。用户要长期改，改生成后的 `~/.wezterm.lua` 和 `~/AppData/Roaming/nushell/config.nu`。
- **不要跳过备份直接覆盖。** 脚本已经自动备份成 `<文件名>.bak.<时间戳>`，别绕过它。
- **不要默认开 `-AiCliAutoAccept`。**
- **不要把 WezTerm 装到非默认位置。** 官方 setup.exe 会顺带往资源管理器右键菜单注册「Open WezTerm here」，换路径安装容易丢掉这个集成，配置里「跟随启动目录」的能力就废了。
- **不要手改 `.ps1` 文件后忘了 BOM。** PowerShell 5.1 解析 UTF-8 无 BOM 的脚本会按 GBK 解码，中文注释全变乱码然后报语法错。改完必须存成 UTF-8 **带 BOM**。

## 装机后长什么样

- 默认 shell 是 Nushell，提示符由 Starship 渲染（git 分支、目录、语言版本）
- `Alt+Shift+→` / `Alt+Shift+↓` 分屏，`Ctrl+方向键` 跳窗格，新窗格继承当前目录
- `Ctrl+1`~`Ctrl+8` 切标签页
- 右键粘贴，`Shift+右键` 复制
- 去掉了标题栏，用 `Ctrl+左键拖拽` 移动窗口
- 资源管理器里右键有「Open WezTerm here」，从那里打开会直接落在当前目录
- 检测到的 AI CLI 会自动生成快捷命令：`cc` / `qw` / `cx` / `gm` / `km` / `gr`，启动时会把标签页标题改成对应名字

## 出问题看这里

见 `docs\排错.md`。常见问题：字体装了但终端里没变、nightly 下载慢或校验失败、winget 装不动、提示符显示成方框、Nushell 起不来。
