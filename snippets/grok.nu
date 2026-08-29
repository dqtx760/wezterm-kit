# gr —— 启动 Grok CLI（Grok Build），同时把 WezTerm 标签页标题改成 Grok
def gr [] {
    wezterm cli set-tab-title "Grok"
    grok __FLAGS__
}
