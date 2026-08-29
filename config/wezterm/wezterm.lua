-- ============================================================
--  wezterm-kit · WezTerm 配置模板
--  本文件是模板，由 scripts/install.ps1 替换占位符后写到 ~/.wezterm.lua
--  直接改这里没用；改生成后的 ~/.wezterm.lua 才生效（重跑脚本会先备份再覆盖）
-- ============================================================

local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action
local mux = wezterm.mux

-- ===================== 字体与默认 shell =====================
config.font = wezterm.font("__FONT_NAME__")
config.font_size = __FONT_SIZE__
config.default_prog = { 'nu' }        -- 默认进 Nushell
config.exit_behavior = "Hold"         -- 命令跑完留住窗口，方便看输出

-- ===================== 配色 =====================
config.color_scheme = 'OneHalfDark'
config.colors = {
  foreground = '#D4D4D4',
  selection_bg = '#207F7F',
  selection_fg = '#FFFFFF',
}

-- ===================== 窗口外观 =====================
config.window_decorations = "RESIZE"   -- 去掉标题栏，窗口靠 Ctrl+左键拖动
config.use_fancy_tab_bar = false
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
  left = 2,
  right = 2,
  top = __PADDING_TOP__,   -- 启用背景图时留 30 给图让位，否则 2
  bottom = 2,
}

--__BACKGROUND_BLOCK__
--__PROXY_BLOCK__
-- ===================== 窗口尺寸 =====================
config.initial_cols = 120
config.initial_rows = 40
config.window_close_confirmation = 'NeverPrompt'

-- ===================== 鼠标 =====================
-- 按住 Shift 时鼠标事件直接给终端（TUI 程序里选文本用）
config.bypass_mouse_reporting_modifiers = "SHIFT"

config.mouse_bindings = {
  -- 右键直接粘贴。刻意不判断「是否有选中内容」：get_selection_text_for_pane
  -- 在大缓冲区上很慢，会让右键卡半秒
  { event = { Down = { streak = 1, button = "Right" } }, mods = "NONE",  action = act.PasteFrom("Clipboard") },
  -- Shift+右键复制
  { event = { Down = { streak = 1, button = "Right" } }, mods = "SHIFT", action = act.CopyTo("Clipboard") },
  -- 左键拖选
  { event = { Down = { streak = 1, button = "Left" } },  mods = "NONE",  action = act.SelectTextAtMouseCursor("Cell") },
  { event = { Drag = { streak = 1, button = "Left" } },  mods = "NONE",  action = act.ExtendSelectionToMouseCursor("Cell") },
  { event = { Drag = { streak = 1, button = "Left" } },  mods = "SHIFT", action = act.ExtendSelectionToMouseCursor("Cell") },
  -- Ctrl+左键拖窗口（因为标题栏被去掉了）
  { event = { Drag = { streak = 1, button = "Left" } },  mods = "CTRL",  action = act.StartWindowDrag },
}

-- ===================== 快捷键 =====================
config.keys = {
  -- 分屏。带 CurrentPaneDomain，新窗格继承当前目录
  { key = "RightArrow", mods = "ALT|SHIFT", action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = "DownArrow",  mods = "ALT|SHIFT", action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
  -- 窗格跳转
  { key = "LeftArrow",  mods = "CTRL", action = act.ActivatePaneDirection "Left" },
  { key = "RightArrow", mods = "CTRL", action = act.ActivatePaneDirection "Right" },
  { key = "UpArrow",    mods = "CTRL", action = act.ActivatePaneDirection "Up" },
  { key = "DownArrow",  mods = "CTRL", action = act.ActivatePaneDirection "Down" },

  -- 关闭。对齐浏览器习惯：Ctrl+W 关标签页，Ctrl+Shift+W 才关整个应用
  { key = "w", mods = "CTRL",       action = act.CloseCurrentTab { confirm = false } },
  { key = "w", mods = "CTRL|SHIFT", action = act.QuitApplication },
  { key = "w", mods = "ALT",        action = act.CloseCurrentTab { confirm = false } },

  { key = "t", mods = "CTRL", action = act.SpawnTab 'DefaultDomain' },
  { key = "u", mods = "CTRL", action = act.SendString('\x15') },   -- 删除到行首
}

-- Ctrl+1 ~ Ctrl+8 切到第 1~8 个标签页
for i = 1, 8 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "CTRL",
    action = act.ActivateTab(i - 1)
  })
end

-- ===================== 启动菜单（新标签页下拉可选） =====================
config.launch_menu = {
  { label = 'NuShell',    args = { 'nu.exe' } },
  { label = 'PowerShell', args = { 'powershell.exe' } },
  { label = 'Cmd',        args = { 'cmd.exe' } },
}

-- ===================== 启动行为 =====================
-- 只起一个 Shell 标签页。cwd 取启动参数带过来的值：
-- 官方 setup.exe 安装器会自动往资源管理器右键菜单加「Open WezTerm here」，
-- 从那里启动时 WezTerm 会把当前目录传进 cmd.cwd，这里接住就能直接落在目标目录。
-- 没带 cwd 就用 WezTerm 自己的默认目录。
-- AI CLI 刻意不在这里拉起：放进 Nushell 的 cc/qw/cx/gm 更稳，
-- 不会因为某个 CLI 没装或卡登录就让整个 WezTerm 起不来
wezterm.on('gui-startup', function(cmd)
  local screen = wezterm.gui.screens().active
  local ratio  = 0.55
  local width  = screen.width * ratio
  local height = screen.height * ratio

  local spawn_cwd = nil
  if cmd and cmd.cwd then
    spawn_cwd = cmd.cwd
  end

  local tab, _, window = mux.spawn_window({ cwd = spawn_cwd })
  tab:set_title("Shell")

  local gui_win = window:gui_window()
  gui_win:set_position((screen.width - width) / 2, (screen.height - height) / 2)
  gui_win:set_inner_size(width, height)
end)

return config
