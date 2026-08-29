# gm —— 启动 Gemini CLI，同时把 WezTerm 标签页标题改成 Gemini
def gm [] {
    wezterm cli set-tab-title "Gemini"
    gemini __FLAGS__
}
