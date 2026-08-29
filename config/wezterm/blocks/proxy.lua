-- ===================== 代理 =====================
-- 由 install.ps1 在传入 -ProxyPort 时注入
-- 注意：这里设的代理对 WezTerm 拉起的所有子进程生效
config.set_environment_variables = {
  http_proxy  = "__PROXY_URL__",
  https_proxy = "__PROXY_URL__",
}
