module "waf" {
  source = "../../modules/waf"
  applications = {
    app1 = {
      path     = "/app1"
      ipv4_ips = ["86.207.223.242/32"]
      ipv6_ips = []
      priority = 1
    }
    app2 = {
      path     = "/app2"
      ipv4_ips = ["86.207.223.242/32", "92.184.104.5/32"]
      ipv6_ips = [
        "2a01:cb14:e53:3c00:e89a:ab8a:dce6:f6c2/128",
        "2a01:cb09:d04a:a09b:0:59:f258:ea01/128"
      ]
      priority = 2
    }
  }
}
