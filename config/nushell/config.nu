# ============================================================
#  wezterm-kit · Nushell 配置模板
#  由 scripts/install.ps1 替换占位符后写到 $env:APPDATA\nushell\config.nu
# ============================================================

# -------------------- Starship 提示符 --------------------
# 左提示符和右提示符都交给 Starship，配色在 ~/.config/starship.toml 里改
$env.PROMPT_COMMAND = {|| starship prompt }
$env.PROMPT_COMMAND_RIGHT = {|| starship prompt --right }

# 不显示启动横幅
$env.config.show_banner = false
# 关掉 osc133：开着会让某些程序回显错行
$env.config.shell_integration.osc133 = false

alias vim = nvim

# -------------------- 语法高亮配色 --------------------
$env.config.color_config = {
    separator: default
    leading_trailing_space_bg: { attr: n }
    header: green_bold
    empty: blue
    bool: light_cyan
    int: default
    filesize: cyan
    duration: default
    datetime: purple
    range: default
    float: default
    string: default
    nothing: default
    binary: default
    cell-path: default
    row_index: green_bold
    record: default
    list: default
    closure: green_bold
    glob: cyan_bold
    block: default
    hints: '#6c6c6c'
    search_result: { bg: red fg: default }
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_external_resolved: light_yellow_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    shape_glob_interpolation: cyan_bold
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
    shape_raw_string: light_purple
    shape_garbage: {
        fg: default
        bg: red
        attr: b
    }
}

#__PROXY_BLOCK__
#__SNIPPETS__
