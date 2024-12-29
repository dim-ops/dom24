locals {
  waf_name = "main"
}

resource "aws_wafv2_ip_set" "whitelist_ipv4" {
  for_each = {
    for name, app in var.applications : name => app.ipv4_ips
    if length(app.ipv4_ips) > 0
  }

  name               = "whitelist-ipv4-${each.key}"
  description        = "IPv4 whitelist for ${var.applications[each.key].path}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = each.value
}

# IP Sets IPv6
resource "aws_wafv2_ip_set" "whitelist_ipv6" {
  for_each = {
    for name, app in var.applications : name => app.ipv6_ips
    if length(app.ipv6_ips) > 0
  }

  name               = "whitelist-ipv6-${each.key}"
  description        = "IPv6 whitelist for ${var.applications[each.key].path}"
  scope              = "REGIONAL"
  ip_address_version = "IPV6"
  addresses          = each.value
}

# WAF ACL
resource "aws_wafv2_web_acl" "main" {
  name        = local.waf_name
  description = "WAF with whitelists"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  dynamic "rule" {
    for_each = var.applications
    content {
      name     = "allow-whitelist-${rule.key}"
      priority = rule.value.priority

      action {
        allow {}
      }

      dynamic "statement" {
        for_each = length(rule.value.ipv4_ips) > 0 && length(rule.value.ipv6_ips) > 0 ? [1] : []
        content {
          or_statement {
            statement {
              and_statement {
                statement {
                  ip_set_reference_statement {
                    arn = aws_wafv2_ip_set.whitelist_ipv4[rule.key].arn
                  }
                }
                statement {
                  byte_match_statement {
                    positional_constraint = "STARTS_WITH"
                    search_string        = rule.value.path
                    field_to_match {
                      uri_path {}
                    }
                    text_transformation {
                      priority = 1
                      type     = "NONE"
                    }
                  }
                }
              }
            }
            statement {
              and_statement {
                statement {
                  ip_set_reference_statement {
                    arn = aws_wafv2_ip_set.whitelist_ipv6[rule.key].arn
                  }
                }
                statement {
                  byte_match_statement {
                    positional_constraint = "STARTS_WITH"
                    search_string        = rule.value.path
                    field_to_match {
                      uri_path {}
                    }
                    text_transformation {
                      priority = 1
                      type     = "NONE"
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "statement" {
        for_each = length(rule.value.ipv4_ips) > 0 && length(rule.value.ipv6_ips) == 0 ? [1] : []
        content {
          and_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.whitelist_ipv4[rule.key].arn
              }
            }
            statement {
              byte_match_statement {
                positional_constraint = "STARTS_WITH"
                search_string        = rule.value.path
                field_to_match {
                  uri_path {}
                }
                text_transformation {
                  priority = 1
                  type     = "NONE"
                }
              }
            }
          }
        }
      }

      dynamic "statement" {
        for_each = length(rule.value.ipv4_ips) == 0 && length(rule.value.ipv6_ips) > 0 ? [1] : []
        content {
          and_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.whitelist_ipv6[rule.key].arn
              }
            }
            statement {
              byte_match_statement {
                positional_constraint = "STARTS_WITH"
                search_string        = rule.value.path
                field_to_match {
                  uri_path {}
                }
                text_transformation {
                  priority = 1
                  type     = "NONE"
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = "Allow${title(rule.key)}Metric"
        sampled_requests_enabled  = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "WAFWebACLMetric"
    sampled_requests_enabled  = true
  }
}

# Association avec l'ALB
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = data.aws_lb.shared.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

resource "aws_cloudwatch_log_group" "this" {
  name = "aws-waf-logs-${local.waf_name}"
}

# Configuration du logging WAF
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_cloudwatch_log_group.this.arn]
  resource_arn           = aws_wafv2_web_acl.main.arn

  logging_filter {
    default_behavior = "DROP"

    filter {
      behavior = "KEEP"

      condition {
        action_condition {
          action = "COUNT"
        }
      }

      condition {
        action_condition {
          action = "BLOCK"
        }
      }

      requirement = "MEETS_ANY"
    }
  }
}
