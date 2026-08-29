# env.nu
#
# Nushell 启动时最先加载这个文件，然后是 config.nu，最后是 login.nu。
# 按官方建议，能在 config.nu 里做的配置就别放这里，env.nu 只放环境变量。
#
# 这个文件由 wezterm-kit 写入，内容就是 Nushell 安装后的默认模板，没有任何改动。
# 如果你要设环境变量，建议放这里，或者用 config.nu 里的 def --env。
