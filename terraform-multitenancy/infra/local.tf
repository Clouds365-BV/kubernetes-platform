locals {
  resource_name_prefix = lower("${var.customer_prefix}-${var.env.location}-${var.env.env_name}")

  tags = {
    Customer     = var.customer_prefix
    Environment  = var.env.env_name
    Terraform    = "true"
    Application  = "GhostBlog"
    Organization = "Drone Shuttles Ltd"
  }

  diagnostic_settings = {
    logs = [
      {
        category_group = "allLogs"
      }
    ]
    metrics = [
      {
        category = "AllMetrics"
      }
    ]
  }
}