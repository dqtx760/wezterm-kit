# km —— 启动 Kimi CLI，同时把 WezTerm 标签页标题改成 Kimi
def km [] {
    wezterm cli set-tab-title "Kimi"
    kimi __FLAGS__
}
