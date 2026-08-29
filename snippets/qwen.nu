# qw —— 启动 Qwen Code，同时把 WezTerm 标签页标题改成 Qwen
# 注意：qwen 0.21.8 没有「自动接受所有操作」的命令行参数，
# 所以就算开了 -AiCliAutoAccept，这里也不会加任何 flag。
def qw [] {
    wezterm cli set-tab-title "Qwen"
    qwen __FLAGS__
}
