# Variables
variable "applications" {
  description = "Map des applications avec leurs chemins et IPs whitelistées"
  type = map(object({
    path = string
    ipv4_ips = list(string)
    ipv6_ips = list(string)
    priority = number
  }))
}
