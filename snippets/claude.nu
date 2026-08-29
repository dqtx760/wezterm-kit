# cc —— 启动 Claude Code，同时把 WezTerm 标签页标题改成 Claude
def cc [] {
    wezterm cli set-tab-title "Claude"
    claude __FLAGS__
}
