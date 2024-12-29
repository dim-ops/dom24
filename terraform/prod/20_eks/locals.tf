locals {
  cluster_name  = "main"
  cw_log_groups = ["application", "dataplane", "performance"]
  retention_in_days = 30
}
