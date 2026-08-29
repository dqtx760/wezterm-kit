# op —— 启动 OpenCode，同时把 WezTerm 标签页标题改成 OpenCode
def op [] {
    wezterm cli set-tab-title "OpenCode"
    opencode __FLAGS__
}
