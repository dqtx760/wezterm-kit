# cx —— 启动 Codex，同时把 WezTerm 标签页标题改成 Codex
def cx [] {
    wezterm cli set-tab-title "Codex"
    codex __FLAGS__
}
