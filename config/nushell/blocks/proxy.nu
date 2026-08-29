# -------------------- 代理开关 --------------------
# 由 install.ps1 在传入 -ProxyPort 时注入
# 用法：proxy set / proxy unset / proxy check

def --env "proxy set" [] {
    load-env { "HTTP_PROXY": "__PROXY_URL__", "HTTPS_PROXY": "__PROXY_URL__" }
}

def --env "proxy unset" [] {
    load-env { "HTTP_PROXY": "", "HTTPS_PROXY": "" }
}

def "proxy check" [] {
    print "正在连 Google 测试代理..."
    let resp = (curl -I -s --connect-timeout 2 -m 2 -w "%{http_code}" -o /dev/null www.google.com)
    if $resp == "200" {
        print "代理可用"
    } else {
        print "代理不可用"
    }
}

# 默认开代理，需要临时关掉就执行 proxy unset
proxy set
