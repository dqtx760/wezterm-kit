<p align="center">
  <img src="./assets/readme/hero.svg" width="100%"
       alt="wezterm-kit：一行命令装好 WezTerm + Nushell + Starship + Nerd Font，装完 13 项验收全部通过">
</p>

> 🌐 其他语言：[English](README.md)

一行命令，把 Windows 上那套老终端换成开箱即用的现代环境。也可以把仓库地址丢给 AI，让它替你装完。

---

## 它装什么

四样东西，装好并且**互相配通**：

| 组件 | 干什么 |
|---|---|
| **WezTerm** | 终端模拟器。GPU 加速、Lua 配置、分屏好用 |
| **Nushell** | shell。管道里传的是结构化数据，不用拿纯文本硬解析 |
| **Starship** | 提示符。git 分支、目录、语言版本一眼看到 |
| **CaskaydiaCove Nerd Font** | 图标和连字。缺了它提示符里全是方框 |

单独装这四样都不难，难的是让它们配合起来：字体要能被终端认到、提示符要读到配置、分屏要继承当前目录、AI 命令行工具要能自动改标签页标题。这些琐事脚本全包了。

---

## 一次装机做了什么

<p align="center">
  <img src="./assets/readme/workflow.svg" width="100%"
       alt="install.ps1 的五个阶段：检测环境、备份旧配置、安装软件与字体、生成配置、跑验收">
</p>

重复跑不会有副作用：软件装过了就跳过，配置每次从模板重新生成，覆盖前一定先备份。

**可选的东西按需注入**——背景图、代理、AI CLI 快捷命令都是检测到了才写进配置，不会留一堆指向不存在文件的悬空设置。

---

## 效果预览

装完之后的 WezTerm 长这样：自定义标签页标题、半透明背景图、Starship 提示符，分屏后目录会继承。

<p align="center">
  <img src="./assets/readme/screenshot.jpg" width="100%"
       alt="WezTerm 实际效果：多标签页、半透明背景图、Starship 提示符">
</p>

---

## WezTerm 选哪个版本通道

用 `-Channel` 选，默认 Nightly。

| 通道 | 版本 | 状态 |
|---|---|---|
| **Nightly**（默认，推荐） | 每夜构建 | 每天从主分支自动打包，包含 Stable 之后的所有新特性和 bug 修复。自带更新检查，有新构建会主动提示 |
| **Stable** | `20240203-110809-5046fc22` | 自 2024-02 起**已停止更新**，长期不收 bug 修复。也是 winget 唯一登记的版本 |

官方下载页：<https://wezterm.org/install/windows.html>

Nightly 固定直链（文件每天被覆盖更新，可以直接收藏）：

```
https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-setup.exe
```

想先自己装 WezTerm 也行——点上面的链接或用下载页的 "Windows (setup.exe)"，**建议装到默认位置**，安装器会把「Open WezTerm here」注册进资源管理器右键菜单。之后再跑脚本时加 `-SkipApps`，只装字体和配置。

```powershell
# 默认就是 Nightly
.\scripts\install.ps1

# 想用正式版
.\scripts\install.ps1 -Channel Stable
```

---

## 开始之前

| 项目 | 要求 |
|---|---|
| 系统 | Windows 10 1709+ 或 Windows 11 |
| winget | 系统自带，用来装 Nushell 和 Starship |
| 管理员权限 | **不需要** |
| 网络 | 要能访问 GitHub（WezTerm 45MB + 字体 20MB） |
| 前提动作 | **先把正在运行的 WezTerm 完全退出**，否则装不上 |

---

## 安装方式一：自己手动装

### 1. 拿到仓库

```powershell
git clone https://github.com/dqtx760/wezterm-kit.git
cd wezterm-kit
```

没有 git 也行：仓库页面 → `Code` → `Download ZIP` → 解压。

### 2. 跑安装脚本

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1
```

软件、字体、配置全自动，默认带上仓库自带的背景图。

不放心就先预演，只打印会做什么、不改动任何东西：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -WhatIf
```

### 3. 验收

```powershell
powershell -ExecutionPolicy Bypass -File scripts\verify.ps1
```

13 项逐条检查，失败会直接告诉你原因。退出码 0 是全通过。

### 4. 完全退出 WezTerm 再重开

不是关窗口，是**退出进程**。字体和配色要重启才生效。

### 常用参数

```powershell
# 换成自己的背景图
.\scripts\install.ps1 -BackgroundImage "D:\path\to\your.png"

# 不要背景图
.\scripts\install.ps1 -NoBackground

# 配代理
.\scripts\install.ps1 -ProxyPort 7890

# 换字体
.\scripts\install.ps1 -FontName "JetBrainsMono Nerd Font" -FontSize 15

# 只重装配置，不动软件和字体
.\scripts\install.ps1 -SkipApps -SkipFonts

# 给 cc / cx / gm 加跳过确认的参数（谨慎，等于把执行权交给模型）
.\scripts\install.ps1 -AiCliAutoAccept
```

| 参数 | 作用 | 默认 |
|---|---|---|
| `-Channel <Nightly\|Stable>` | WezTerm 安装通道 | `Nightly` |
| `-BackgroundImage <路径>` | 换成自己的背景图 | 仓库自带 `assets\background.png` |
| `-NoBackground` | 不用任何背景图 | 关 |
| `-ProxyPort <端口>` | 写入 http/https 代理 | 不写代理 |
| `-FontName <名字>` | 换终端字体 | `CaskaydiaCove Nerd Font` |
| `-FontSize <数字>` | 字号 | 14 |
| `-AiCliAutoAccept` | 给 cc/cx/gm 加跳过确认的参数 | 关 |
| `-SkipApps` | 不装软件，只处理字体和配置 | 关 |
| `-SkipFonts` | 不装字体 | 关 |
| `-WhatIf` | 预演，不改动任何东西 | 关 |

---

## 安装方式二：丢给 AI 帮你装

不想自己敲命令，就把下面这段连着项目地址一起发给任意 AI 编程工具（Claude Code、Codex、Cursor 等）。项目里的 `SKILL.md` 是给 AI 看的操作手册，它会照着做。

```text
帮我在这台 Windows 电脑上装一个终端环境，项目地址：
https://github.com/dqtx760/wezterm-kit

按下面几步来：
1. 把仓库克隆到本地（没装 git 就直接下 zip 解压）
2. 读仓库里的 SKILL.md，按里面的流程执行，别自己发挥
3. 动手前先问我三个问题：背景图用自带的还是要换、要不要配代理（端口多少）、
   要不要给 AI CLI 开自动确认
4. 先跑 -WhatIf 预演，把会改动的东西列给我看，我确认之后再真跑
5. 装完跑 scripts\verify.ps1 验收，把结果贴给我
6. 中途报错先停下来问我，别自己猜着改配置

需要我关掉正在运行的 WezTerm 时提醒我一声。
```

AI 会问你三个问题，然后一步步装完。你只需要回答问题，再在预演结果上点个头。

---

## 软件使用

### 基本操作

打开 WezTerm 默认进 Nushell，提示符由 Starship 渲染。

| 想干什么 | 怎么做 |
|---|---|
| 在当前目录打开 | 资源管理器右键 → **Open WezTerm here** |
| 分屏 | `Alt+Shift+→` 左右分，`Alt+Shift+↓` 上下分 |
| 在窗格间跳 | `Ctrl+方向键` |
| 新建标签页 | `Ctrl+T` |
| 切标签页 | `Ctrl+1` ~ `Ctrl+8` |
| 关标签页 | `Ctrl+W` |
| 关整个应用 | `Ctrl+Shift+W` |
| 粘贴 | 鼠标右键 |
| 复制 | `Shift+右键` |
| 终端里选文本（TUI 程序内） | 按住 `Shift` 再拖选 |
| 搜索滚回缓冲区 | `Ctrl+Shift+F` |
| 命令面板 | `Ctrl+Shift+P` |
| 移动窗口 | `Ctrl+左键拖拽`（标题栏被去掉了） |

> **别按错 `Ctrl+W` 和 `Ctrl+Shift+W`**：`Ctrl+W` 只关当前标签页，`Ctrl+Shift+W` 是关掉整个 WezTerm、所有标签页一起没。

新分出来的窗格会**继承当前目录**，分屏后不用重新 `cd`。

### 快捷键全表

| 快捷键 | 作用 |
|---|---|
| `Alt+Shift+→` / `Alt+Shift+↓` | 水平 / 垂直分屏 |
| `Ctrl+←` `Ctrl+→` `Ctrl+↑` `Ctrl+↓` | 窗格跳转 |
| `Ctrl+W` | 关当前标签页 |
| `Ctrl+Shift+W` | 关整个应用 |
| `Alt+W` | 关当前标签页（跟 `Ctrl+W` 一样，留着顺手） |
| `Ctrl+T` | 新建标签页 |
| `Ctrl+1` ~ `Ctrl+8` | 切到第 1~8 个标签页 |
| `Ctrl+U` | 删除到行首 |
| 右键 | 粘贴 |
| `Shift+右键` | 复制 |
| `Ctrl+左键拖拽` | 移动窗口 |

### 字体

用的是 **CaskaydiaCove Nerd Font**——微软 Cascadia Code（VS Code 同款）打上 Nerd Font 补丁的版本，来自 [ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) v3.5.1。

**为什么非它不可**：提示符里那些图标——git 分支符号、目录图标、语言图标、Powerline 的三角箭头——都来自 Nerd Font 在 Unicode 私有区补的字形。普通字体没有这些字符，装了会显示成方框或者问号。

几个细节：

- 装到**用户级字体目录**（`%LOCALAPPDATA%\Microsoft\Windows\Fonts`），不需要管理员权限
- 配置里写的是全称 `CaskaydiaCove Nerd Font`，但 Windows 注册表里登记的是短名 `CaskaydiaCove NF`——两个名字指向同一套字体，查注册表时别以为没装上
- 换完字体同样要**完全退出 WezTerm 再重开**

### AI CLI 快捷命令

安装时会自动扫描本机已装的 AI 命令行工具，**只给检测到的生成快捷命令**。启动时会把 WezTerm 标签页标题改成对应名字，一眼看出哪个标签在跑什么。

| 命令 | 对应工具 |
|---|---|
| `cc` | Claude Code |
| `qw` | Qwen Code |
| `cx` | Codex |
| `gm` | Gemini CLI |
| `km` | Kimi CLI |
| `gr` | Grok（Grok Build） |
| `op` | OpenCode |

以后装了新的 AI CLI，重跑一次 `install.ps1`，新命令会自动补上。

> **关于 `op` 的提醒**：`op` 同时也是 1Password 的命令行命令。如果你装了 1Password，在 Nushell 里定义 `op` 会把它盖掉。要是碍事，去生成后的 `config.nu` 里把别名改掉就行。

### 背景图

仓库自带一张（`assets\background.png`），默认启用。想换就 `-BackgroundImage`，想彻底不要就 `-NoBackground`。

安装时图片会被**复制**到 `%LOCALAPPDATA%\wezterm-kit\background.png`，配置引用的是这个副本——装完之后把克隆的仓库删掉，背景图照样在。

透明度在生成后的 `~/.wezterm.lua` 里改 `opacity`（0 全透明，1 不透明）。

---

## 已知边界

- **只支持 Windows**。Nushell 和 Starship 本身跨平台，但安装脚本是 PowerShell，路径处理和字体注册都是 Windows 逻辑
- **改 `config/` 和 `snippets/` 没用**。那是模板，重跑脚本会被覆盖。要长期自定义改生成后的文件，看 [docs/定制.md](docs/定制.md)
- **Nightly 每次跑脚本都会重装**（约 45MB）。它没有固定版本号，没法比对是不是最新
- **改了背景图原图不会自动生效**，得重跑脚本或改副本
- **WezTerm Stable 停在 20240203**，不再收 bug 修复——这也是默认走 Nightly 的原因
- **`-AiCliAutoAccept` 默认是关的**，那个开关等于把本机执行权交给模型

---

## 目录结构

```
wezterm-kit/
├── SKILL.md                      给 AI 工具看的装机流程
├── README.md                     英文版（默认）
├── README.zh-CN.md               简体中文版（本文件）
├── assets/
│   ├── background.png            默认背景图
│   └── readme/                   README 用图
├── config/
│   ├── wezterm/
│   │   ├── wezterm.lua           主配置模板
│   │   └── blocks/               可选块：背景图、代理
│   ├── nushell/
│   │   ├── config.nu             主配置模板
│   │   ├── env.nu
│   │   └── blocks/proxy.nu       可选块：代理开关
│   └── starship/starship.toml
├── snippets/                     AI CLI 快捷命令，按检测结果注入
├── scripts/
│   ├── install.ps1               安装脚本
│   └── verify.ps1                验收脚本
└── docs/
    ├── 定制.md
    └── 排错.md
```

---

## 出了问题

见 [docs/排错.md](docs/排错.md)。

---

## 关于作者

**大强同学（Derek Zhao）**  
AI 工具与工作流实践者 · GitHub 开源项目作者

我在 Windows、AI Agent、Obsidian 和个人网站这些真实场景里，
把能跑通的工具、Skill 和流程，整理成可复用的开源项目与交付方案。

- 项目与源码：[GitHub @dqtx760](https://github.com/dqtx760)
- 文章与工具：[dqtx.cc](https://www.dqtx.cc/) · [os.dqtx.cc](https://os.dqtx.cc/)
- 关注更新：[B站](https://space.bilibili.com/491358682/upload/video) · [YouTube](https://www.youtube.com/@dqtx760/videos) · [X](https://x.com/dqtx760)
- 公众号：微信搜索「大强同学」

![微信公众号：大强同学](./assets/readme/wechat-qr.webp)

卡在安装、配置、报错，或想把 AI 接进自己的工作流，可以直接找我。

---

## 许可证

MIT
